# Variables file for CRUX_release_V1		09-01-2017
# Written by Emily Curd (eecurd@g.ucla.edu) and Gaurav Kandlikar (gkandlikar@ucla.edu)
# Developed at UCLA for the University of California Conservation Consortium's CALeDNA Program

###########################
# Parameters
###########################

# EcoPCR parameters
ECOPCR_e="3"						# max errors allowed by oligonucleotide (0 by default)

CUTADAPT_ERROR=".3"   # Cutadapt max error allowed between primer and query sequence


# BLAST 1 parameters
BLAST1_eVALUE="0.00001"			# Expect value
BLAST1_NUM_THREADS="10"				# Number of threads to launch
BLAST1_PERC_IDENTITY="50" 			# minimum percent identity for the subject
BLAST1_HSP_PERC="100"					# minimum percent that the subject covert the length of the query
BLAST1_NUM_ALIGNMENTS="10000" 			# maximum number of alignments to add to the output
GAP_OPEN="1"   # penalty to open a gap
GAP_EXTEND="1"  # penalty to extend a gap


# BLAST 2 parameters
BLAST2_eVALUE="0.00001"			# Expect value
BLAST2_NUM_THREADS="10"				# Number of threads to launch
BLAST2_PERC_IDENTITY="70" 			# minimum percent identity for the subject
BLAST2_HSP_PERC="70"					# minimum percent that the subject covert the length of the query
BLAST2_NUM_ALIGNMENTS="10000" 			# maximum number of alignments to add to the output
GAP_OPEN="1"   # penalty to open a gap
GAP_EXTEND="1"  # penalty to extend a gap
