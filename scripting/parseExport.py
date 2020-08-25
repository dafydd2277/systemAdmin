#!/usr/bin/python3
"""
parseExport.py

This script takes a (zipped) XML file from Apple Health and processes
that file to create a weekly summary of selected records.

By default, this script scans the XML file for entries ending in the
previous week. This can be modified with the `-e` or `--end=`
arguments, followed by a date in `YYYY-MM-DD` format.

By default, this script parses for the following record types and
adds the results of each type entry returned for a sum:

- HKQuantityTypeIdentifierStepCount (steps)
- HKQuantityTypeIdentifierDistanceWalkingRunning (miles)
- HKQuantityTypeIdentifierDietaryEnergyConsumed (calories consumed)
- HKQuantityTypeIdentifierActiveEnergyBurned (active calories expended)
- HKQuantityTypeIdentifierBasalEnergyBurned (basal calories expended)
- HKQuantityTypeIdentifierAppleExerciseTime (active minutes)

This can be modified with the `-s` or `--sum` arguments, followed by
a comma-separated list.

By default, this script parses for the following record types and
provides an arithmatic mean of the discovered values.

- HKQuantityTypeIdentifierBodyMass (weight)

This can be modified with the `-m` or `--mean` arguments, followed by
a comma-separated list.

The `-a` or `--audit` argument tells the script to create a date-
stamped file of the discovered entries for each record type discovered.
"""

import datetime
import getopt
from optparse import OptionParser,OptionGroup
import os
import re
from statistics import mean
import sys
import xml.etree.ElementTree as ET
from zipfile import ZipFile


###
### Explicit Variables
###

# Block tracebacks on error.
# (So, make sure you have good error messages!)
#sys.tracebacklimit = None

# Format of RFC-3339 timestamps. Needed to convert strings to
# datetime objects.
formatString = '%Y-%m-%d %H:%M:%S %z'


###
### FUNCTIONS
###

def getMean(recordType):
  """Collect a list of `value` attributes for averaging."""
  if optList.verbose:
    print("Getting records for type "+recordType+".")

  if optList.audit:
    dateOut = sundayEnd.strftime('%Y-%m-%d')
    fileOut = open(dateOut+'.'+recordType+'.csv', 'w')

  resultsList = []
  for record in xmlStructure.findall("./*[@type='"+recordType+"']"):
    endDateObject = setDatetimeObject(record.attrib.get('endDate'))
    if (endDateObject >= sundayStart.astimezone()
      and endDateObject <= sundayEnd.astimezone()):
      recordValue = record.attrib.get('value')
      resultsList.append(float(recordValue))

      if optList.audit:
        ed = endDateObject.strftime('%Y-%m-%d %H:%M:%S')
        fileOut.write(str(ed+','+recordValue+"\n"))

  if optList.audit:
    fileOut.close()

  return round(mean(resultsList), 2)


def getSum(recordType):
  """Collect the sum total of `value` attributes.

  That's the total of records in the date range of `type`
  recordType.
  """
  if optList.verbose:
    print("Getting records for type "+recordType+".")

  if optList.audit:
    dateOut = sundayEnd.strftime('%Y-%m-%d')
    fileOut = open(dateOut+'.'+recordType+'.csv', 'w')

  total = 0
  for record in xmlStructure.findall("./*[@type='"+recordType+"']"):
    endDateObject = setDatetimeObject(record.attrib.get('endDate'))
    if (endDateObject >= sundayStart.astimezone()
      and endDateObject <= sundayEnd.astimezone()):
      recordValue = record.attrib.get('value')
      total += float(recordValue)

      if optList.audit:
        ed = endDateObject.strftime('%Y-%m-%d %H:%M:%S')
        fileOut.write(str(ed+','+recordValue+"\n"))

  if optList.audit:
    fileOut.close()

  return round(total, 2)

def getXML():
  """Open and internalize the input XML file."""
  if os.path.isfile(optList.inputFile):
    isZip = False
    if re.search(".zip$", optList.inputFile) is not None:
      if optList.verbose:
        print(optList.inputFile+" is detected as a zip file.")
      isZip = True
  
    if isZip:
      # This is heavily influenced by the answer to
      # https://stackoverflow.com/questions/10908877/extracting-a-zipfile-to-memory
      try:
        baseName = os.path.basename(optList.inputFile) 
        xmlFile = os.path.splitext(baseName)[0]  
  
        if optList.verbose:
          print("baseName is "+baseName)
          print("xmlFile is "+xmlFile)
  
        unZipped = ZipFile(optList.inputFile, 'r')
        return ET.fromstring(unZipped.read(xmlFile))
      except Exception as error:
        print(error)
        sys.exit(2)
    else:
      try:
        return ET.parse(optList.inputFile).getroot
      except Exception as error:
        print(error)
        sys.exit(2)
  else:
    parser.error("XML input file (-i or --input) is required.")
    parser.print_help()
    sys.exit(1)


