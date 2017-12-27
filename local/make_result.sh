#!/bin/bash
# This script gathers the information of best_wer and displays the training result.
#														Hyungwon Yang
# 														hyung8758@gmail.com
# 														NAMZ & EMCS Labs
#


if [ $# -ne 3 ]; then
   echo "Three arguments should be assigned." 
   echo "1. Result contained directory. (./exp)"
   echo "2. Result saving folder." 
   echo "3. Result file name." && exit 1
fi

# Result contained directory. (./exp)
data=$1
# Result saving folder. (./log)
save=$2
# Result file name. (reulst5-1)
filename=$3

if [ ! -d $save ]; then
	mkdir -p $save
fi
if [ -f $save/$filename ]; then
	rm $save/$filename
	echo "Previous $filename is removed."
fi


echo ====================================================================== | > $save/$filename
echo "                             RESULTS  	                	      " | >> $save/$filename 
echo ====================================================================== | >> $save/$filename
echo RESULT REPORT ON... `date` 											  >> $save/$filename
echo  																		  >> $save/$filename
echo  																		  >> $save/$filename
# Result calculation.
exam_list=`ls $data`
exam_num=`echo $exam_list | wc -w`

for skim in $exam_list; do

	decode_skim=`ls $data/$skim | grep "^decode$"`

	if [ ${#decode_skim} -ne 0 ]; then

		title_tmp=`echo $skim`
		if [ "$title_tmp" == "mono" ]; then
			title_name="MONOPHONE"
		elif [ "$title_tmp" == "tri1" ]; then
			title_name="TRIPHONE1 (DELTA + DOUBLE DELTA)"
		elif [ "$title_tmp" == "tri2" ]; then
			title_name="TRIPHONE2 (LDA + MLLT)"
		elif [ "$title_tmp" == "tri3" ]; then
			title_name="TRIPHONE3 (LDA + MLLT + SAT)"
		elif [ "$title_tmp" == "tri4" ]; then
			title_name="TRIPHONE4 (DEEP NEURAL NETWORK)"
		elif [ "$title_tmp" == "sgmm" ]; then
			title_name="SGMM2"
		elif [ "$title_tmp" == "sgmm_mmi" ]; then
			title_name="SGMM2+MMI"
		else
			title_name=`echo $skim | tr '[:lower:]' '[:upper:]'`
		fi

		echo "$title_name" 																>> $save/$filename
		echo "======================================================================" 	>> $save/$filename
		echo 	 																		>> $save/$filename
		if [ ${#decode_skim} -ne 0 ]; then
			decode_best=`cat $data/$skim/decode/scoring_kaldi/best_wer`
			decode_for=`echo $decode_best | cut -c2- | awk -F']' '{print $1}'`
			decode_forward=`echo $decode_for]`
			decode_backword=`echo $decode_best | cut -c2- | awk -F']' '{print $2}' | cut -c2-`
			if [ -z "$decode_for" ]; then
				decode_forward="WER CANNOT BE DISPLAYED."
				decode_backword="ERROR MIGHT BE OCCURRED IN THE DECODING PROCESS."
			fi
			echo "DECODE" 																>> $save/$filename
			echo "- BEST : $decode_forward" 											>> $save/$filename
			echo "- PATH : $decode_backword" 											>> $save/$filename
			echo 	 																	>> $save/$filename
		else
			echo "DECODE: DIRECTORY IS NOT FOUND." 										>> $save/$filename
			echo 	 																	>> $save/$filename
		fi
		echo ====================================================================== 	>> $save/$filename
		echo 																			>> $save/$filename
	fi
done

echo "$filename is newly generated in $save."


