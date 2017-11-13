#!/user/bin/env/ python

# Written by Emily Curd (eecurd@g.ucla.edu), with help from https://www.biostars.org/p/14614/
# for the University of California Conservation Consortium's CALeDNA Program
# Reverse complement primers
# python <path to script> <input primer file> <modified regular complement file> <modified reverse complement file>

import sys
infile = open(sys.argv[1], "r") #fasta made from prmers



nuc_dict = {'A':'T','T':'A','U':'A','G':'C','C':'G','Y':'R','R':'Y','S':'S','W':'W','K':'M','M':'K','B':'V','D':'H','H':'D','V':'B','N':'N','a':'T','t':'A','u':'A','g':'C','c':'G','y':'R','r':'Y','s':'S','w':'W','k':'M','m':'K','b':'V','d':'H','h':'D','v':'B','n':'N'}

def rComp(read):
    rc = ''
    for i in range(len(read) - 1,-1,-1):
        rc += nuc_dict[read[i]]

    return rc
    
### make regular primers with ^seq -> g
outfile1 = open(sys.argv[2], "w+") # forwards with ^seq
header = ''
seq = ''
for line in infile:
    if line[0] == ">":
    	header = line.strip() 
        outfile1.write(header + "\n")  
    else:
    	seq = line.strip()
    	outfile1.write("^" + seq + "\n")
outfile1.close()
infile.close()

infile = open(sys.argv[1], "r")
### make reverse complement primers with seq$ -> a
outfile2 = open(sys.argv[3], "w+") # forwards with ^seq
header = ''
seq = ''
for line in infile:
    if line[0] == ">":
    	header = line.strip() 
        outfile2.write(header + "_rc" + "\n")  
    else:
    	seq = line.strip()
    	outfile2.write(rComp(seq)+ "$" + "\n")
outfile2.close()

 