def setArgs():
  """Identify the script arguments."""
  scriptArgSet = OptionParser(usage="Usage: %prog [options]",
                              version="%prog 1.0")

  group1 = OptionGroup(scriptArgSet, "Input/Output Options:")
  group1.add_option("-i", "--input", dest="inputFile",
    help="REQUIRED: XML input file. Can be plain or zipped.",
    metavar="FILE")
  group1.add_option("-o", "--output", dest="outputDir",
    help="REQUIRED: Output directory for summary and (optional) audit "
          "files", metavar="DIR")
  scriptArgSet.add_option_group(group1)

  group2 = OptionGroup(scriptArgSet, "Date Option:")
  group2.add_option("-d", "--date", dest="date",
    metavar="YYYY-MM-DD", default=datetime.date.today(),
    help="Date within week to parse. Default: last week.")
  scriptArgSet.add_option_group(group2)

  group3 = OptionGroup(scriptArgSet, "Entry Type Options:")
  group3.add_option("-m", "--mean", dest="meanTypes", metavar="LIST",
    help="Comma-separated list of `type` attributes to search for in "
         "the file.  The mean of the captured records will be returned. "
         "Default: %default",
    default="HKQuantityTypeIdentifierBodyMass"
  )
  group3.add_option("-s", "--sum", dest="sumTypes", metavar="LIST",
    help="Comma-separated list of `type` attributes to search for in "
         "the file.  The sum of the captured records will be returned. "
         "Default: %default",
    default="HKQuantityTypeIdentifierStepCount,"
            "HKQuantityTypeIdentifierDistanceWalkingRunning,"
            "HKQuantityTypeIdentifierDietaryEnergyConsumed,"
            "HKQuantityTypeIdentifierActiveEnergyBurned,"
            "HKQuantityTypeIdentifierBasalEnergyBurned,"
            "HKQuantityTypeIdentifierAppleExerciseTime"
  )
  scriptArgSet.add_option_group(group3)

  group4 = OptionGroup(scriptArgSet, "Debug Options:")
  group4.add_option("-a", "--audit",
    action="store_true", dest="audit", default=False,
    help="Add files capturing data for each `type` to the output "
         "directory, to allow for data verification.")
  group4.add_option("-v", "--verbose",
    action="store_true", dest="verbose", default=False,
    help="Be talkative about what this script is doing.")
  scriptArgSet.add_option_group(group4)

  return scriptArgSet


def setDatetimeObject(rfc):
  """Convert an RFC-3339 date/time string into a datetime object."""
  return datetime.datetime.strptime(rfc, formatString)


def setListType(string):
  """Convert a string of comma-separated terms into a list."""
  return string.split(",")


def weekBounds():
  """Get the Sunday and Saturday dates of the given week.

  `weekBounds()` will return the dates for the Sunday and
  Saturday of the given calendar week. If no date is given,
  the Sunday and Saturday of the previous week are returned.

  This function is heavily derived from
  https://stackoverflow.com/questions/18200530/get-the-last-sunday-and-saturdays-date-in-python
  """
  # If today, extract last week. If not today, extract specified week.
  if optList.date == datetime.date.today():
    lastweek = 7
  else:
    try:
      lastweek = 0
      year, month, day = optList.date.split("-")
      optList.date = datetime.datetime(int(year), int(month), int(day))
    except Exception as error:
      print("Invalid date given.")
      parser.print_help()
      sys.exit(1)

  # The range needs to be "Sunday 00:00" to "Sunday+7 00:00" and we'll do >= and <=
  # comparisons elsewhere.
  idx = (( optList.date.weekday() + 1) % 7 )
  sunStart = optList.date - datetime.timedelta(lastweek+idx)
  sunEnd = optList.date - datetime.timedelta(lastweek+idx-7)

  return sunStart,sunEnd


###
### MAIN
###

#try:
#  xmlSource = str(sys.argv[1])
#except IndexError as trash:
#  raise IOError("No input file given.\n"+usage)

# Get the arguments
parser = setArgs()
optList, args = parser.parse_args()
sundayStart, sundayEnd = weekBounds()

if optList.verbose:
  print("Sunday, "+str(sundayStart))
  print("Saturday, "+str(sundayEnd))
  print("Opt List: "+str(optList))
  print("Args: "+str(args))

sumTypesList = setListType(optList.sumTypes)
meanTypesList = setListType(optList.meanTypes)

if optList.verbose:
  print("List var of sumTypes: "+str(sumTypesList))
  print("List var of meanTypes: "+str(meanTypesList))
  print("\n\nAttempting to open "+optList.inputFile)

xmlStructure = getXML()


for recordType in sumTypesList:
  total = getSum(recordType)
  print("Sum of "+recordType+" is "+str(total))

for recordType in meanTypesList:
  mean = getMean(recordType)
  print("Mean of "+recordType+" entries is "+str(mean))
