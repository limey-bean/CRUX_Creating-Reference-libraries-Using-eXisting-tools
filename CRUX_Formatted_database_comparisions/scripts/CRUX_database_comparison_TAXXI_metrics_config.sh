#############################
# Paths to programs / load programs
#############################

MODULE_SOURCE="source /u/local/Modules/default/init/bash" 	#if none, leave empty <- for HPC

#load anaconda/python2-4.2
ANACONDA_PYTHON="module load anaconda"				#or whatever code is used to load anaconda/python2-4.2 in a bash shell, or path to anaconda/python2-4.2
#load bowtie2
BOWTIE2="module load bowtie2"							# version 2.3.4 or what ever code is used to load bowtie2 in a bash shell, or path to bowtie2
#load ATS
ATS="module load ATS"									#or what ever code is used to load ATS in a bash shell, or path to ATS.  ATS is a Hoffman2 module that allows the user to submit a job on the HPC from within a shell script
# load qiime/1.8.0
QIIME="module load qiime/1.8.0"
