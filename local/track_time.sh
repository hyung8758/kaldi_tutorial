#!/bin/bash
# This script shows time taken from specific tasks.
# It calculates the differences between two date.
# 														Hyungwon Yang
# 														hyung8758@gmail.com
# 														NAMZ & EMCS Labs

# Get the variables.
if [ $# -ne 2 ]; then
   echo "Two date arguments should be assigned." 
   echo "First input should be start time formatted as: xx (seconds)"
   echo "Second input should be end time formatted as: xx (seconds)"
   echo "Collect start and end time with the command: date +%s" && exit 1
fi

in_start=$1
in_end=$2

if ! [ $in_start -eq $in_start 2>/dev/null ] && [ $in_end -eq $in_end 2>/dev/null ]; then
	echo "Input arguments should be integers." && exit 1
fi

# Calculation
newtime=$(($in_end - $in_start))

# Conver it to 00:00:00 format.
myos=`uname`
if [ $myos == "Linux" ]; then
	outtime=`date -u -d @${newtime} +%T`
	echo linux
else
	outtime=`date -u -r $newtime +%T`
	echo osx
fi

# Print the result.
echo $outtime


























##################################################
# Depricated (1st-version) It didn't work well.

# s_time=`echo $start | tr -s ':' ' '`
# e_time=`echo $end | tr -s ':' ' '`

# first_s_time=`echo $s_time | awk '{print $1}'`
# second_s_time=`echo $s_time | awk '{print $2}'`
# third_s_time=`echo $s_time | awk '{print $3}'`

# first_e_time=`echo $e_time | awk '{print $1}'`
# second_e_time=`echo $e_time | awk '{print $2}'`
# third_e_time=`echo $e_time | awk '{print $3}'`


# for check in first_s_time second_s_time third_s_time first_e_time second_e_time third_e_time; do
# 	eval "number=\${$check}"
# 	if [ $(echo ${number:0:1}) -eq 0 ]; then
# 		eval "$check=${number:1}"
# 	fi
# done

# # Calculate two times
# one=$(( $first_e_time - $first_s_time ))
# two=$(( $second_e_time - $second_s_time ))
# three=$(( $third_e_time - $third_s_time ))


# if [ $(echo ${#one}) -lt 2 ]; then
# 	first="0"$one
# fi
# if [ $(echo ${#two}) -lt 2 ]; then
# 	second="0"$two
# fi
# if [ $(echo ${#three}) -lt 2 ]; then
# 	third="0"$three
# fi

# echo $first":"$second":"$third