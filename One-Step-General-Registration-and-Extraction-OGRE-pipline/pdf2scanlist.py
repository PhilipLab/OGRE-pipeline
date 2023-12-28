#!/usr/bin/env python3

#https://pdfreader.readthedocs.io/en/latest/examples/extract_page_text.html

"""
SeriesDesc=['t1_mpr_1mm_p2_pos50', ...
            'SpinEchoFieldMap2_AP',...
            'SpinEchoFieldMap2_PA',...
            'CMRR_fMRI_TASK_R1_AP_3mm_488meas_SBRef',...
            'CMRR_fMRI_TASK_R1_AP_3mm_488meas',...
            'CMRR_fMRI_TASK_R2_AP_3mm_488meas_SBRef',...
            'CMRR_fMRI_TASK_R2_AP_3mm_488meas',...
            'CMRR_fMRI_TASK_R3_AP_3mm_488meas_SBRef',...
            'CMRR_fMRI_TASK_R3_AP_3mm_488meas',...
            'CMRR_fMRI_TASK_R4_AP_3mm_488meas_SBRef',...
            'CMRR_fMRI_TASK_R4_AP_3mm_488meas',...
            'CMRR_fMRI_TASK_R5_AP_3mm_488meas_SBRef',...
            'CMRR_fMRI_TASK_R5_AP_3mm_488meas',...
            'CMRR_fMRI_TASK_R6_AP_3mm_488meas_SBRef',...
            'CMRR_fMRI_TASK_R6_AP_3mm_488meas',...
            'ep2ddbsi_b0_PE=PA',...
            'ep2ddbsi_19_2mm_iso_LowBW_2av',...
            'CMRR_fMRI_REST_R1_AP_3mm_550meas_SBRef',...
            'CMRR_fMRI_REST_R1_AP_3mm_550meas',...
            'CMRR_fMRI_REST_R2_AP_3mm_550meas_SBRef',...
            'CMRR_fMRI_REST_R2_AP_3mm_550meas',...
            'CMRR_fMRI_REST_R3_AP_3mm_550meas_SBRef',...
            'CMRR_fMRI_REST_R3_AP_3mm_550meas',...
            't2_spc_sag_p2_iso1.0']
"""

#We should set this up so this can also be loaded as a paramter file (ie csv) that is read into DICT
#Dictionary: Key = SeriesDesc Value = ('overwrite' or 'append', 'anat' or 'fmap' or 'func', output root)

#Need to find all occurences of field maps in case that got in and out of the scanner
#Will need to check how the dbsi is named.

"""
DICT={'t1_mpr_1mm_p2_pos50'                    : ('overwrite', 'anat', 't1_mpr_1mm_p2_pos50'          ), ...
      'SpinEchoFieldMap2_AP'                   : ('append',    'fmap', 'SpinEchoFieldMap2_AP'         ), ...
      'SpinEchoFieldMap2_PA'                   : ('append',    'fmap', 'SpinEchoFieldMap2_PA'         ), ...
      'CMRR_fMRI_TASK_R1_AP_3mm_488meas_SBRef' : ('overwrite', 'func', 'task-drawRH_run-1_SBRef'      ), ...
      'CMRR_fMRI_TASK_R1_AP_3mm_488meas'       : ('overwrite', 'func', 'task-drawRH_run-1'            ), ...
      'CMRR_fMRI_TASK_R2_AP_3mm_488meas_SBRef' : ('overwrite', 'func', 'task-drawLH_run-1_SBRef'      ), ...
      'CMRR_fMRI_TASK_R2_AP_3mm_488meas'       : ('overwrite', 'func', 'task-drawLH_run-1'            ), ...
      'CMRR_fMRI_TASK_R3_AP_3mm_488meas_SBRef' : ('overwrite', 'func', 'task-drawRH_run-2_SBRef'      ), ...
      'CMRR_fMRI_TASK_R3_AP_3mm_488meas'       : ('overwrite', 'func', 'task-drawRH_run-2'            ), ...
      'CMRR_fMRI_TASK_R4_AP_3mm_488meas_SBRef' : ('overwrite', 'func', 'task-drawLH_run-2_SBRef'      ), ...
      'CMRR_fMRI_TASK_R4_AP_3mm_488meas'       : ('overwrite', 'func', 'task-drawLH_run-2'            ), ...
      'CMRR_fMRI_TASK_R5_AP_3mm_488meas_SBRef' : ('overwrite', 'func', 'task-drawRH_run-3_SBRef'      ), ...
      'CMRR_fMRI_TASK_R5_AP_3mm_488meas'       : ('overwrite', 'func', 'task-drawRH_run-3'            ), ...
      'CMRR_fMRI_TASK_R6_AP_3mm_488meas_SBRef' : ('overwrite', 'func', 'task-drawLH_run-3_SBRef'      ), ...
      'CMRR_fMRI_TASK_R6_AP_3mm_488meas'       : ('overwrite', 'func', 'task-drawLH_run-3'            ), ...
      'ep2ddbsi_b0_PE=PA',                     : ('overwrite', 'fmap', 'ep2ddbsi_b0_PE=PA'            ), ...
      'ep2ddbsi_19_2mm_iso_LowBW_2av',         : ('overwrite', 'anat', 'ep2ddbsi_19_2mm_iso_LowBW_2av'), ...
      'CMRR_fMRI_REST_R1_AP_3mm_550meas_SBRef' : ('overwrite', 'func', 'rest01_SBRef'                 ), ...
      'CMRR_fMRI_REST_R1_AP_3mm_550meas'       : ('overwrite', 'func', 'rest01'                       ), ...
      'CMRR_fMRI_REST_R2_AP_3mm_550meas_SBRef' : ('overwrite', 'func', 'rest02_SBRef'                 ), ...
      'CMRR_fMRI_REST_R2_AP_3mm_550meas'       : ('overwrite', 'func', 'rest02'                       ), ...
      'CMRR_fMRI_REST_R3_AP_3mm_550meas_SBRef' : ('overwrite', 'func', 'rest03_SBRef'                 ), ...
      'CMRR_fMRI_REST_R3_AP_3mm_550meas'       : ('overwrite', 'func', 'rest03'                       ), ...
      't2_spc_sag_p2_iso1.0'                   : ('overwrite', 'anat', 't2_spc_sag_p2_iso1.0'         )}
"""

