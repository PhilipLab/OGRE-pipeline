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
        #args.dat=[args.dat0]
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

    if not args.out:
        n0=pathlib.Path(args.dat[0]).stem
        m=re.match('sub-([0-9]+)',n0)
        if m is not None: n0=m.group()
        #args.out = str(pathlib.Path(args.dat[0]).resolve().parent) + '/' + n0 + '_runs.txt' 
        args.out = parent0 + '/' + n0 + '_runs.txt' 
        print(f'args.out={args.out}')
        
    from pdfreader import SimplePDFViewer
    plain_text = []
    for i in args.dat:
        with open(i,"rb") as fd:
            viewer = SimplePDFViewer(fd)
            for canvas in viewer:
                plain_text += "".join(canvas.strings).split()
    #print(f'plain_text={plain_text}')

"""
    with open(args.out,'w',encoding="utf8",errors='ignore') as f0:
        for i in range(len(plain_text)):
            if plain_text[i].find('PhysioLog') > -1:
                continue
            for j in dict0: 
                idx = plain_text[i].find(j)
                if idx > -1:
                    print(plain_text[i]) 
                    #print(f'    {plain_text[i][0:idx]}') 
                    #line1 = re.findall(r'[^,\s]+', line0)
                    #re.findall(r'[0-9]+', plain_text[i][0:idx])
                    print(f"    {re.findall(r'[0-9]+', plain_text[i][0:idx])}") 
                    break

"""







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
