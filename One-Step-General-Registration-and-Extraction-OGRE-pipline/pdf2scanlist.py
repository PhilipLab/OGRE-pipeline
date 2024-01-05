#!/usr/bin/env python3

#https://pdfreader.readthedocs.io/en/latest/examples/extract_page_text.html
#https://note.nkmk.me/en/python-re-match-object-span-group/#:~:text=In%20Python's%20re%20module%2C%20match,provided%20by%20the%20match%20object.

import re
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
                 

if __name__ == "__main__":
    import sys
    import argparse

    parser=argparse.ArgumentParser(description='Convert pdf(s) to a single scanlist.csv.\nRequired: <pdf(s)> -p <protocol.csv>',formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('dat0',metavar='<pdf(s)>',action='extend',nargs='*',help='Arguments without options are assumed to be pdfs.')
    parser.add_argument('-pdf','--pdf',dest='dat',metavar='*.pdf',action='append',nargs='+',help='-pdf --pdf')

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

    #if not args.out: args.out = parent0 + '/' + n0 + '_scanlist.csv' 
    #START240104
    if args.out:
        ext = pathlib.Path(args.out).suffix 
        if ext == '': args.out += '.csv'
    else:
        args.out: args.out = parent0 + '/' + n0 + '_scanlist.csv' 

        
    from pdfreader import SimplePDFViewer
    plain_text = []
    for i in args.dat:
        with open(i,"rb") as fd:
            viewer = SimplePDFViewer(fd)
            for canvas in viewer:
                plain_text += "".join(canvas.strings).split()
    #print(f'plain_text={plain_text}')

    from collections import Counter
    cnt = Counter()

    with open(args.out,'w',encoding="utf8",errors='ignore') as f0:
        dict1={}
        for i in range(len(plain_text)):
            if plain_text[i].find('PhysioLog') > -1:
                continue
            for j in dict0: 
                idx = plain_text[i].find(j)
                if idx > -1:
                    #print(plain_text[i]) 
                    scan = re.findall(r'[0-9]+', plain_text[i][0:idx]) 
                    name = parent0 + '/' + dict0[j][1] + '/' + n0 + '_' + dict0[j][2] 
                    if dict0[j][0] == 'overwrite':
                        dict1[j] = scan[0] + ',' + name
                    elif dict0[j][0] == 'append':
                        cnt[j] += 1
                        a0 = '-' + str(cnt[j])
                        dict1[j+a0] = scan[0] + ',' + name + a0
                    #print(f'    {scan} {name}') 
                    break
        #print(f'dict1.values()={dict1.values()}')
        f0.write('\n'.join(i for i in dict1.values()))
    if args.verbose: print(f'Output written to {args.out}')