import re
def get_protocol(file):
    with open(file,encoding="utf8",errors='ignore') as f0:
        for line0 in f0:
            if not line0.strip() or line0.startswith('#'): continue
            #line1 = line0.replace(',',' ').split()
            #https://stackoverflow.com/questions/44785374/python-re-split-string-by-commas-and-space
            line1 = re.findall(r'[^,\s]+', line0)
            print(f'line1={line1}')
                 

#    for i in args.dat:
#        for j in range(len(i)):
#            with open(i[j],encoding="utf8",errors='ignore') as f0:
#                for line0 in f0:
#                    if not line0.strip() or line0.startswith('#'): continue
#                    if not 'keys' in locals():
#                        keys = line0.split()
#                        continue
#                    d0 = Dat(dict(zip(keys,line0.split())))
#                    dir0 = d0.OUTDIR + FREESURFVER




#            if not 'keys' in locals():
#                keys = line0.split()
#                continue
#            d0 = Dat(dict(zip(keys,line0.split())))








if __name__ == "__main__":
    import sys
    import argparse

    parser=argparse.ArgumentParser(description='Convert pdf(s) to a single scanlist.csv.\nRequired: <pdf(s)> -p <protocol.csv>',formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('dat0',metavar='<pdf(s)>',action='extend',nargs='*',help='Arguments without options are assumed to be pdfs.')
    parser.add_argument('-pdf','--pdf',dest='dat',metavar='*.pdf',action='append',nargs='+',help='-pdf --pdf')

    hprotocol='Comma and/or space and/or tab separated file that specifies the protocol.'
    parser.add_argument('-p','--protocol','-protocol',dest='protocol',metavar='protocol file',help=hprotocol)

    hout='Override default output name of scanlist.'
    parser.add_argument('-o','--out','-out',dest='out',metavar='output scanlist',help=hout)

    hverbose='Echo messages to terminal.'
    parser.add_argument('-v','--verbose','-verbose',dest='verbose',action='store_true',help=hverbose)



    #parser.add_argument('subject',action='extend',nargs='*',help='<pdf> <scanlist.csv>')
    #parser.add_argument('-a','--append',help='Append to existing scanlist.csv',action="store_true")
    #parser.add_argument('-v','--verbose',help='Echo messages to terminal',action="store_true")
    #if len(sys.argv)==1:
    #    parser.print_help()
    #    # parser.print_usage() # for just the usage line
    #    parser.exit()
    #args=parser.parse_args()
    #mode="w"
    #if args.subject:
    #    pdf=args.subject[0]
    #    csv=args.subject[1]
    #    if args.append:
    #        print(f'-a --append {args.append}')
    #        mode="a"
    #else:
    #    exit()
    #START231226
    #https://stackoverflow.com/questions/22368458/how-to-make-argparse-print-usage-when-no-option-is-given-to-the-code
    if len(sys.argv)==1:
        parser.print_help()
        # parser.print_usage() # for just the usage line
        parser.exit()
    args=parser.parse_args()
    if args.dat:
        if args.dat0:
            #args.dat.append(args.dat0)
            args.dat += args.dat0
    elif args.dat0:
        args.dat=[args.dat0]
    else:
        exit()

    if not args.protocol:
        print(f'Error: Protocol must be specified. Abort!')
        exit()
    get_protocol(args.protocol)

"""
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
