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

# generate save directory if it is not present.
if [ ! -d $save ]; then
        mkdir -p $save
fi
echo ======================================================================
echo "                              NOTICE                                "
echo ""
echo -e "krs_prep_dict: Generate lexicon, silence, nonsilence, \n\toptional_silence, and extra_questions."
echo "CURRENT SHELL: $0"
echo -e "INPUT ARGUMENTS:\n$@"

for check in lexicon.txt silence.txt nonsilence.txt optional_silence.txt extra_questions.txt; do
	if [ -f $save/$check ] && [ ! -z $save/$check ]; then
		echo -e "$check is already present but it will be overwritten."
	fi
done
echo ""
echo ======================================================================

# lexicon.
# Generate lexicon.txt by running g2p.
echo "Generating lexicon.txt."
if [ -f $save/lexicon.txt ]; then
    rm $save/lexicon.txt
fi
cd local/KoG2P
for w in `cat ../../$data/textraw | tr ' ' '\n' | sort -u `; do
    lex_word=`python g2p.py $w`
    echo "$w $lex_word" >> ../../$save/tmp_lexicon.txt
done
cd ../..
cat $save/tmp_lexicon.txt | sort -u > $save/lexicon.txt
rm $save/tmp_lexicon.txt
echo "lexicon.txt file was generated."

# silence.
echo -e "<SIL>\n<UNK>" >  $save/silence_phones.txt
echo "silence.txt file was generated."

# nonsilence.
awk '{$1=""; print $0}' $save/lexicon.txt | tr -s ' ' '\n' | sort -u | sed '/^$/d' >  $save/nonsilence_phones.txt
# sed '1d' $save/nonsilence_phones.txt > tmp_nons.txt
# mv tmp_nons.txt $save/nonsilence_phones.txt
echo "nonsilence.txt file was generated."

# insert <UNK> to lexicon.txt
sed -e '1i\
<UNK> <UNK>\' $save/lexicon.txt > $save/tmp_lexicon.txt
mv $save/tmp_lexicon.txt $save/lexicon.txt
# sed -e '1i\
# <UNK> 1.0 <UNK>\' $save/lexiconp.txt > $save/tmp_lexiconp.txt
# mv $save/tmp_lexiconp.txt $save/lexiconp.txt

# optional_silence.
echo '<SIL>' >  $save/optional_silence.txt
echo "optional_silence.txt file was generated."

# extra_questions.
cat $save/silence_phones.txt| awk '{printf("%s ", $1);} END{printf "\n";}' > $save/extra_questions.txt || #exit 1;
cat $save/nonsilence_phones.txt | perl -e 'while(<>){ foreach $p (split(" ", $_)) {  $p =~ m:^([^\d]+)(\d*)$: || die "Bad phone $_"; $q{$2} .= "$p "; } } foreach $l (values %q) {print "$l\n";}' >> $save/extra_questions.txt || exit 1;
echo "extra_questions.txt file was generated."
