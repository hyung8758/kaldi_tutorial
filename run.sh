#!/bin/bash
# This script buils Korean ASR model based on kaldi toolkit.
# 														Hyungwon Yang
# 														hyung8758@gmail.com
# 														NAMZ & EMCS Labs

# This code trains and decodes the Korean readspeech corpus dataset with various training techniques.
# Therefore, if anyone who would like to train their corpus dataset by running this sciprt, simply modify this script. 
# Before running this script, corpus dataset needs to be divided into two parts: train and test. 
# Allocate speech data into train and test folders. 
# For those who wish to run this script for learining kaldi, small set of Korean read-speech corpus is provided, 
# so download it from the link in the README file and follow the tutorial from my blog.

### Set path and requisite variables.
# Kaldi root: Where is your kaldi directory?
kaldi=/home/kaldi
# Source data: Where is your source (wavefile) data directory?
source=/home/corpus/small_krs
# Log file: Log file will be saved with the name set below.
logfile=1st_test
log_dir=log
# Result file name
resultfile=result.txt

### Number of jobs.
train_nj=2
decode_nj=2

### CMD
train_cmd=utils/run.pl
decode_cmd=utils/run.pl

### Directories.
train_dir=data/train
test_dir=data/train
lang_dir=data/lang
dict_dir=data/local/dict
log_dir=log

### Activation 
### Data: Give 1 to activate the following steps. Give 0 to deactivate the following steps.
prepare_data=1
prepare_lm=1
extract_train_mfcc=1
extract_test_mfcc=1
extract_train_plp=0
extract_test_plp=0

### Training: Give 1 to activate the following steps. Give 0 to deactivate the following steps.
train_mono=1
train_tri1=1
train_tri2=1
train_tri3=1
train_dnn=0

### Decoding : Give 1 to activate the following steps. Give 0 to deactivate the following steps.
decode_mono=0
decode_tri1=0
decode_tri2=0
decode_tri3=1
decode_dnn=0

### Result
display_result=1

### Options.
# Monophone
mono_train_opt="--boost-silence 1.25 --nj $train_nj --cmd $train_cmd"
mono_align_opt="--nj $train_nj --cmd $decode_cmd"
mono_decode_opt="--nj $decode_nj --cmd $decode_cmd"

# Tri1
tri1_train_opt="--cmd $train_cmd"
tri1_align_opt="--nj $train_nj --cmd $decode_cmd"
tri1_decode_opt="--nj $decode_nj --cmd $decode_cmd"

# Tri2
tri2_train_opt="--cmd $train_cmd"
tri2_align_opt="--nj $train_nj --cmd $decode_cmd"
tri2_decode_opt="--nj $decode_nj --cmd $decode_cmd"

# Tri3
tri3_train_opt="--cmd $train_cmd"
tri3_align_opt="--nj $train_nj --cmd $decode_cmd"
tri3_decode_opt="--nj $decode_nj --cmd $decode_cmd"

# SGMM
sgmm2_train_opt="--cmd $train_cmd"
sgmm2_align_opt="--nj $train_nj --cmd $decode_cmd --transform-dir exp/tri3_ali"
sgmm2_decode_opt="--nj $decode_nj --cmd $decode_cmd --transform-dir exp/tri3_ali"

# SGMM + MMI
sgmm_denlats_opt="--nj $train_nj --sub-split 40 --transform-dir exp/tri3_ali"
sgmmi_train_opt="--cmd $train_cmd --transform-dir exp/tri3_ali"
sgmmi_decode_opt="--transform-dir exp/tri3/decode"

# DNN
dnn_function="train_tanh_fast.sh"
dnn_train_opt=""
dnn_decode_opt="--nj $decode_nj --transform-dir exp/tri3/decode"


# Start logging.
mkdir -p $log_dir
echo ====================================================================== | tee $log_dir/$logfile.log
echo "                       Kaldi ASR Project	                		  " | tee -a $log_dir/$logfile.log
echo ====================================================================== | tee -a $log_dir/$logfile.log
echo Tracking the training procedure on: `date` | tee -a $log_dir/$logfile.log
echo KALDI_ROOT: $kaldi | tee -a $log_dir/$logfile.log
echo DATA_ROOT: $source | tee -a $log_dir/$logfile.log
START=`date +%s`

