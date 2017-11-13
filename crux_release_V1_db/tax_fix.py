# Written by Emily Curd (eecurd@g.ucla.edu)
# for the University of California Conservation Consortium's CALeDNA Program

import sys
print sys.argv

input = sys.argv[1]
output = sys.argv[2]
print input
print output

infile = open(input)
outfile = open(output, "w+") # Clears existing file, open for writing

for line in infile:
    if len(line.strip()) == 0:
        # skip blank lines
        continue

    # Get columns 1 and 2, write it to file
    id = line.split('\t')[0]
    tax = line.split("\t")[1]
    outfile.write(id + "\t" + tax + "\n")

outfile.close()


