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

	test_skim=`ls $data/$skim | grep "decode"`
	if [ ${#test_skim} -ne 0 ]; then

		train_box=`ls $data/$skim | grep "train" | head -1`
		test_box=`ls $data/$skim | grep "test" | head -1`
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
		if [ ${#train_box} -ne 0 ]; then
			train_best=`cat $data/$skim/$train_box/scoring_kaldi/best_wer`
			train_for=`echo $train_best | cut -c2- | awk -F']' '{print $1}'`
			train_forward=`echo $train_for]`
			train_backword=`echo $train_best | cut -c2- | awk -F']' '{print $2}' | cut -c2-`
			if [ -z "$train_for" ]; then
				train_forward="WER CANNOT BE DISPLAYED."
				train_backword="ERROR MIGHT BE OCCURRED IN THE DECODING PROCESS."
			fi
			echo "TRAIN DATA" 															>> $save/$filename
			echo "- BEST : $train_forward" 												>> $save/$filename
			echo "       : $train_backword" 											>> $save/$filename
			echo 	 																	>> $save/$filename
		else
			echo "TRAIN DATA: DIRECTORY IS NOT FOUND." 									>> $save/$filename
			echo 	 																	>> $save/$filename
		fi
		if [ ${#test_box} -ne 0 ]; then
			test_best=`cat $data/$skim/$test_box/scoring_kaldi/best_wer`
			test_for=`echo $test_best | cut -c2- | awk -F']' '{print $1}'`
			test_forward=`echo $test_for]`
			test_backword=`echo $test_best | cut -c2- | awk -F']' '{print $2}' | cut -c2-`
			if [ -z "$test_for" ]; then
				test_forward="WER CANNOT BE DISPLAYED."
				test_backword="ERROR MIGHT BE OCCURRED IN THE DECODING PROCESS."
			fi
			echo "TEST DATA" 															>> $save/$filename
			echo "- BEST : $test_forward" 												>> $save/$filename
			echo "       : $test_backword" 												>> $save/$filename
			echo 	 																	>> $save/$filename
		else
			echo "TEST DATA: DIRECTORY IS NOT FOUND." 									>> $save/$filename
			echo 	 																	>> $save/$filename
		fi
		echo ====================================================================== 	>> $save/$filename
		echo 																			>> $save/$filename
	fi
done

echo "$filename is newly generated in $save."


