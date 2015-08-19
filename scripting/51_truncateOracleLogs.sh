#!/bin/bash
#
#db truncateLogs.sh
#
#db 2015-02-15
#db Just a point of documentation: this script truncates and deletes files. If
#db you want to preserve old files, you'll need to play with this script to
#db make it work.
#
#db 2012-06-25
#db Revise so non-GRID/RAC database can also be checked. Basically, if the
#db $GRID_* directories don't exist, skip that part, and look for the listener
#db logs in the Oracle structure, instead. Also, explicitly check each file, to
#db prevent `wc` from waiting on STDIN.
#
#db 2012-02-29
#db Original script.

HOST=`hostname -s`

#db Set the base directory variables, even if the variables already exist but
#db are null.
GRID_BASE=${GRID_BASE:=/u01/app/grid}
GRID_HOME=${GRID_HOME:=/u01/app/11.2.0.2/grid}
ORACLE_BASE=${ORACLE_BASE:=/u01/app/oracle}

#db Verify the user.
if [ `id -u` -ne 0 ]
then
  echo "FATAL: Must be run as root."
  exit 1
fi

#db Make the pass through trace and alert directories a common function.
function tracealert () {
  OWNER=$1
  THIS_DIR=$2
  
  if [ -d $THIS_DIR/alert ]
  then
    cd $THIS_DIR/alert
    pwd
    rm -f log_*.xml
  else
    echo -e "$THIS_DIR/alert doesn't exist. Skipping."
  fi

  if [ -d $THIS_DIR/trace ]
  then
    cd $THIS_DIR/trace
    pwd
    #db Instead of rm, find could be run for each of these file suffixes to
    #db delete older files but keep newer ones. See the find command for the
    #db audit files, below.
    rm -f *.trc *.trm *.log.gz
    FILE=`ls -1 alert_*.log 2> /dev/null`
    if [ x$FILE = x ]
    then
      FILE=`ls -1 listen*.log`
    fi
    if [ x$FILE != x ]
    then
      truncate $FILE
      chown $OWNER $FILE
    fi
  else
    echo -e "$THIS_DIR/trace doesn't exist. Skipping."
  fi
}

#db If a log file has more than 200 lines in it, delete all but the last 100
#db lines.
function truncate () {
  FILE=$1
  
  if [ -f $FILE ]
  then
    #db Display the number of lines in the file.
    WC_OUT=`wc -l $FILE`
    echo -e "$WC_OUT\n"
    
    #db Calculate the number of lines to cut.
    LINES=`echo $WC_OUT | cut -d ' ' -f 1`
    if [ $LINES -ge 200 ]
    then
      #db This is how bash does variable arithmatic.
      LINES=$((LINES - 100))
      #db Display the number of lines to be cut.
      echo $LINES
      #db Cut them.
      sed "1,$LINES d" <$FILE >/tmp/trunc
      mv -f /tmp/trunc $FILE
    fi
  else
    echo -e "File $FILE doesn't exist. Skipping.\n"
  fi
}

