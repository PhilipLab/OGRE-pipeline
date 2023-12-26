#!/usr/bin/env python3

#SeriesDesc=['t1_mpr_1mm_p2_pos50', ...
#            'SpinEchoFieldMap2_AP',...
#            'SpinEchoFieldMap2_PA',...
#            'CMRR_fMRI_TASK_R1_AP_3mm_488meas_SBRef',...
#            'CMRR_fMRI_TASK_R1_AP_3mm_488meas',...
#            'CMRR_fMRI_TASK_R2_AP_3mm_488meas_SBRef',...
#            'CMRR_fMRI_TASK_R2_AP_3mm_488meas',...
#            'CMRR_fMRI_TASK_R3_AP_3mm_488meas_SBRef',...
#            'CMRR_fMRI_TASK_R3_AP_3mm_488meas',...
#            'CMRR_fMRI_TASK_R4_AP_3mm_488meas_SBRef',...
#            'CMRR_fMRI_TASK_R4_AP_3mm_488meas',...
#            'CMRR_fMRI_TASK_R5_AP_3mm_488meas_SBRef',...
#            'CMRR_fMRI_TASK_R5_AP_3mm_488meas',...
#            'CMRR_fMRI_TASK_R6_AP_3mm_488meas_SBRef',...
#            'CMRR_fMRI_TASK_R6_AP_3mm_488meas',...

#Need to find all occurences of field maps in case that got in and out of the scanner





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

with open(pdf,"rb") as fd:

    with open(csv,mode,encoding="utf8",errors='ignore') as f0:
        f0.write("Scan,Series Desc,nii\n")

        #searchstr='ep2d'
        #START231224
        #We always want the last one, so reading repetively is what we want to do.
        searchstr=['t1_mpr_1mm_p2_pos50']

        d0 = dict.fromkeys(searchstr,None)
        print(f'd0={d0}')

        viewer = SimplePDFViewer(fd)
        #viewer.render()

        #plain_text = ["".join(canvas.strings).split() for canvas in viewer]
        #print(f'plain_text={plain_text}')

        plain_text = []
        for canvas in viewer:
            plain_text += "".join(canvas.strings).split()
        print(f'plain_text={plain_text}')

        for j in d0: 
            for i in range(len(plain_text)):
                idx = plain_text[i].find(j)
                if idx > -1:
                    #scan = plain_text[i].split("files")[1].split(j)[0]
                    #print(plain_text[i]) 
                    #print(f'idx={idx}') 
                    #print(f'scan={scan}') 
                    d0[j] = plain_text[i].split("files")[1].split(j)[0]
                    print(f'd0={d0}') 


"""
        for canvas in viewer:
        #for canvas in viewer.render():

            #print(f'canvas.strings={canvas.strings}')
            #print(f'canvas.text_context={canvas.text_content}')

            #plain_text = "".join(canvas.strings)
            plain_text = "".join(canvas.strings).split()
            #print(f'plain_text={plain_text}')
            



            #indices = [i for i in range(len(canvas.strings)) if canvas.strings[i]==searchstr]
            #if indices:
            #    for i in range(0,len(indices),2):
            #        str=canvas.strings[indices[i]]+"_"+"".join(canvas.strings[indices[i]+1:indices[i+1]])
            #        f0.write(canvas.strings[indices[i]-1]+","+str+","+str+"\n")
            #START231224
            #for j in searchstr: 
            #    indices = [i for i in range(len(canvas.strings)) if canvas.strings[i]==j]
            #    if indices:
            #        for i in range(0,len(indices),2):
            #            str=canvas.strings[indices[i]]+"_"+"".join(canvas.strings[indices[i]+1:indices[i+1]])
            #            f0.write(canvas.strings[indices[i]-1]+","+str+","+str+"\n")
            #for j in searchstr: 
            #    indices = [i for i in range(len(plain_text)) if plain_text[i]==j]
            #    if indices:
            #        for i in range(0,len(indices),2):
            #            str=plain_text[indices[i]]+"_"+"".join(plain_text[indices[i]+1:indices[i+1]])
            #            f0.write(plain_text[indices[i]-1]+","+str+","+str+"\n")
            #for j in searchstr: 
            for j in d0: 
                for i in range(len(plain_text)):
                    idx = plain_text[i].find(j)
                    if idx > -1:
                        scan = plain_text[i].split("files")[1].split(j)[0]
                        print(plain_text[i]) 
                        print(f'idx={idx}') 
                        print(f'scan={scan}') 




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

"""
with open(pdf,"rb") as fd:
    with open("example-markdown.txt", "w") as f:
        viewer = SimplePDFViewer(fd)
        for canvas in viewer:
            markdown = canvas.text_content
            f.write(markdown)
"""
