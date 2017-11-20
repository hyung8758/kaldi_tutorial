#                                                       Hyungwon Yang
#                                                       hyung8758@gmail.com
#                                                       NAMZ & EMCS Labs
'''
This script generates lexicon.txt and lexiconp.txt files based on corpus data.
Running on python3.
'''

import sys
import os
import re


# Arguments check.
if len(sys.argv) != 3:
    print(len(sys.argv))
    raise ValueError('The number of input arguments is wrong.')

# corpus data directory
text_dir=sys.argv[1]
outputfile = sys.argv[2]

# Search directories.
dir_list = os.listdir(text_dir)
sub_dir = []
for check in dir_list:
    if len(re.findall('[0-9]',check)) != 0:
        sub_dir.append(check)
d phoneme lists.
word_con=[]
phone_con=[]
for d in range(len(sub_dir)):

    for s in sub_list[d]:

        with open('/'.join([text_dir,sub_dir[d],s]),'r') as tg:
            lines = tg.read().splitlines()
            phone_idx = lines.index('"phonem
# Get TextGrid list.
sub_list=[]
for sub in sub_dir:
    tmp = os.listdir('/'.join([text_dir,sub]))
    tg_reg= re.compile(".*.TextGrid")
    sub_list.append([k.group(0) for i in tmp for k in [tg_reg.search(i)] if k])

# Search all TextGrid files and make word ane"')
            word_idx = lines.index('"word"')
            phone_list = lines[phone_idx+7:word_idx-4]
            word_list = lines[word_idx+7:-3]

            for beg_wt in range(0,len(word_list),3):
                word_box = beg_wt
                phone_box = 0
                box = 0
                con_idx = []

                while box < 2:
                    if word_list[word_box] == phone_list[phone_box]:
                        con_idx.append(phone_box)
                        word_box+=1
                        phone_box+=1
                        box += 1
                    else:
                        phone_box += 1

                # Final word list.
                word_con.append(word_list[beg_wt+2])
                # Final phoneme list.
                phone_time=phone_list[con_idx[0]+2:con_idx[1]+2]
                phone_group=[k.group(0) for i in phone_time for k in [re.search('"[a-z0-9]*"', i)] if k]
                phone_con.append(phone_group)

# Rearrange the data for writing text files.
context=[]
for idx in range(len(word_con)):
    # Remove 'sp', '"'
    if re.findall('"sp"',word_con[idx]) == []:
        word_text = re.sub('"', '', word_con[idx])
        phone_join = ' '.join(phone_con[idx])
        phone_text = re.sub('"', '', phone_join)
        context.append(word_text + '\t' + phone_text + ' \n')
final_context=list(set(context))
final_context.sort()


# Write a lexicon.txt file.
with open(outputfile+'.txt','w') as otxt:
    for num in range(len(final_context)):
        otxt.write(final_context[num])

# Write a lexiconp.txt file.
with open(outputfile+'p.txt','w') as otxt:
    for num in range(len(final_context)):
        prob_in = re.sub('\t','\t1.0\t',final_context[num])
        otxt.write(prob_in)



############# Previous version (deprecated) #############

'''
# Prepare word set.
text_box = []
list_box = []
with open(textfile,'r')as txt:
    for line in txt:
        text_box = line.split()[1:]
        # Listing words.
        for num in text_box:
            list_box.append(num)
# Ready for word set.
sort_list=list(set(list_box))
sort_list.sort()


# Prepare phoneme set.
new_box=sort_list
tag = []
tag_list=[]
for word in new_box:
    proc_word=re.sub('[-]','',word)

    for turn in range(int(len(proc_word)/2)):
        tag.append(proc_word[turn*2:(turn*2)+2])
    # Ready for phoneme set.
    tag_list.append(tag)
    tag=[]


# Combine word and phoneme sets to make a lexicon.txt file.
with open(outputfile+'.txt','w') as lex:
    for word,phoneme in zip(sort_list, tag_list):
        lex.write(word+'\t'+' '.join(phoneme[0:])+'\n')

# Combine word, probability, and phoneme sets to make a lexiconp.txt file.
with open(outputfile+'p.txt','w') as lex:
    for word,phoneme in zip(sort_list, tag_list):
        lex.write(word+'\t'+'1.0 '+' '.join(phoneme[0:])+'\n')
'''
