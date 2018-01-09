#! /bin/bash

### this script is run as follows
# sh ~/crux_part1.sh -n <primer_name> -f <forward_primer> -r <reverse_primer> -l <shortest amplicon expected> -m <longest amplicon expected> -o <output_directory> -d <database_directory> -c <clean up intermediate files y/n> -h <user>
NAME=""
FP=""
RP=""
ODIR=""
DB=""
SHRT=""
LNG=""
CLEAN=""
UN=""

while getopts "n:f:r:l:m:o:d:c:h:" opt; do
    case $opt in
        n) NAME="$OPTARG"
        ;;
        f) FP="$OPTARG"
        ;;
        r) RP="$OPTARG"
        ;;
        l) SHRT="$OPTARG"
        ;;
	      m) LNG="$OPTARG"
        ;;
        o) ODIR="$OPTARG"
        ;;
        d) DB="$OPTARG"
        ;;
        c) CLEAN="$OPTARG"
        ;;
        h) UN="$OPTARG"
        ;;
    esac
done


###########################################

# Emily Curd (eecurd@g.ucla.edu), Gaurav Kandlikar (gkandlikar@ucla.edu), and Jesse Gomer (jessegomer@gmail.com)
# Updated 07 September 2017

# this is a draft of a pipeline that takes any pair of primer sequences and generages a comprehensive reference database that could be amplified with those primers, using as much data from published sequences as posible.

# THE GOAL: is to capture not only the sequences that were submitted with primers included in the read (ecoPCR gets these), but also those that do not include primer regions but are some % of the length of the expected amplion (BLAST fills in these holes), and generate reference libraries and taxonomy files compatible with qiime or kraken taxonomy pipelines.

# Source the config and vars file so that we have programs and variables available to us
source $DB/scripts/crux_vars.sh
source $DB/scripts/crux_config.sh
${MODULE_SOURCE}
${QIIME}
${BOWTIE2}

echo " "
echo "in the case of failure check, that your the config file is accurate: $DB/crux_config.sh"
mkdir -p ${ODIR}/blast_jobs
mkdir -p ${ODIR}/blast_logs


##########################
# Part 1.1: ecoPCR
##########################