# This step will generate path.sh based on written path above.
. path.sh $kaldi
. local/check_code.sh $kaldi

# Prepare data for training.
if [ $prepare_data -eq 1 ]; then
	echo ====================================================================== | tee -a $log_dir/$logfile.log
	echo "                       Data Preparation	                		  " | tee -a $log_dir/$logfile.log 
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	start1=`date +%s`; log_s1=`date | awk '{print $4}'`
	echo $log_s1 >> $log_dir/$logfile.log 
	echo START TIME: $log_s1 | tee -a $log_dir/$logfile.log 

	# Check source file is ready to be used. Does train and test folders exist inside the source folder?
	if [ ! -d $source/train -o ! -d $source/test ] ; then
		echo "train and test folders are not present in $source directory." || exit 1
	fi

	# In each train and test data folder, distribute 'text', 'utt2spk', 'spk2utt', 'wav.scp', 'segments'.
	for set in train test; do
		echo -e "Generating prerequisite files...\nSource directory:$source/$set" | tee -a $log_dir/$logfile.log 
		local/krs_prep_data.sh \
			$source/$set \
			data/$set || exit 1

		utils/validate_data_dir.sh data/$set
		utils/fix_data_dir.sh data/$set
	done

	end1=`date +%s`; log_e1=`date | awk '{print $4}'`
	taken1=`local/track_time.sh $start1 $end1`
	echo END TIME: $log_e1  | tee -a $log_dir/$logfile.log 
	echo PROCESS TIME: $taken1 sec  | tee -a $log_dir/$logfile.log
fi

### Language Model
if [ $prepare_lm -eq 1 ]; then
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	echo "                       Language Modeling	                		  " | tee -a $log_dir/$logfile.log 
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	start2=`date +%s`; log_s2=`date | awk '{print $4}'`
	echo $log_s2 >> $log_dir/$logfile.log 
	echo START TIME: $log_s2 | tee -a $log_dir/$logfile.log 

	# Generate lexicon, lexiconp, silence, nonsilence, optional_silence, extra_questions
	# from the train dataset.
	echo "Generating dictionary related files..." | tee -a $log_dir/$logfile.log 
	local/krs_prep_dict.sh \
		$source/train \
		$dict_dir || exit 1

	# Make ./data/lang folder and other files.
	echo "Generating language models..." | tee -a $log_dir/$logfile.log 
	utils/prepare_lang.sh \
		$dict_dir \
		"<UNK>" \
		$lang_dir/local/lang \
		$lang_dir

	# Set ngram-count folder.
	if [[ -z $(find $KALDI_ROOT/tools/srilm/bin -name ngram-count) ]]; then
		echo "SRILM might not be installed on your computer. Please find kaldi/tools/install_srilm.sh and install the package." #&& exit 1
	else
		nc=`find $KALDI_ROOT/tools/srilm/bin -name ngram-count`
		# Make lm.arpa from textraw.
		$nc -text $train_dir/textraw -lm $lang_dir/lm.arpa
	fi

	# Make G.fst from lm.arpa.
	echo "Generating G.fst from lm.arpa..." | tee -a $log_dir/$logfile.log
	cat $lang_dir/lm.arpa | $KALDI_ROOT/src/lmbin/arpa2fst --disambig-symbol=#0 --read-symbol-table=$lang_dir/words.txt - $lang_dir/G.fst
	# Check .fst is stochastic or not.
	$KALDI_ROOT/src/fstbin/fstisstochastic $lang_dir/G.fst


	end2=`date +%s`; log_e2=`date | awk '{print $4}'`
	taken2=`local/track_time.sh $start2 $end2`
	echo END TIME: $log_e2  | tee -a $log_dir/$logfile.log 
	echo PROCESS TIME: $taken2 sec  | tee -a $log_dir/$logfile.log
fi

