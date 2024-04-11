#!/bin/bash
#set -x


###
### DYNAMIC VARIABLES
###

sourceFile=${1:-}


###
### FUNCTIONS
###

# Boil down the sum. (Using `date` won't show hour values >24.)
timestring () {
#set -x
  local totalSecs=${1:-}

  local h=$( echo "${totalSecs}/3600" | bc )
  local m=$( echo "(${totalSecs}%3600)/60" | bc )
  local s=$( echo "(${totalSecs}%3600)%60" | bc )

  printf "%02.0fh %02.0fm %02.0fs" "${h}" "${m}" "${s}"
#set +x
}


###
### MAIN
###

if [ -z "${sourceFile}" ]
then
  echo "Usage: $0 <file of entries>"
  exit 1
fi


declare -t values
maxValue=0
minValue=99999
sumOfValues=0
sumOfSquares=0
numberOfEntries=0

# Get the values
while IFS= read -r value
do
  # Skip blank lines and comments.
  # https://www.baeldung.com/linux/regex-inside-if-clause
  # https://unix.stackexchange.com/a/47585/31778
  # https://en.wikibooks.org/wiki/Regular_Expressions/POSIX-Extended_Regular_Expressions#Character_classes
  if [[ ${value} =~ ^$ ]] || [[ ${value} =~ ^[[:blank:]]*# ]]
  then
    continue
  fi

  # Add the value to the array.
  values+=( ${value} )

  # Get the smallest value.
  # https://www.gnu.org/software/bc/manual/html_chapter/bc_3.html#SEC11
  is_less=$(echo "${value} < ${minValue}" | bc)
  if [ ${is_less} -eq 1 ]
  then
    minValue=${value}
  fi

  # Get the largest value.
  is_greater=$(echo "${value} > ${maxValue}" | bc)
  if [ ${is_greater} -eq 1 ]
  then
    maxValue=${value}
  fi

  numberOfEntries=$((${numberOfEntries}+1))
  sumOfValues=$( echo ${sumOfValues}+${value} | bc -l )
done < "${sourceFile}"

# Calculate the values and create printable strings.
statMean=$( echo ${sumOfValues}/${numberOfEntries} | bc -l )
printf -v s_mean '%3.3f' ${statMean}

# Get the sum of squares.
for value in ${values[@]}
do
  sumOfSquares=$( echo "${sumOfSquares}+(${value}-${statMean})^2" | bc -l )
done

# Get the median
if (( ${numberOfEntries} % 2 == 1 ))
then
  # Odd number of entries.
  j=$( echo "(${numberOfEntries}/2)+1" | bc )
  statMedian=${values[j]}
else
  # Even number of entries
  j=$((${numberOfEntries}/2))
  k=$((j-1))
  statMedian=$( echo "(${values[j]}+${values[k]})/2" | bc -l )
fi
printf -v s_median '%4.1f' ${statMedian}

statRange=$( echo "${maxValue}-${minValue}" | bc -l )
statVariance=$( echo "${sumOfSquares}/${numberOfEntries}" | bc -l )
printf -v s_variance '%6.3f' ${statVariance}
stdDev=$( echo "sqrt(${statVariance})" | bc -l )
printf -v s_stddev '%3.3f' ${stdDev}
testVariation1=$( echo "${statRange}/${statMean}*100" | bc -l )
printf -v s_testvariation1 '%3.2f' ${testVariation1}
testVariation2=$( echo "${stdDev}/${statMean}*100" | bc -l )
printf -v s_testvariation2 '%3.2f' ${testVariation2}

echo "Returned values:"
for key in ${!values[@]}
do
  # The individual deviation of a value is
  # (value - mean)/StdDev.
  value=${values[${key}]}
  printf -v indivDev '%3.3f' \
    "$( echo "(${value}-${statMean})/${stdDev}" | bc -l )"

  # If the value is less than the mean, print it to screen in red, to
  # highlight and distinguish the values less than the mean from the
  # values greater than the mean.
  NORMAL=$(tput sgr0)
  is_less=$(echo "${value} < ${statMean}" | bc -l )
  if [ ${is_less} -eq 1 ]
  then
    RED=$(tput setaf 1)
  else
    RED=$(tput sgr0)
  fi

  # And print out each individual value.
  printf "%2s: %4s seconds is %11s and ${RED}%6s${NORMAL} %33s\n" \
    "$(( ${key} + 1 ))" \
    "${value}" \
    "$( timestring ${value} )" \
    "${indivDev}" \
    "standard deviations from the mean."
done


# Then, print the summary statistics.
echo
printf "%-21s: %8s\n" \
  "Number of entries" \
  "${numberOfEntries}"
printf "%-21s: %8s seconds is %-11s.\n" \
  "Minimum Elapsed" \
  "${minValue}" \
  "$( timestring ${minValue} )"
printf  "%-21s: %8s seconds is %-11s.\n" \
  "Maximum Elapsed" \
  "${maxValue}" \
  "$( timestring ${maxValue} )"
printf  "%-21s: %8s seconds is %-11s.\n" \
  "Range (Max - Min)" \
  "${statRange}" \
  "$( timestring ${statRange} )"
printf "%-21s: %8s seconds is %-11s, plus job switching time.\n" \
  "Total Elapsed" \
  "${sumOfValues}" \
  "$( timestring ${sumOfValues} )"
printf "%-21s: %8s seconds is %-11s.\n" \
  "Statistical Mean" \
  "${s_mean}" \
  "$( timestring ${s_mean} )"
printf "%-21s: %8s seconds is %-11s.\n" \
  "Statistical Median" \
  "${s_median}" \
  "$( timestring ${s_median} )"
#printf "%-21s: %10s seconds is %-11s.\n" \
#  "Statistical Variance" \
#  "${s_variance}" \
#  "$( timestring ${s_variance} )"
printf "%-21s: %8s seconds is %-11s.\n" \
  "Standard Deviation" \
  "${s_stddev}" \
  "$( timestring ${s_stddev} )"
# Note that variabilty test 1 is much more sensitive to outliers than
# variability test 2 is.
printf "%-21s: %8s%%, calculated as (Range/Mean)*100.\n" \
  "Variability 1" \
  "${s_testvariation1}"
printf "%-21s: %8s%%, calculated as (StdDev/Mean)*100.\n" \
  "Variability 2" \
  "${s_testvariation2}"

