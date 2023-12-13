#!/usr/bin/env python3
text='Append dbsi fields in pdf to scanlist.csv'

import sys

import argparse
parser=argparse.ArgumentParser(description=text,formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('subject',action='extend',nargs='*',help='<pdf> <scanlist.csv>')

#START231103
parser.add_argument('-a','--append',help='Append to existing scanlist.csv',action="store_true")
parser.add_argument('-v','--verbose',help='Echo messages to terminal',action="store_true")

if len(sys.argv)==1:
    parser.print_help()
    # parser.print_usage() # for just the usage line
    parser.exit()

args=parser.parse_args()

#START231103
mode="w"

if args.subject:
    pdf=args.subject[0]
    csv=args.subject[1]

    #START231103
    if args.append:
        print(f'-a --append {args.append}')
        mode="a"

else:
    exit()

#from pdfreader import PDFDocument, SimplePDFViewer
from pdfreader import SimplePDFViewer

with open(pdf,"rb") as fd:

    #with open(csv,"a",encoding="utf8",errors='ignore') as f0:
    #START231103
    with open(csv,mode,encoding="utf8",errors='ignore') as f0:
        f0.write("Scan,Series Desc,nii\n")

        viewer = SimplePDFViewer(fd)
        searchstr='ep2d'
        for canvas in viewer:
            indices = [i for i in range(len(canvas.strings)) if canvas.strings[i]==searchstr]
            if indices:
                for i in range(0,len(indices),2):
                    str=canvas.strings[indices[i]]+"_"+"".join(canvas.strings[indices[i]+1:indices[i+1]])
                    f0.write(canvas.strings[indices[i]-1]+","+str+","+str+"\n")
        
        #START231103
        if args.verbose: print(f'Output written to {csv}')