if [ $extract_train_mfcc -eq 1 ] || [ $extract_test_mfcc -eq 1 ] || [ $extract_train_plp -eq 1 ] || [ $extract_test_plp -eq 1 ]; then
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	echo "                   Acoustic Feature Extraction	             	  " | tee -a $log_dir/$logfile.log 
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	start3=`date +%s`; log_s3=`date | awk '{print $4}'`
	echo $log_s3 >> $log_dir/$logfile.log 
	echo START TIME: $log_s3 | tee -a $log_dir/$logfile.log 

	### MFCC ###
	if [ $extract_train_mfcc -eq 1 ] || [ $extract_test_mfcc -eq 1]; then
		# Generate mfcc configure.
		mkdir -p conf
		echo -e '--use-energy=false\n--sample-frequency=16000' > conf/mfcc.conf
		# mfcc feature extraction.
		mfccdir=mfcc
	fi
	if [ $extract_train_mfcc -eq 1 ]; then
		echo "Extracting train data MFCC features..." | tee -a $log_dir/$logfile.log
		steps/make_mfcc.sh \
			--nj $train_nj \
		 	$train_dir \
		 	exp/make_mfcc/train \
		 	$mfccdir
		# Compute cmvn. (This steps should be processed right after mfcc features are extracted.)
		echo "Computing CMVN on train data MFCC..." | tee -a $log_dir/$logfile.log 
		steps/compute_cmvn_stats.sh \
		 	$train_dir \
		 	exp/make_mfcc/train \
		 	$mfccdir
	fi
	if [ $extract_test_mfcc -eq 1 ]; then
		echo "Extracting test data MFCC features..." | tee -a $log_dir/$logfile.log
		steps/make_mfcc.sh \
		    --nj $train_nj \
		 	$test_dir \
		 	exp/make_mfcc/test \
		 	$mfccdir
		# Compute cmvn. (This steps should be processed right after mfcc features are extracted.)
		echo "Computing CMVN on test data MFCC..." | tee -a $log_dir/$logfile.log 
		steps/compute_cmvn_stats.sh \
		 	$test_dir \
		 	exp/make_mfcc/test \
		 	$mfccdir
	fi

	### PLP ###
	if [ $extract_train_plp -eq 1 ] || [ $extract_test_plp -eq 1 ]; then
		# Generate plp configure.
		echo -e '--sample-frequency=16000' > conf/plp.conf
		plpdir=plp
	fi
	if [ $extract_train_plp -eq 1 ]; then
		# plp feature extraction.
		echo "Extracting train data PLP features..." | tee -a $log_dir/$logfile.log
	 	steps/make_plp.sh \
	 	    --nj $train_nj \
			$train_dir \
			exp/make_plp/train \
			$plpdir
		# Compute cmvn. (This steps should be processed right after plp features are extracted.)
		echo "Computing CMVN on train data PLP..." | tee -a $log_dir/$logfile.log 
		steps/compute_cmvn_stats.sh \
		 	$train_dir \
		 	exp/make_plp/train \
		 	$plpdir
	fi
	if [ $extract_test_plp -eq 1 ]; then
		# plp feature extraction.
		echo "Extracting test data PLP features..." | tee -a $log_dir/$logfile.log
	 	steps/make_plp.sh \
	 	    --nj $train_nj \
			$test_dir \
			exp/make_plp/test \
			$plpdir
		# Compute cmvn. (This steps should be processed right after plp features are extracted.)
		echo "Computing CMVN on test data PLP..." | tee -a $log_dir/$logfile.log 
		steps/compute_cmvn_stats.sh \
		 	$test_dir \
		 	exp/make_plp/test \
		 	$plpdir
	fi


	# data directories sanity check.
	echo "Examining generated datasets..." | tee -a $log_dir/$logfile.log 
	utils/validate_data_dir.sh $train_dir
	utils/fix_data_dir.sh $train_dir


	end3=`date +%s`; log_e3=`date | awk '{print $4}'`
	taken3=`local/track_time.sh $start3 $end3`
	echo END TIME: $log_e3  | tee -a $log_dir/$logfile.log 
	echo PROCESS TIME: $taken3 sec  | tee -a $log_dir/$logfile.log

fi

