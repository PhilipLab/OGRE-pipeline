#**** These are overwritten by their environment variables in get_env_vars ****
FSLDIR='/usr/local/fsl'
FREESURFDIR='/Applications/freesurfer'
FREESURFVER='7.4.1'
SHEBANG = "#!/usr/bin/env bash"

import os
import subprocess

# https://www.geeksforgeeks.org/how-to-check-if-a-python-variable-exists/

def get_env_vars(args):
    gev = Envvars()
    gev.overwrite(args)
    if not gev.check(): return False
    gev.assign() 
    return gev
    

class Envvars:

    def __init__(self):

        self.FSLDIR=FSLDIR
        self.FREESURFDIR=FREESURFDIR
        self.FREESURFVER=FREESURFVER
        self.SHEBANG=SHEBANG

        self.OGREDIR = None
        self.HCPDIR = None
        self.WBDIR = None

        try:
            self.OGREDIR = os.environ['OGREDIR']
        except KeyError:
            pass
        try:
            self.WBDIR = os.environ['WBDIR']
        except KeyError:
            pass
        try:
            self.HCPDIR = os.environ['HCPDIR']
        except KeyError:
            pass
        try:
            self.FSLDIR = os.environ['FSLDIR']
        except KeyError:
            pass
        try:
            self.FREESURFDIR = os.environ['FREESURFDIR']
        except KeyError:
            pass
        try:
            self.FREESURFVER = os.environ['FREESURFVER']
        except KeyError:
            pass

    def overwrite(self,args):
        if args.OGREDIR: self.OGREDIR = args.OGREDIR
        if args.FREESURFVER: self.FREESURFVER = args.FREESURFVER
        if args.HCPDIR: self.HCPDIR = args.HCPDIR 

    def check(self):
        if not self.OGREDIR:
            print('OGREDIR not set. Abort!\nBefore calling this script: export OGREDIR=<OGRE directory>\nor via an option to this script: -OGREDIR <OGRE directory>\n')
            return False 
        return True

    def assign(self):
        if not self.HCPDIR:
            self.HCPDIR = self.OGREDIR + '/lib/HCP'
            print(f'HCPDIR not set. Setting it to {self.HCPDIR}')
        if not self.WBDIR:
            self.WBDIR = self.HCPDIR + '/lib/HCP/workbench-mac/bin_macosx64'
            print(f'WBDIR not set. Setting it to {self.WBDIR}')




def run_cmd(cmd):
    return subprocess.run(cmd, capture_output=True, shell=True).stdout.decode().strip()
    #START240515
    #return subprocess.run(cmd, capture_output=True, shell=False, check=True, text=True).stdout.decode().strip()
    #print('********* here-1 ******************')
    #try:
    #    #out = subprocess.run(cmd, capture_output=True, shell=False, check=True, text=True).stdout.decode().strip()
    #    #subprocess.run(cmd, capture_output=True, shell=False, check=True, text=True).stdout.decode().strip()
    #    #subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=False, check=True, text=True).stdout.decode().strip()
    #    print('********* here0 ******************')
    #    subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=False, check=True, text=True)
    #except subprocess.CalledProcessError as e:
    #    print('********* here1 ******************')
    #    #print(out)
    #    print(e.returncode)
    #    print(e.output)
    #    exit()
    #return subprocess.STDOUT

def make_executable(path):
    mode = os.stat(path).st_mode
    mode |= (mode & 0o444) >> 2    # copy R bits to X
    os.chmod(path, mode)
