#!/usr/bin/python2
import sys
import re

file= sys.argv[1] 
outfile1 = sys.argv[2]
#outfile2 = sys.argv[3]



f1= open(outfile1,"w+")

with open(file, "r") as my_file:
  for line in my_file:
  	  str = line.split(';')
  	  print >> f1, str[1], '.1'


f1.close()