if [ $train_mono -eq 1 ] || [ $decode_mono -eq 1 ]; then
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	echo "                    Train & Decode: Monophone	                 	  " | tee -a $log_dir/$logfile.log 
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	start4=`date +%s`; log_s4=`date | awk '{print $4}'`
	echo $log_s4 >> $log_dir/$logfile.log 
	echo START TIME: $log_s4 | tee -a $log_dir/$logfile.log 

	# Monophone train.
	if [ $train_mono -eq 1 ]; then

		echo "Monophone trainig options: $mono_train_opt" 	| tee -a $log_dir/$logfile.log
		echo "Training monophone..." | tee -a $log_dir/$logfile.log 
		steps/train_mono.sh \
			$mono_train_opt \
			$train_dir \
			$lang_dir \
			exp/mono || exit 1
	
		# Monophone aglinment.
		# train된 model파일인 mdl과 occs로부터 새로운 align을 생성
		echo "Monophone aligning options: $mono_align_opt" 	| tee -a $log_dir/$logfile.log
		echo "Aligning..." | tee -a $log_dir/$logfile.log 
		steps/align_si.sh \
			$mono_align_opt \
			$train_dir \
			$lang_dir \
			exp/mono \
			exp/mono_ali || exit 1
	fi

	# Graph structuring.
	# make HCLG graph (optional! train과는 무관, 오직 decode만을 위해.)
	# This script creates a fully expanded decoding graph (HCLG) that represents
	# all the language-model, pronunciation dictionary (lexicon), context-dependency,
	# and HMM structure in our model.  The output is a Finite State Transducer
	# that has word-ids on the output, and pdf-ids on the input (these are indexes
	# that resolve to Gaussian Mixture Models).
	# exp/mono/graph에 가면 결과 graph가 만들어져 있음
	if [ $decode_mono -eq 1 ]; then
		
		echo "Generating monophone graph..." | tee -a $log_dir/$logfile.log 
		utils/mkgraph.sh \
		$lang_dir \
		exp/mono \
		exp/mono/graph 

		# Data decoding.
		echo "Monophone decoding options: $mono_decode_opt" | tee -a $log_dir/$logfile.log
		echo "Decoding with monophone model..." | tee -a $log_dir/$logfile.log 
		steps/decode.sh \
			$mono_decode_opt \
			exp/mono/graph \
			$test_dir \
			exp/mono/decode
	fi

	### Optional ###
	# tree structuring.
	# $KALDI_ROOT/src/bin/draw-tree $lang_dir/phones.txt exp/mono/tree \
	# | dot -Tps -Gsize=8,10.5 | ps2pdf - tree.pdf 2>/dev/null

	end4=`date +%s`; log_e4=`date | awk '{print $4}'`
	taken4=`local/track_time.sh $start4 $end4`
	echo END TIME: $log_e4  | tee -a $log_dir/$logfile.log 
	echo PROCESS TIME: $taken4 sec  | tee -a $log_dir/$logfile.log
fi

if [ $train_tri1 -eq 1 ] || [ $decode_tri1 -eq 1 ]; then
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	echo "           Train & Decode: Triphone1 [delta+delta-delta]	       	  " | tee -a $log_dir/$logfile.log 
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	start5=`date +%s`; log_s5=`date | awk '{print $4}'`
	echo $log_s5 >> $log_dir/$logfile.log 
	echo START TIME: $log_s5 | tee -a $log_dir/$logfile.log 

	# Triphone1 training.
	if [ $train_tri1 -eq 1 ]; then

		echo "Triphone1 training options: $tri1_train_opt"	| tee -a $log_dir/$logfile.log
		echo "Training delta+double-delta..." | tee -a $log_dir/$logfile.log 
		steps/train_deltas.sh \
			$tri1_train_opt \
			2000 \
			10000 \
			$train_dir \
			$lang_dir \
			exp/mono_ali \
			exp/tri1 || exit 1

		# Triphone1 aglining.
		echo "Triphone1 aligning options: $tri1_align_opt"	| tee -a $log_dir/$logfile.log
		echo "Aligning..." | tee -a $log_dir/$logfile.log 
		steps/align_si.sh \
			$tri1_align_opt \
			$train_dir \
			$lang_dir \
			exp/tri1 \
			exp/tri1_ali ||  exit 1
	fi

	if [ $decode_tri1 -eq 1 ]; then
		# Graph drawing.
		echo "Generating delta+double-delta graph..." | tee -a $log_dir/$logfile.log 
		utils/mkgraph.sh \
			$lang_dir \
			exp/tri1 \
			exp/tri1/graph

		# Data decoding.
		echo "Triphone1 decoding options: $tri1_decode_opt"	| tee -a $log_dir/$logfile.log
		echo "Decoding with delta+double-delta model..." | tee -a $log_dir/$logfile.log 
		steps/decode.sh \
			$tri1_decode_opt \
			exp/tri1/graph \
			$test_dir \
			exp/tri1/decode
	fi

	end5=`date +%s`; log_e5=`date | awk '{print $4}'`
	taken5=`local/track_time.sh $start5 $end5`
	echo END TIME: $log_e5  | tee -a $log_dir/$logfile.log 
	echo PROCESS TIME: $taken5 sec  | tee -a $log_dir/$logfile.log
