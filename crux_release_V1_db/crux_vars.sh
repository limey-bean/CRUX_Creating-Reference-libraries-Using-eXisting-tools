# Variables file for CRUX_release_V1		09-01-2017
# Written by Emily Curd (eecurd@g.ucla.edu) and Gaurav Kandlikar (gkandlikar@ucla.edu)
# Developed at UCLA for the University of California Conservation Consortium's CALeDNA Program

###########################
# Parameters
###########################

# EcoPCR parameters
ECOPCR_e="5"						# max errors allowed by oligonucleotide (0 by default)

# BLAST parameters
BLAST_eVALUE="0.0000000001"			# Expect value
BLAST_NUM_THREADS="100"				# Number of threads to launch
BLAST_PERC_IDENTITY="60" 			# minimum percent identity for the subject
BLAST_HSP_PERC="70"					# minimum percent that the subject covert the length of the query
BLAST_NUM_ALIGNMENTS="1500" 			# maximum number of alignments to add to the output

#First Qiime Pick OTUs parameters
METHOD_OTU="usearch" 				#otu picking method
USEARCH61_SORT_METHOD="abundance" 	#clusters will be sorted by most abundant reads
SIM=".80" 					#clusters will be generated based on sequence similarity
MINSIZE="1" 						#minimum number of reads included in a cluster

#First Qiime Assign Taxonomy parameters
METHOD_AT="uclust" 					#taxonomy assignment method
UCLUST_MIN_CONSENSUS_FRACTION=".90" # minimum fraction of reads that have to have the same taxonomic id for that id to be retained at a given taxonomic level. 
UCLUST_MAX_ACCEPT="35" 			# maximum number of hits retained

#Final Qiime Pick OTUs parameters
FMETHOD_OTU="usearch" 				#otu picking method
FUSEARCH61_SORT_METHOD="abundance" 	#clusters will be sorted by most abundant reads
FUSEARCH_SIM=".99" 					#clusters will be generated based on sequence similarity
FMINSIZE="1" 						#minimum number of reads included in a cluster

#Final Qiime Assign Taxonomy parameters
FMETHOD_AT="uclust" 					#taxonomy assignment method
FUCLUST_MIN_CONSENSUS_FRACTION=".90" # minimum fraction of reads that have to have the same taxonomic id for that id to be retained at a given taxonomic level. 
FUCLUST_MAX_ACCEPT="100" 			# maximum number of hits retained
FUCLUST_SIMILARITY=".99" 			# similarity threshold for taxonomic assignment

