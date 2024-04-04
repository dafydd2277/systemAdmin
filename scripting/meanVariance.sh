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


declare -t a_values
i_max=0
i_min=10000
i_sum=0
i_sumofsquares=0
numberOfEntries=0


echo "Returned values:"
while IFS= read -r i_value
do

  if [[ ${i_value} =~ ^$ ]]
  then
    continue
  fi

  if [[ ${i_value} =~ ^# ]]
  then
    continue
  fi

  numberOfEntries=$((${numberOfEntries}+1))
  a_values+=( ${i_value} )
  s_hms=$( timestring ${i_value} )
  printf '%2s: %4s seconds is %11s.\n' "${numberOfEntries}" \
    "${i_value}" "${s_hms}"

  i_sum=$( echo ${i_sum}+${i_value} | bc -l )
  
  is_less=$(echo "${i_value} < ${i_min}" | bc)
  if [ ${is_less} -eq 1 ]
  then
    i_min=${i_value}
  fi

  is_greater=$(echo "${i_value} > ${i_max}" | bc)
  if [ ${is_greater} -eq 1 ]
  then
    i_max=${i_value}
  fi
done < "${sourceFile}"


# Calculate the values
f_mean=$( echo ${i_sum}/${numberOfEntries} | bc -l )

i_sumofsquares=0
for i_value in ${a_values[*]}
do
  i_sumofsquares=$( echo "${i_sumofsquares}+(${i_value}-${f_mean})^2" | bc -l )
done

f_variance=$( echo "${i_sumofsquares}/${numberOfEntries}" | bc -l )
f_stddev=$( echo "sqrt(${i_sumofsquares}/${numberOfEntries})" | bc -l )
f_testvariation1=$( echo "((${i_max}-${i_min})/${f_mean})*100" | bc -l )
f_testvariation2=$( echo "(${f_stddev}/${f_mean})*100" | bc -l )

# Convert to usable strings
printf -v s_mean '%3.3f' ${f_mean}
printf -v s_variance '%6.3f' ${f_variance}
printf -v s_stddev '%3.3f' ${f_stddev}
printf -v s_testvariation1 '%3.2f' ${f_testvariation1}
printf -v s_testvariation2 '%3.2f' ${f_testvariation2}

# Print the results
echo
printf "%-21s: %8s\n" \
  "Number of entries" \
  "${numberOfEntries}"
printf "%-21s: %8s seconds is %-11s.\n" \
  "Minimum Elapsed" \
  "${i_min}" \
  "$( timestring ${i_min} )"
printf  "%-21s: %8s seconds is %-11s.\n" \
  "Maximum Elapsed" \
  "${i_max}" \
  "$( timestring ${i_max} )"
printf "%-21s: %8s seconds is %-11s, plus job switching time.\n" \
  "Total Elapsed" \
  "${i_sum}" \
  "$( timestring ${i_sum} )"
printf "%-21s: %8s seconds is %-11s.\n" \
  "Statistical Mean" \
  "${s_mean}" \
  "$( timestring ${s_mean} )"
#printf "%-21s: %10s seconds is %-11s.\n" \
#  "Statistical Variance" \
#  "${s_variance}" \
#  "$( timestring ${s_variance} )"
printf "%-21s: %8s seconds is %-11s.\n" \
  "Standard Deviation" \
  "${s_stddev}" \
  "$( timestring ${s_stddev} )"
printf "%-21s: %8s%%, calculated as ((Max - Min)/Mean)*100.\n" \
  "Testing Variation 1" \
  "${s_testvariation1}"
printf "%-21s: %8s%%, calculated as (StdDev/Mean)*100.\n" \
  "Testing Variation 2" \
  "${s_testvariation2}"