fi

if [ $train_tri2 -eq 1 ] || [ $decode_tri2 -eq 1 ]; then
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	echo "               Train & Decode: Triphone2 [LDA+MLLT]	         	  " | tee -a $log_dir/$logfile.log 
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	start6=`date +%s`; log_s6=`date | awk '{print $4}'`
	echo $log_s6 >> $log_dir/$logfile.log 
	echo START TIME: $log_s6 | tee -a $log_dir/$logfile.log 


	# Triphone2 training.
	if [ $train_tri2 -eq 1 ]; then
		echo "Triphone2 trainig options: $tri2_train_opt"	| tee -a $log_dir/$logfile.log
		echo "Training LDA+MLLT..." | tee -a $log_dir/$logfile.log 
		steps/train_lda_mllt.sh \
			$tri2_train_opt \
			2500 \
			15000 \
			$train_dir \
			$lang_dir \
			exp/tri1_ali \
			exp/tri2 ||  exit 1

		# Triphone2 aglining.
		echo "Triphone2 aligning options: $tri2_align_opt"	| tee -a $log_dir/$logfile.log
		echo "Aligning..." | tee -a $log_dir/$logfile.log
		steps/align_si.sh \
			$tri2_align_opt \
			$train_dir \
			$lang_dir \
			exp/tri2 \
			exp/tri2_ali ||  exit 1
	fi

	if [ $decode_tri2 -eq 1 ]; then
		# Graph drawing.
		echo "Generating LDA+MLLT graph..." | tee -a $log_dir/$logfile.log
		utils/mkgraph.sh \
			$lang_dir \
			exp/tri2 \
			exp/tri2/graph

		# Data decoding.
		echo "Triphone2 decoding options: $tri2_decode_opt"	| tee -a $log_dir/$logfile.log
		echo "Decoding with LDA+MLLT model..." | tee -a $log_dir/$logfile.log
		steps/decode.sh \
			$tri2_decode_opt \
			exp/tri2/graph \
			$test_dir \
			exp/tri2/decode
	fi

	end6=`date +%s`; log_e6=`date | awk '{print $4}'`
	taken6=`local/track_time.sh $start6 $end6`
	echo END TIME: $log_e6  | tee -a $log_dir/$logfile.log 
	echo PROCESS TIME: $taken6 sec  | tee -a $log_dir/$logfile.log
fi

