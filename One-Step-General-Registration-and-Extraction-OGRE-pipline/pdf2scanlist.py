#!/usr/bin/env python3

#https://pdfreader.readthedocs.io/en/latest/examples/extract_page_text.html

#text='Append dbsi fields in pdf to scanlist.csv'
#START231213
text='pdf to scanlist.csv'

import sys
import argparse

parser=argparse.ArgumentParser(description=text,formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('subject',action='extend',nargs='*',help='<pdf> <scanlist.csv>')
parser.add_argument('-a','--append',help='Append to existing scanlist.csv',action="store_true")
parser.add_argument('-v','--verbose',help='Echo messages to terminal',action="store_true")
if len(sys.argv)==1:
    parser.print_help()
    # parser.print_usage() # for just the usage line
    parser.exit()
args=parser.parse_args()

mode="w"
if args.subject:
    pdf=args.subject[0]
    csv=args.subject[1]
    if args.append:
        print(f'-a --append {args.append}')
        mode="a"
else:
    exit()

from pdfreader import SimplePDFViewer

"""
with open(pdf,"rb") as fd:

    with open(csv,mode,encoding="utf8",errors='ignore') as f0:
        f0.write("Scan,Series Desc,nii\n")

        viewer = SimplePDFViewer(fd)
        searchstr='ep2d'
        for canvas in viewer:

            print(f'canvas={canvas}')
            print(f'canvas.strings={canvas.strings}')
            #print(f'canvas.text_context={canvas.text_content}')

            indices = [i for i in range(len(canvas.strings)) if canvas.strings[i]==searchstr]
            if indices:
                for i in range(0,len(indices),2):
                    str=canvas.strings[indices[i]]+"_"+"".join(canvas.strings[indices[i]+1:indices[i+1]])
                    f0.write(canvas.strings[indices[i]-1]+","+str+","+str+"\n")
        if args.verbose: print(f'Output written to {csv}')
"""

"""
with open(pdf,"rb") as fd:
    viewer = SimplePDFViewer(fd)
    markdown = viewer.canvas.text_content
    print(f'markdown = {markdown}');
    with open("example-markdown.txt", "w") as f:
        f.write(markdown)
    print(f'viewer.canvas.strings={viewer.canvas.strings}')
"""

with open(pdf,"rb") as fd:
    with open("example-markdown.txt", "w") as f:
        viewer = SimplePDFViewer(fd)
        for canvas in viewer:
            markdown = canvas.text_content
            f.write(markdown)