if [ -d $GRID_HOME ]
then
  #db Remove older audit files using find. Modify the ctime argument to keep the
  #db most recent files. The sample deletes all audit files greater than two
  #db weeks old.
  echo -e "\n\nAudit logs"
  if [ -d $GRID_HOME/rdbms/audit ]
  then
    echo -e "\n\nAudit files"
    cd $GRID_HOME/rdbms/audit
    pwd
    #db Bash for statement to iterate over a range of integers. For busy systems,
    #db just searching for files-older-than can pass too many arguments to the rm
    #db command. Also, quote the -name search string to prevent the shell from
    #db filling the * wildcards before invoking the find.
    for i in {10..99}
    do
      find . -name "*${i}*.aud" -ctime +14 -print -exec rm -f {} \;
    done
  else
    echo -e "$GRID_HOME/rdbms/audit doesn't exist. Skipping.\n"
  fi

  #db For the rest of the script, code is organized by $BASE_DIR.
  #db Here, $DIRS is treated as an array.
  echo -e "\n\nGrid alert and agent logs"
  BASE_DIR=$GRID_HOME/log/${HOST}
  DIRS=( crflogd \
  crfmond \
  cssd \
  ctssd \
  evmd \
  gipcd \
  gpnpd \
  ohasd \
  agent/crsd/oraagent_grid \
  agent/crsd/oraagent_oracle \
  agent/crsd/orarootagent_root \
  agent/ohasd/oraagent_grid \
  agent/ohasd/oracssdagent_root \
  agent/ohasd/oracssdmonitor_root \
  agent/ohasd/orarootagent_root \
  )

  #db Delete old log files in the grid user's service subdirectories. For these
  #db directories, the current log files are service.log and serviceOUT.log. Old
  #db log files are changed to service.l01 through service.l10. (ell-zero-one
  #db through ell-ten).
  for DIR in "${DIRS[@]}"
  do
    if [ -d $BASE_DIR/$DIR ]
    then
      cd $BASE_DIR/$DIR
      #db Echo the directory we're working on.
      pwd
      rm -f *.l[01]*
    fi
  done

  #db Truncate the grid user's alert${HOST}.log. (This is the only time
  #db truncate() is called for this $BASE_DIR. Everything else is straight
  #db removal. So, we're not at risk of modifying the ownership of root-owned
  #db files.
  if [ -d $BASE_DIR ]
  then
    cd $BASE_DIR
    FILE=`ls -1 alert${HOST}.log`
    if [ -f $FILE ]
    then
      truncate $FILE
      chown grid:oinstall $FILE
    else
      echo -e "$FILE doesn't exist. Skipping."
    fi
    #db cvutrc logs use a different name format. This rm leaves *.log.0, which is
    #db the current.
    if [ -d $BASE_DIR/cvu/cvutrc ]
    then
      cd $BASE_DIR/cvu/cvutrc
      pwd
      rm -f *.log.[123456789]*
    else
      echo -e "$BASE_DIR/cvu/cvutrc doesn't exist. Skipping."
    fi
  else
    echo -e "$BASE_DIR doesn't exist. Skipping."
  fi


  #db Here, we're using the same $BASE_DIR, and $DIRS is treated as a
  #db whitespace-separated set of strings.
  echo -e "\n\nSCAN listener logs"
  DIRS="$GRID_HOME/log/diag/tnslsnr/$HOST/listener_scan1
  $GRID_HOME/log/diag/tnslsnr/$HOST/listener_scan2
  $GRID_HOME/log/diag/tnslsnr/$HOST/listener_scan3
  "
  for DIR in $DIRS
  do
    if [ -d $DIR ]
    then
      tracealert grid:oinstall $DIR
    else
      echo -e "$DIR doesn't exist. Skipping."
    fi
  done
else
  echo -e "$GRID_HOME doesn't exist. Skipping."
fi

if [ -d $GRID_BASE ]
then
  #db Now we get a new $BASE_DIR.
  echo -e "\n\nListener logs"
  tracealert grid:oinstall $GRID_BASE/diag/tnslsnr/$HOST/listener
  
  echo -e "\n\nASM logs"
  BASE_DIR=$GRID_BASE/diag/asm/+asm/
  if [ -d $BASE_DIR ]
  then
    cd $BASE_DIR
    NEXT=`ls -1 | grep -v mif`
    tracealert grid:oinstall $BASE_DIR/$NEXT
  else
    echo -e "$BASE_DIR doesn't exist. Skipping."
  fi
else
  echo -e "$GRID_BASE doesn't exist. Skipping."
fi

if [ -d $ORACLE_HOME ]
then
  #db If we don't have a GRID installation, the listener logs will be here.
  if [ -d $ORACLE_BASE/diag/tnslsnr/$HOST/listener/alert ]
  then
    echo -e "\n\nOracle stand-alone listener logs."
    tracealert oracle:oinstall $ORACLE_BASE/diag/tnslsnr/$HOST/listener/
  fi
  
  #db And the RDBMS logs.
  echo -e "\n\nRDBMS logs"
  BASE_DIR=$ORACLE_BASE/diag/rdbms
  #db Each database is listed in $BASE_DIR.
  for DB in `ls -1 $BASE_DIR`
  do
    cd $BASE_DIR/$DB
    #db With the specific instance directory one more level in.
    NEXT=`ls -1 | grep -v mif`
    tracealert oracle:oinstall $BASE_DIR/$DB/$NEXT
  done
else
  echo -e "$ORACLE_BASE does not exist. Skipping."
fi

echo -e "\n\n"
exit 0