if [ $train_tri3 -eq 1 ] || [ $decode_tri3 -eq 1 ]; then
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	echo "             Train & Decode: Triphone3 [LDA+MLLT+SAT]	         	  " | tee -a $log_dir/$logfile.log 
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	start7=`date +%s`; log_s7=`date | awk '{print $4}'`
	echo $log_s7 >> $log_dir/$logfile.log 
	echo START TIME: $log_s7 | tee -a $log_dir/$logfile.log 


	# Triphone3 training.
	if [ $train_tri3 -eq 1 ]; then
		echo "Triphone3 trainig options: $tri3_train_opt" | tee -a $log_dir/$logfile.log
		echo "Training LDA+MLLT+SAT..." | tee -a $log_dir/$logfile.log
		steps/train_sat.sh \
			$tri3_train_opt \
			2500 \
			15000 \
			$train_dir \
			$lang_dir \
			exp/tri2_ali \
			exp/tri3 ||  exit 1

		# Triphone3 aglining.
		echo "Triphone3 aligning options: $tri3_align_opt" | tee -a $log_dir/$logfile.log
		echo "Aligning..." | tee -a $log_dir/$logfile.log
		steps/align_fmllr.sh \
			$tri3_align_opt \
			$train_dir \
			$lang_dir \
			exp/tri3 \
			exp/tri3_ali ||  exit 1
	fi

	if [ $decode_tri3 -eq 1 ]; then
		# Graph drawing.
		echo "Generating LDA+MLLT+SAT graph..." | tee -a $log_dir/$logfile.log
		utils/mkgraph.sh \
			$lang_dir \
			exp/tri3 \
			exp/tri3/graph

		# Data decoding: train and test datasets.
		echo "Tirphone3 decoding options: $tri3_decode_opt" | tee -a $log_dir/$logfile.log
		echo "Decoding with LDA+MLLT+SAT model..." | tee -a $log_dir/$logfile.log
		steps/decode_fmllr.sh \
			$tri3_decode_opt \
			exp/tri3/graph \
			$test_dir \
			exp/tri3/decode
	fi

	end7=`date +%s`; log_e7=`date | awk '{print $4}'`
	taken7=`local/track_time.sh $start7 $end7`
	echo END TIME: $log_e7  | tee -a $log_dir/$logfile.log 
	echo PROCESS TIME: $taken7 sec  | tee -a $log_dir/$logfile.log
fi

### DNN training
if [ $train_dnn -eq 1 ] || [ $decode_dnn -eq 1 ]; then
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	echo "                       Train & Decode: DNN  	            	      " | tee -a $log_dir/$logfile.log 
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	start10=`date +%s`; log_s10=`date | awk '{print $4}'`
	echo $log_s10 >> $log_dir/$logfile.log 
	echo START TIME: $log_s10 | tee -a $log_dir/$logfile.log 

	# DNN training.
	if [ $train_dnn -eq 1 ]; then
		# train_tanh_fast.sh
		echo "DNN($dnn_function) trainig options: $dnn_train_opt"					| tee -a $log_dir/$logfile.log
		echo "Training DNN..." | tee -a $log_dir/$logfile.log
		steps/nnet2/$dnn_function \
			$dnn_train_opt \
			$train_dir \
			$lang_dir \
			exp/tri3_ali \
			exp/tri4 ||  exit 1
	fi

	# DNN decoding.
	if [ $decode_dnn -eq 1 ]; then
		# Data decoding: train dataset.
		echo "DNN($dnn_function) decoding options: $dnn_decode_opt"	| tee -a $log_dir/$logfile.log
		echo "Decoding with DNN model..." | tee -a $log_dir/$logfile.log
		steps/nnet2/decode.sh \
			$dnn_decode_opt \
			exp/tri3/graph \
			$test_dir \
			exp/tri4/decode
	fi

	end10=`date +%s`; log_e10=`date | awk '{print $4}'`
	taken10=`local/track_time.sh $start10 $end10`
	echo END TIME: $log_e10  | tee -a $log_dir/$logfile.log 
	echo PROCESS TIME: $taken10 sec  | tee -a $log_dir/$logfile.log


fi

if [ $display_result -eq 1 ]; then 
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	echo "                             RESULTS  	                	      " | tee -a $log_dir/$logfile.log 
	echo ====================================================================== | tee -a $log_dir/$logfile.log 
	echo "Displaying results" | tee -a $log_dir/$logfile.log

	# Save result in the log folder.
	echo "Displaying results" | tee -a $log_dir/$logfile.log
	local/make_result.sh exp log $resultfile
	echo "Reporting results..." | tee -a $log_dir/$logfile.log
	cat log/$resultfile | tee -a $log_dir/$logfile.log
fi
##########################################################
# This is for final log.
echo "Training procedure finished successfully..." | tee -a $log_dir/$logfile.log
END=`date +%s`
taken=`. local/track_time.sh $START $END`
echo TOTAL TIME: $taken sec  | tee -a $log_dir/$logfile.log 

