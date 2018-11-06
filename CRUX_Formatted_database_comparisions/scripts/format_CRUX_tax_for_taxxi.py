#!/usr/bin/python2
import sys
import re

file= sys.argv[1] 
outfile1 = sys.argv[2]
#outfile2 = sys.argv[3]



f1= open(outfile1,"w+")

with open(file, "r") as my_file:
  for line in my_file:
  	  line = re.sub('\t', ';tax=d:', line)	
  	  str = line.split(';')
  	  print >> f1, str[0], ';', str[1], ';p:', str[2], ';c:', str[3], ';o:', str[4], ';f:', str[5], ';g:', str[6], ';s:', str[7],
  	  
#gi_EF535685;tax=d:Fungi,p:Ascomycota,c:Dothideomycetes,o:Capnodiales,f:Mycosphaerellaceae,g:Mycosphaerella;s:Mycosphaerella_sp;


f1.close()


#f2= open(outfile2,"w+")

#with open(file, "r") as my_file:
#  for line in my_file:
#  	  line = re.sub('\t', ';', line)	
#  	  str = line.split(';')
#  	  print >> f2, str[0], '\t', 'species:', str[7], ';', 'genus:', str[6],';', 'family:', str[5],';', 'order:', str[4],';', 'class:', str[3],';', 'phylum:',str[2],';', 'superkingdom:', str[1],';' 
  	  
  	  
#REF_GI_EU254776	genus:Gnomonia;family:Gnomoniaceae;order:Diaporthales;class:Sordariomycetes;phylum:Ascomycota;superkingdom:Fungi;


#f2.close()



