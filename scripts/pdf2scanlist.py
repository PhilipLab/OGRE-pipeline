#!/usr/bin/env python3

#https://pdfreader.readthedocs.io/en/latest/examples/extract_page_text.html
#https://note.nkmk.me/en/python-re-match-object-span-group/#:~:text=In%20Python's%20re%20module%2C%20match,provided%20by%20the%20match%20object.

#fmdict = {'task':'acq-task','rest':'acq-rest'}

import re
from pdfreader import SimplePDFViewer
from collections import Counter
from operator import itemgetter

#Dictionary: Key = SeriesDesc Value = ('overwrite' or 'append', 'anat' or 'fmap' or 'func', output root)
def get_protocol(file):
    with open(file,encoding="utf8",errors='ignore') as f0:
        dict0 = {}
        for line0 in f0:
            if not line0.strip() or line0.startswith('#'): continue
            #line1 = line0.replace(',',' ').split()
            #https://stackoverflow.com/questions/44785374/python-re-split-string-by-commas-and-space
            line1 = re.findall(r'[^,\s]+', line0)
            #print(f'line1={line1}')
            dict0[line1[0]] = (line1[1],line1[2],line1[3])
        #print(f'dict0={dict0}')
    return dict0

def pdf2txt(pdfs):
    plain_text = []
    for i in pdfs:
        with open(i,"rb") as fd:
            viewer = SimplePDFViewer(fd)
            for canvas in viewer:
                plain_text += "".join(canvas.strings).split()
    #print(f'plain_text={plain_text}')
    #[print(f'{txt}') for txt in plain_text]
    return plain_text

def txt2dict(plain_text):
    dict1={}
    cnt = Counter()
    for i in range(len(plain_text)):
        if plain_text[i].find('PhysioLog') > -1:
            continue
        for j in dict0:

            #print(f'j={j}')

            idx = plain_text[i].find(j)
            if idx > -1:
                #print(plain_text[i])

                #scan = re.findall(r'[0-9]+', plain_text[i][0:idx])
                #START240303 3600files33 rather than the intended files33
                scan = re.findall(r'[0-9]+', plain_text[i][idx-2:idx])


                name0 = parent0 + '/' + dict0[j][1] + '/' + n0 + '_'

                #First value (scan number) will be used to sort the second value (bids name), so the output is in the proper order.
                if dict0[j][0] == 'overwrite':

                    dict1[j] = (int(scan[0]), scan[0] + ',' + name0 + dict0[j][2])

                elif dict0[j][0] == 'append':
                    cnt[j] += 1

                    dict1[j+'-'+str(cnt[j])] = (int(scan[0]), scan[0] + ',' + name0 + dict0[j][2])

                #print(f'    {scan} {name}')

                break
    return dict1

                 