echo " "
echo " "
echo "Part 1.1:"
echo "Run ecoPCR with ${NAME} primers F- ${FP} R- ${RP} and these parameters:"
echo "     missmatch = ${ECOPCR_e}"
echo "If this is not what you want, then modify ${DB}/scripts/crux_vars.sh"
###
mkdir -p ${ODIR}/${NAME}_ecoPCR
mkdir -p ${ODIR}/${NAME}_ecoPCR/raw_out/
#run ecoPCR on each folder in the obitools database folder
for db in ${OBI_DB}/OB_dat_*/
do
 db1=${db%/}
 j=${db1#${OBI_DB}/}
 echo "..."${j}" ecoPCR is running"
 ${ecoPCR} -d ${db}${j} -e ${ECOPCR_e} -l ${SHRT} -L ${LNG} ${FP} ${RP} -D 1 > ${ODIR}/${NAME}_ecoPCR/raw_out/${NAME}_${j}_ecoPCR_out
 echo "..."${j}" ecoPCR is finished"
date
done
###

##########################
# Part 1.2: ecoPCR
##########################

echo " "
echo " "
echo "Part 1.2:"
echo "Clean ${NAME} ecoPCR output for blasting"
mkdir -p ${ODIR}/${NAME}_ecoPCR/
mkdir -p ${ODIR}/${NAME}_ecoPCR/clean_up
mkdir -p ${ODIR}/${NAME}_ecoPCR/cleaned
# make primer files for cutadapt step
printf ">${NAME}_F\n${FP}\n>${NAME}_R\n${RP}" > "${DB}/cutadapt_files/${NAME}.fasta"
python ${DB}/scripts/crux_format_primers_cutadapt.py ${DB}/cutadapt_files/${NAME}.fasta ${DB}/cutadapt_files/g_${NAME}.fasta ${DB}/cutadapt_files/a_${NAME}.fasta
#run ecoPCR through cutadapt to verify that the primer seqeunce exists, and to trim it off
for str in ${ODIR}/${NAME}_ecoPCR/raw_out/*_ecoPCR_out
do
 str1=${str%_ecoPCR_out}
 j=${str1#${ODIR}/${NAME}_ecoPCR/raw_out/}
 #reformat ecoPCR out and remove duplicate reads by taxid
 tail -n +14 ${str} |cut -d "|" -f 3,21|sed "s/ | /,/g"|awk -F"," '!_[$1]++' | sed "s/\s//g" |awk 'BEGIN { FS=","; } {print ">"$1"\n"$2}' > ${ODIR}/${NAME}_ecoPCR/clean_up/${j}_ecoPCR_blast_input.fasta
 #run cut adapt
 ${CUTADAPT} -e .2 -a file:${DB}/cutadapt_files/a_${NAME}.fasta  --untrimmed-output ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_untrimmed_1.fasta -o ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_ecoPCR_blast_input_a_clean.fasta ${ODIR}/${NAME}_ecoPCR/clean_up/${j}_ecoPCR_blast_input.fasta >> ${ODIR}/${NAME}_ecoPCR/clean_up/${j}_cutadapt-report.txt
 ${CUTADAPT} -e .2 -g file:${DB}/cutadapt_files/g_${NAME}.fasta  --untrimmed-output ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_untrimmed_2.fasta -o ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_ecoPCR_blast_input_a_and_g_clean.fasta ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_ecoPCR_blast_input_a_clean.fasta >> ${ODIR}/${NAME}_ecoPCR/clean_up/${j}_cutadapt-report.txt
 echo "..."${j}" is clean"
date
done
###

##########################
# Part 1.2: Submit BLAST 1 job
##########################

echo " "
echo " "
echo "Part 1.3:"
echo "Clean ${NAME} ecoPCR output for blasting and submit blast1 array job"

### if file 0b discard?code from https://www.cyberciti.biz/faq/linux-unix-script-check-if-file-empty-or-not/
## loop through ecoPCR results
for str in ${ODIR}/${NAME}_ecoPCR/cleaned/*_ecoPCR_blast_input_a_and_g_clean.fasta
do
 str1=${str%_ecoPCR_blast_input_a_and_g_clean.fasta}
 j=${str1#${ODIR}/${NAME}_ecoPCR/cleaned/}
 mkdir -p ${ODIR}/${NAME}_ecoPCR/cleaned/${j}
 mkdir -p ${ODIR}/${NAME}_BLAST/
 mkdir -p ${ODIR}/${NAME}_BLAST/${j}_BLAST_out
 mkdir -p ${ODIR}/${NAME}_BLAST/${j}_BLAST_out/raw
 mkdir -p ${ODIR}/${NAME}_BLAST/${j}_BLAST_out/fasta
 [ $# -eq 0 ] && { echo "Usage: $0 filename"; exit 1; }
 [ ! -f "${str}" ] && { echo "Error: $0 file not found."; exit 2; }
 if [ -s "${str}" ]
  then
  echo " "
  echo "${str} has ecoPCR reads that passed the minimum criteria to move to the next step."
  # split ecopcr output into files with 500 reads each
  split -l 1000 ${str} ${ODIR}/${NAME}_ecoPCR/cleaned/${j}/blast_ready_
    # replace aa, ab,... etc. from split outputand replcae with concecutive numbers 1, 2, ... etc.
    i = 1
  for nam in {ODIR}/${NAME}_ecoPCR/cleaned/${j}/blast_ready_*
	do
     cp ${nam} ${nam}_${i}
	 i = i+1
    done
  	for st in ${ODIR}/${NAME}_ecoPCR/cleaned/${j}/blast_ready_*
	  do
     l=${st#${ODIR}/${NAME}_ecoPCR/cleaned/${j}/}
     # submit 2blast jobs for each file.  One that collects partial length hits, and one that collects full length hits
     printf "#!/bin/bash\n#$ -l highp,h_rt=05:00:00,h_data=30G\n#$ -N blast1_${j}_${NAME}\n#$ -cwd\n#$ -m bea\n#$ -M ${UN} \n#$ -o ${ODIR}/blast_logs/blast1_${j}_${NAME}.out\n#$ -e ${ODIR}/blast_logs/ blast1_${j}_${NAME}.err \n\n\n sh ${DB}/scripts/sub_blast1.sh -n ${NAME} -q ${st} -o ${ODIR} -j ${j} -l ${l} -d ${DB} \n" >> ${ODIR}/blast_jobs/${j}_blast1.sh
	   qsub ${ODIR}/blast_jobs/${j}_blast1.sh
     printf "#!/bin/bash\n#$ -l highp,h_rt=05:00:00,h_data=30G\n#$ -N blast2_${j}_${NAME}\n#$ -cwd\n#$ -m bea\n#$ -M ${UN} \n#$ -o ${ODIR}/blast_logs/ blast2_${j}_${NAME}\n#$ -e ${ODIR}/blast_logs/ blast2_${j}_${NAME}.err \n\n\n sh ${DB}/scripts/sub_blast2.sh -n ${NAME} -q ${st} -o ${ODIR} -j ${j} -l ${l} -d ${DB} \n" >> ${ODIR}/blast_jobs/${j}_blast2.sh
	   qsub ${ODIR}/blast_jobs/${j}_blast2.sh
    done
 else
  echo " "
  echo "${str} did not pass the minimum criteria that passes ecoPCR reads to the next step."
  rm ${str}
  echo " Don't panic ${str} was deleted because it was empty, and we do not need it in the next step"
 fi
done
###
echo "  Once all array jobs have run, submit crux_par2.sh"
