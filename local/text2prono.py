# -*- coding: utf-8 -*-
"""
This script transforms Korean word list in the text file into pronunciation and then adds them to the original text file which is lexicon.txt

 														Hyungwon Yang
 														hyung8758@gmail.com
 														NAMZ & EMCS Labs


"""

import sys
import re
import math

# Arguments check.
if len(sys.argv) != 4:
    print(len(sys.argv))
    print("Input arguments are incorrectly provided. Two argument should be assigned.")
    print("1. text file.")
    print("2. g2p function.")
    print("3. save directory.")
    print("*** USAGE ***")
    print("Ex. python3 text2prono.py $text_file $g2p_function $save_directory")
    raise ValueError('RETURN')

# file and directory.
txt_file = sys.argv[1]
g2p_func = sys.argv[2]
save_dir = sys.argv[3]

# check xlrd module
# xlrd enables reading .xls files
try:
    import xlrd
except ImportError:
    print('\nxlrd is not installed\nPlease install it first')

# check rules_g2p.xls
g2p_dir = re.sub('g2p.py','',g2p_func)
try:
    rule_book = xlrd.open_workbook(g2p_dir + 'rules_g2p.xls')
except IOError:
    print('\nrules_g2p.xls does not exist or is corrupted')
    print('\nLocate rules_g2p.xls in the same folder as in g2p.py')

# read rules_g2p.xls
rule_sheet = rule_book.sheet_by_name(u'ruleset')
var = rule_sheet.cell(0, 0).value

rule_in = []
rule_out = []
for idx in range(0, rule_sheet.nrows):
    rule_in.append(rule_sheet.cell(idx, 0).value)
    rule_out.append(rule_sheet.cell(idx, 1).value)


def checkSpaceElement(var_list):
    '''
    This function checks if an element in a list is 32 or not
    32 is a representation of 16-bit unsigned integer
    of space character ' '

    If 32, it returns 1
    If not empty, it returns 0
    '''
    checked = []
    for i in range(len(var_list)):
        if var_list[i] == 32:
            checked.append(1)
        else:
            checked.append(0)
    return checked


def graph2phone(graphs):
    '''
    This function converts Korean graphemes to romanized phones
    '''
    # encode graphemes as utf8
    try:
        graphs = graphs.decode('utf-8')
    except:
        pass
    integers = []
    for i in range(len(graphs)):
        integers.append(ord(graphs[i]))

    # romanization
    phones = ''
    ONS = ['k0', 'kk', 'nn', 't0', 'tt', 'rr', 'mm', 'p0', 'pp',
           's0', 'ss', 'oh', 'c0', 'cc', 'ch', 'kh', 'th', 'ph', 'hh']
    NUC = ['aa', 'qq', 'ya', 'yq', 'vv', 'ee', 'yv', 'ye', 'oo', 'wa',
           'wq', 'wo', 'yo', 'uu', 'wv', 'we', 'wi', 'yu', 'xx', 'xi', 'ii']
    COD = ['', 'k0', 'kk', 'ks', 'nn', 'nc', 'nh', 't0',
           'll', 'lk', 'lm', 'lb', 'ls', 'lt', 'lp', 'lh',
           'mm', 'p0', 'ps', 's0', 'ss', 'oh', 'c0', 'ch',
           'kh', 'th', 'ph', 'hh']

    # pronunciation
    idx = checkSpaceElement(integers)
    iElement = 0
    while iElement < len(integers):
        if idx[iElement] == 0:  # not space characters
            base = 44032
            df = int(integers[iElement]) - base
            iONS = int(math.floor(df / 588)) + 1
            iNUC = int(math.floor((df % 588) / 28)) + 1
            iCOD = int((df % 588) % 28) + 1

            s1 = '-' + ONS[iONS - 1]  # onset
            s2 = NUC[iNUC - 1]        # nucleus

            if COD[iCOD - 1]:         # coda
                s3 = COD[iCOD - 1]
            else:
                s3 = ''
            tmp = s1 + s2 + s3
            phones = phones + tmp
        elif idx[iElement] == 1:  # space character
            tmp = ' '
            phones = phones + tmp
        phones = re.sub('-(oh)', '-', phones)
        iElement += 1
        tmp = ''

    # final velar nasal
    phones = re.sub('^oh', '', phones)
    phones = re.sub('-(oh)', '', phones)
    phones = re.sub('oh-', 'ng-', phones)
    phones = re.sub('oh$', 'ng', phones)
    phones = re.sub('oh ', 'ng ', phones)

    phones = re.sub('(\W+)\-', '\\1', phones)
    phones = re.sub('\W+$', '', phones)
    phones = re.sub('^\-', '', phones)
    return phones


def phone2prono(phones):
    '''
    This function converts romanized phones to pronunciation
    '''
    # apply g2p rules
    for pattern, replacement in zip(rule_in, rule_out):
        phones = re.sub(pattern, replacement, phones)
        prono = phones
    return prono

# Import text file.
with open(txt_file,'r') as txt:
    txt_list = txt.readlines()

# Save lexicon.txt.
with open(save_dir,'w') as sav:
    for list in txt_list:
        in_str = re.sub('\n','',list)
        romanized = graph2phone(in_str)
        out_str = phone2prono(romanized)
        tmp = []
        phone_list=''
        jump=0
        for chop in range(int(len(out_str)/2)):
            tmp = out_str[chop+jump:chop+jump+2]
            jump += 1
            phone_list += ' '+tmp
        sav.write(in_str + '\t' + phone_list + '\n')