if __name__ == "__main__":
    import sys
    import argparse
    import json

    parser=argparse.ArgumentParser(description='Convert pdf(s) to a single scanlist.csv.\nRequired: <pdf(s)> -p <protocol.csv>',formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('dat0',metavar='<pdf(s)>',action='extend',nargs='*',help='Arguments without options are assumed to be pdfs.')

    #parser.add_argument('-pdf','--pdf',dest='dat',metavar='*.pdf',action='append',nargs='+',help='-pdf --pdf')
    parser.add_argument('-pdf','--pdf',dest='dat',metavar='*.pdf',action='append',nargs='+',help='One or more pdf files to convert to a single scanlist.csv.')

    hprotocol='Comma and/or space and/or tab separated file that specifies the protocol.'
    parser.add_argument('-p','--protocol','-protocol',dest='protocol',metavar='<protocol file>',help=hprotocol)

    hout='Override default output name of scanlist.\nEx. sub-2035_CNDA.pdf will output sub-2035_scanlist.csv'
    parser.add_argument('-o','--out','-out',dest='out',metavar='<output scanlist>',help=hout)

    hverbose='Echo messages to terminal.'
    parser.add_argument('-v','--verbose','-verbose',dest='verbose',action='store_true',help=hverbose)

    #https://stackoverflow.com/questions/22368458/how-to-make-argparse-print-usage-when-no-option-is-given-to-the-code
    if len(sys.argv)==1:
        parser.print_help()
        # parser.print_usage() # for just the usage line
        parser.exit()
    args=parser.parse_args()
    if args.dat:
        if args.dat0:
            args.dat += args.dat0
    elif args.dat0:
        args.dat=args.dat0
    else:
        exit()
    #print(f'args.dat={args.dat}')

    if not args.protocol:
        print(f'Error: Protocol must be specified. Abort!')
        exit()
    dict0 = get_protocol(args.protocol)

    import pathlib
    parent0 = str(pathlib.Path(args.dat[0]).resolve().parent)
    n0=pathlib.Path(args.dat[0]).stem
    m=re.match('sub-([0-9]+)',n0)
    if m is not None: n0=m.group()
    #print(f'n0={n0}')

    if args.out:
        ext = pathlib.Path(args.out).suffix 
        if ext == '': args.out += '.csv'
    else:
        args.out: args.out = parent0 + '/' + n0 + '_scanlist.csv' 

    plain_text = pdf2txt(args.dat)

    #cnt = Counter()

    #fmstr = fmdict['task']

    with open(args.out,'w',encoding="utf8",errors='ignore') as f0:

        dict1 = txt2dict(plain_text) 

        #print(f'dict1.values()={dict1.values()}')
        #[print(value) for value in dict1.values()]
        #print(json.dumps(dict1,indent=4))
        #print(f'cnt={cnt}')
        #[print(f'{key}, {val}') for key,val in dict1.items()]

        #edit fieldmap names
        cnt = Counter()
        key0=[]
        for key,val in dict1.items():
            #print(f'key={key} val={val}')


            if val[1].find('acq-dbsi') != -1:
                continue
            if val[1].find('epi') != -1:
                #print(f'here0 key={key} val={val}')
                #print(f'here0 val[1] = {val[1]}')

                #"2-back delete code" goes here

                key0.append(key)
                continue

            str_run=''
            if val[1].find('task-rest') != -1:
                str_acq='acq-rest'
            else:
                str_acq='acq-task'

                if cnt[str_acq] > 0:
                    idx=val[1].find('run-')
                    if idx != -1:
                        str_run = val[1][idx-1:idx+5]
                        #print(f'idx={idx}')
                        #print(f'val[1]={val[1]}')
                        #print(f'str_run={str_run}')
                    else:
                        str_acq='acq-rest'
                



            #print(f'val={val} str_acq={str_acq}')
            #print(f'key0={key0}')

            #str_cnt = ''
            #if cnt[str_acq] > 0: str_cnt = str(cnt[str_acq]+2)

            for k in key0:
                str1=dict1[k][1].split('dir') 
                #dict1[k] = (int(dict1[k][0]), str1[0] + str_acq + str_cnt + '_dir' + str1[1])
                #dict1[k] = (int(dict1[k][0]), str1[0] + str_acq + str_run + '_dir' + str1[1])
                #START240326
                dict1[k] = (int(dict1[k][0]), str1[0] + str_acq +  '_dir' + str1[1] + str_run)

            if key0: cnt[str_acq]+=1
            key0.clear()


        #[print(value) for value in dict1.values()]
        #[print(f'{key}, {val}') for key,val in dict1.items()]

        #output the second value of the tuple (bids name), sorted by the first value (scan number)
        #itemgetter is purported to be significantly faster than a lambda function
        #f0.write('\n'.join(i for i in list(zip(*sorted(dict1.values(),key=itemgetter(0))))[1]))
        #l0 = str(list(zip(*sorted(dict1.values(),key=itemgetter(0))))[1]).split(',')
        #l0 = list(zip(*sorted(dict1.values(),key=itemgetter(0))))[1]
        l0 = list(list(zip(*sorted(dict1.values(),key=itemgetter(0))))[1])
        #[print(l) for l in l0]
        #for i in range(len(l0)-2):
      
        i=0
        while i < len(l0)-2:
            #print(l0[i])
            str0 = l0[i].split(',')
            #print(str0)
            if str0[1].find('epi') != -1 and str0[1].find('acq-dbsi') == -1:
                if str0[1] == l0[i+2].split(',')[1]:
                    l0.pop(i)
                    continue
            i+=1

        f0.write('\n'.join(i for i in l0))

    if args.verbose: print(f'Output written to {args.out}')
