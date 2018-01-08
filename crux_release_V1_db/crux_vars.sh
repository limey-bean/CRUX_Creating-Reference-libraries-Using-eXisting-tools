# Variables file for CRUX_release_V1		09-01-2017
# Written by Emily Curd (eecurd@g.ucla.edu) and Gaurav Kandlikar (gkandlikar@ucla.edu)
# Developed at UCLA for the University of California Conservation Consortium's CALeDNA Program

###########################
# Parameters
###########################

# EcoPCR parameters
ECOPCR_e="5"						# max errors allowed by oligonucleotide (0 by default)

# BLAST 1 parameters
BLAST_eVALUE1="0.00001"			# Expect value
BLAST_NUM_THREADS1="1"				# Number of threads to launch
BLAST_PERC_IDENTITY1="50" 			# minimum percent identity for the subject
BLAST_HSP_PERC1="1000"					# minimum percent that the subject covert the length of the query
BLAST_NUM_ALIGNMENTS1="5000" 			# maximum number of alignments to add to the output




# BLAST 2 parameters
BLAST_eVALUE="0.0000000001"			# Expect value
BLAST_NUM_THREADS="1"				# Number of threads to launch
BLAST_PERC_IDENTITY="70" 			# minimum percent identity for the subject
BLAST_HSP_PERC="80"					# minimum percent that the subject covert the length of the query
BLAST_NUM_ALIGNMENTS="2000" 			# maximum number of alignments to add to the output
