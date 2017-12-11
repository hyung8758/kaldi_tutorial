#!/bin/bash
# # This scripts generate dictionray related parts.
# 														Hyungwon Yang
# 														hyung8758@gmail.com
# 														NAMZ & EMCS Labs


if [ $# -ne 2 ]; then
   echo "Two arguments should be assigned." 
   echo "1. Source data."
   echo "2. The folder in which generated files are saved." && exit 1
fi

# train data directory.
data=$1
# savining directory.
save=$2

echo ======================================================================
echo "                              NOTICE                                "
echo ""
echo -e "krs_prep_dict: Generate lexicon, lexiconp, silence, nonsilence, \n\toptional_silence, and extra_questions."
echo "CURRENT SHELL: $0"
echo -e "INPUT ARGUMENTS:\n$@"

for check in lexicon.txt lexiconp.txt silence.txt nonsilence.txt optional_silence.txt extra_questions.txt; do
	if [ -f $save/$check ] && [ ! -z $save/$check ]; then
		echo -e "$check is already present but it will be overwritten."
	fi
done
echo ""
echo ======================================================================

# lexicon.txt and lexiconp.txt
if [ ! -d $save ]; then
	mkdir -p $save
fi

echo "Generating lexicon.txt and lexiconp.txt."
echo "These files are pre-made. When you use other corpus, make them before training."
# Get lexicon.txt and lexiconp.txt files.
# These files are prepared for you. If you want to use other datasets you need to prepare them by yourself.
cat local/lexicon.txt > $save/lexicon.txt
cat local/lexiconp.txt > $save/lexiconp.txt

echo "lexicon.txt and lexiconp.txt files were generated."


# silence.
echo -e "<SIL>\n<UNK>" >  $save/silence_phones.txt
echo "silence.txt file was generated."

# nonsilence.
awk '{$1=""; print $0}' $save/lexicon.txt | tr -s ' ' '\n' | sort -u | sed '/^$/d' >  $save/nonsilence_phones.txt
sed '1d' $save/nonsilence_phones.txt > tmp_nons.txt
mv tmp_nons.txt $save/nonsilence_phones.txt
echo "nonsilence.txt file was generated."

# optional_silence.
echo '<SIL>' >  $save/optional_silence.txt
echo "optional_silence.txt file was generated."

# extra_questions.
cat $save/silence_phones.txt| awk '{printf("%s ", $1);} END{printf "\n";}' > $save/extra_questions.txt || #exit 1;
cat $save/nonsilence_phones.txt | perl -e 'while(<>){ foreach $p (split(" ", $_)) {  $p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } foreach $l (values %q) {print "$l\n";}' >> $save/extra_questions.txt || exit 1;
echo "extra_questions.txt file was generated."

