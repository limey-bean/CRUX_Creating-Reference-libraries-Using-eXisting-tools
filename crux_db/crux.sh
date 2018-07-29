#! /bin/bash

### this script is run as follows
# sh ~CRUX/crux_db/crux.sh  -n <Metabarcode locus primer set name>  -f <Metabarcode locus forward primer sequence>  -r <Metabarcode locus reverse primer sequence>  -s <Shortest amplicon expected>  -m <Longest amplicon expected>  -o <path to output directory>  -d <path to crux_db>  -x <If retaining intermediate files no argument needed>  -u <If running on an HPC this is your username: e.g. eecurd>  -l <If running locally no argument needed>  -k <Chunk size for breaking up blast seeds (default
# 500)> -e	<Maximum number of mismatch between primers and EMBL database sequences> -g <Maximum number of allowed errors for filtering and trimming the BLAST seed sequences with cutadapt> -t <The number of threads to launch for the first round of BLAST>  -v <The minimum accepted value for BLAST hits in the first round of BLAST >  -i <The minimum percent ID for BLAST hits in the first round of BLAST>  -c <Minimum percent of length of a query that a BLAST hit must cover >  -a <Maximum number of
# BLAST hits to return for each query>  -j <The number of threads to launch for the first round of BLAST>  -w <The minimum accepted value for BLAST hits in the first round of BLAST>  -p  <The minimum percent ID for BLAST hits in the first round of BLAST >  -f <Minimum percent of length of a query that a BLAST hit must cover>  -b <Job Submit header>  -h <Shows program usage then quits>

NAME=""
FP=""
RP=""
ODIR=""
DB=""
SHRT=""
LNG=""
CLEAN="TRUE"
UN=""
LOCALMODE="FALSE"
CHUNK=""
ERROR=""
CDERROR=""
THREAD1=""
EVAL1=""
ID1=""
COV1=""
RETURN=""
GO=""
GE=""
THREAD2=""
EVAL2=""
ID2=""
COV2=""
HEADER=""
HELP=""

while getopts "n:f:r:s:m:o:d:q?:u:l?:k:e:g:t:v:i:c:a:z:y:j:w:p:x:b:h?:" opt; do
    case $opt in
        n) NAME="$OPTARG"
        ;;
        f) FP="$OPTARG"
        ;;
        r) RP="$OPTARG"
        ;;
        s) SHRT="$OPTARG"
        ;;
	      m) LNG="$OPTARG"
        ;;
        o) ODIR="$OPTARG"
        ;;
        d) DB="$OPTARG"
        ;;
        q) CLEAN="FLASE"
        ;;
        u) UN="$OPTARG"
        ;;
        l) LOCALMODE="TRUE"
        ;;
        k) CHUNK="$OPTARG"
        ;;
        e) ERROR="$OPTARG"
        ;;
        g) CDERROR="$OPTARG"
        ;;
        t) THREAD1="$OPTARG"
        ;;
        v) EVAL1="$OPTARG"
        ;;
        i) ID1="$OPTARG"
        ;;
        c) COV1="$OPTARG"
        ;;
        a) RETURN="$OPTARG"
        ;;
        z) GO="$OPTARG"
        ;;
        y) GE="$OPTARG"
        ;;
        j) THREAD2="$OPTARG"
        ;;
        w) EVAL2="$OPTARG"
        ;;
        p) ID2="$OPTARG"
        ;;
        x) COV2="$OPTARG"
        ;;
        b) HEADER="$OPTARG"
        ;;
        h) HELP="TRUE"
        ;;
    esac
done

if [ "${HELP}" = "TRUE" ]
then
  printf "<<< CRUX: Sequence Creating Reference Libraries Using eXisting tools>>>\n\nThe purpose of these script is to generate metabarcode locus specific reference libraries. This script takes PCR primer sets, runs ecoPRC (in silico PCR) on EMBL (or other OBITools formatted) databases, then BLASTs the resulting sequences ncbi's nr database, and generates database files for unique NCBI sequences. The final databases are either filtered (sequences with ambiguous taxonomy removed) of unfiltered and consist of a fasta file, a taxonomy file, and a Bowtie2 Index library. \n	For successful implementation \n		1. Make sure you have all of the dependencies and correct paths in the crux_config.sh file\n		2. All parameters can be modified using the arguments below.  Alternatively, all parameters can be altered in the crux_vars.sh folder\n\nArguments:\n- Required:\n	-n	Metabarcode locus primer set name\n	-f	Metabarcode locus forward primer sequence  \n	-r	Metabarcode locus reverse primer sequence  \n	-s	Shortest amplicon expected (e.g. 100 bp shorter than the average amplicon length\n	-m	Longest amplicon expected (e.g. 100 bp longer than the average amplicon length\n	-o	path to output directory\n	-d	path to crux_db\n\n- Optional:\n	-q	If retaining intermediate files: -x (no argument needed; Default is to delete intermediate files) \n	-u	If running on an HPC (e.g. UCLA's Hoffman2 cluster), this is your username: e.g. eecurd\n	-l	If running locally: -l  (no argument needed)\n	-k	Chunk size for breaking up blast seeds (default 500)\n	-e	Maximum number of mismatch between primers and EMBL database sequences (default 3)\n	-g	Maximum number of allowed errors for filtering and trimming the BLAST seed sequences with cutadapt (default 0.3)\n	-t	The number of threads to launch for the first round of BLAST (default 10)\n	-v	The minimum accepted value for BLAST hits in the first round of BLAST (default 0.00001)\n	-i 	The minimum percent ID for BLAST hits in the first round of BLAST (default 50)\n	-c	Minimum percent of length of a query that a BLAST hit must cover (default 100)\n	-a	Maximum number of BLAST hits to return for each query (default 10000)\n	-z	BLAST gap opening penalty\n	-y	BLAST gap extension penalty\n	-j	The number of threads to launch for the first round of BLAST (default 10)\n	-w	The minimum accepted value for BLAST hits in the first round of BLAST (default 0.00001)\n	-p 	The minimum percent ID for BLAST hits in the first round of BLAST (default 70)\n	-x	Minimum percent of length of a query that a BLAST hit must cover (default 70)\n	-b	HPC mode header template\n\n- Other:\n	-h	Shows program usage then quits\n\n\n"
  exit
else
  echo ""
fi

case "$DB" in
*/)
    DB=${DB%/}
    ;;
*)
    echo ""
    ;;
esac

case "$OUT" in
*/)
    ODIR=${ODIR%/}
    ;;
*)
    echo ""
    ;;
esac

###########################################

# Emily Curd (eecurd@g.ucla.edu), Gaurav Kandlikar (gkandlikar@ucla.edu), and Jesse Gomer (jessegomer@gmail.com)
# Updated 07 September 2017

# this is a draft of a pipeline that takes any pair of primer sequences and generages a comprehensive reference database that could be amplified with those primers, using as much data from published sequences as posible.

# THE GOAL: is to capture not only the sequences that were submitted with primers included in the read (ecoPCR gets these), but also those that do not include primer regions but are some % of the length of the expected amplion (BLAST fills in these holes), and generate reference libraries and taxonomy files compatible with qiime or kraken taxonomy pipelines.

# Source the config and vars file so that we have programs and variables available to us

if [[ -z ${HEADER} ]];
then
  source $DB/scripts/HPC_mode_header.sh
else
  source ${HEADER}
fi

###Local or HPC mode check for username
if [[ "${LOCALMODE}" = "TRUE"  ]];
then
  echo "Running in local mode"
elif [[ "${LOCALMODE}" = "FALSE" && ! -z ${UN} ]];
then
  echo "Running in HPC mode"
elif [[ "${LOCALMODE}" = "FALSE" &&  -z ${UN} ]];
then
  echo "Running in HPC mode"
  echo "No username given..."
  echo ""
  exit
fi

#Check that user has all of the default flags set
if [[ ! -z ${ODIR} && -e ${DB} && ! -z ${FP} && ! -z ${RP} && ! -z ${SHRT} && ! -z ${LNG} && ! -z ${NAME} ]];
then
  echo "Required Arguments Given"
  echo ""
else
  echo "Required Arguments Missing:"
  echo "check that you included arguments or correct paths for -n -f -r -o -d -s and -m"
  echo ""
  exit
fi

source $DB/scripts/crux_vars.sh
source $DB/scripts/crux_config.sh

${MODULE_SOURCE}
${QIIME}
${BOWTIE2}
${ATS} #load ATS, Hoffman2 specific module for managing submitted jobs.


echo " "
mkdir -p ${ODIR}/Run_info/blast_jobs
mkdir -p ${ODIR}/Run_info/blast_logs
mkdir -p ${ODIR}/Run_info/cut_adapt_out


##########################
# Part 1.1: ecoPCR
##########################

echo " "
echo " "
echo "Part 1.1:"
echo "Run ecoPCR with ${NAME} primers F- ${FP} R- ${RP} and these parameters:"
echo "     missmatch = ${ERROR:=$ECOPCR_e}"
echo "     expected amplicon length between ${SHRT} and ${LNG}"
echo ""
###
mkdir -p ${ODIR}/${NAME}_ecoPCR
mkdir -p ${ODIR}/${NAME}_ecoPCR/raw_out/
#run ecoPCR on each folder in the obitools database folder
for db in ${OBI_DB}/OB_dat_*/
do
 db1=${db%/}
 j=${db1#${OBI_DB}/}
 echo "..."${j}" ecoPCR is running"
 ${ecoPCR} -d ${db}${j} -e ${ERROR:=$ECOPCR_e} -l ${SHRT} -L ${LNG} ${FP} ${RP} -D 1 > ${ODIR}/${NAME}_ecoPCR/raw_out/${NAME}_${j}_ecoPCR_out
 echo "..."${j}" ecoPCR is finished"
 echo ""
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
mkdir -p ${ODIR}/cutadapt_files
mkdir -p ${ODIR}/${NAME}_ecoPCR/
mkdir -p ${ODIR}/${NAME}_ecoPCR/clean_up
mkdir -p ${ODIR}/${NAME}_ecoPCR/cleaned
# make primer files for cutadapt step
printf ">${NAME}_F\n${FP}\n>${NAME}_R\n${RP}" > "${ODIR}/cutadapt_files/${NAME}.fasta"
python ${DB}/scripts/crux_format_primers_cutadapt.py ${ODIR}/cutadapt_files/${NAME}.fasta ${ODIR}/cutadapt_files/g_${NAME}.fasta ${ODIR}/cutadapt_files/a_${NAME}.fasta
#run ecoPCR through cutadapt to verify that the primer seqeunce exists, and to trim it off
for str in ${ODIR}/${NAME}_ecoPCR/raw_out/*_ecoPCR_out
do
 str1=${str%_ecoPCR_out}
 j=${str1#${ODIR}/${NAME}_ecoPCR/raw_out/}
 #reformat ecoPCR out and remove duplicate reads by taxid
 tail -n +14 ${str} |cut -d "|" -f 3,21|sed "s/ | /,/g"|awk -F"," '!_[$1]++' | sed "s/\s//g" |awk 'BEGIN { FS=","; } {print ">"$1"\n"$2}' > ${ODIR}/${NAME}_ecoPCR/clean_up/${j}_ecoPCR_blast_input.fasta
 #run cut adapt
 ${CUTADAPT} -e ${CDERROR:=$CUTADAPT_ERROR} -a file:${ODIR}/cutadapt_files/a_${NAME}.fasta  --untrimmed-output ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_untrimmed_1.fasta -o ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_ecoPCR_blast_input_a_clean.fasta ${ODIR}/${NAME}_ecoPCR/clean_up/${j}_ecoPCR_blast_input.fasta >> ${ODIR}/Run_info/cut_adapt_out/${j}_cutadapt-report.txt
 ${CUTADAPT} -e ${CDERROR:=$CUTADAPT_ERROR} -g file:${ODIR}/cutadapt_files/g_${NAME}.fasta  --untrimmed-output ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_untrimmed_2.fasta -o ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_ecoPCR_blast_input_a_and_g_clean.fasta ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_ecoPCR_blast_input_a_clean.fasta >> ${ODIR}/Run_info/cut_adapt_out/${j}_cutadapt-report.txt
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
echo "Clean ${NAME} ecoPCR output for blasting and run BLAST jobs"

## loop through ecoPCR results

if [ "${LOCALMODE}" = "FALSE" ];
then
 for str in ${ODIR}/${NAME}_ecoPCR/cleaned/*_ecoPCR_blast_input_a_and_g_clean.fasta
 do
  str1=${str%_ecoPCR_blast_input_a_and_g_clean.fasta}
  j=${str1#${ODIR}/${NAME}_ecoPCR/cleaned/}
  mkdir -p ${ODIR}/${NAME}_ecoPCR/cleaned/${j}

  if [ -s "${str}" ];
  then
    mkdir -p ${ODIR}/${NAME}_BLAST/
    mkdir -p ${ODIR}/${NAME}_BLAST/${j}_BLAST_out
    mkdir -p ${ODIR}/${NAME}_BLAST/${j}_BLAST_out/raw
    mkdir -p ${ODIR}/${NAME}_BLAST/${j}_BLAST_out/fasta
    echo " "
    echo "${str} has ecoPCR reads that passed the minimum criteria to move to the next step."
    # split ecopcr output into files with 500 reads each
    split -l 1000 ${str} ${ODIR}/${NAME}_ecoPCR/cleaned/${j}/blast_ready_
     # do something as file has data
    i=1
    for nam in ${ODIR}/${NAME}_ecoPCR/cleaned/${j}/blast_ready_*
  	do
	    nam1=${nam%_*}
	 # submit blast jobs for each file, and then remove reads with duplicate accession version numbers
      cp ${nam} ${nam1}_${i}
      rm ${nam}
      echo "${nam1}_${i}_blast_1.complete" >> ${ODIR}/${NAME}_BLAST/blast_complete_outfiles.txt
      echo "${nam1}_${i}_blast_2.complete" >> ${ODIR}/${NAME}_BLAST/blast_complete_outfiles.txt
      ((i=i+1))
    done
    # if local blast in line
    # if not local submit blast array jobs
    ### count number of files in the directory
    file_count=$( shopt -s nullglob ; set -- ${ODIR}/${NAME}_ecoPCR/cleaned/${j}/blast_ready_* ; echo $#)
    # submit blast jobs for each file, and then remove reads with duplicate accession version numbers
    array_var="\$SGE_TASK_ID"
    printf "${BLAST1_HEADER}\n#$ -t 1-${file_count}\n\n\n/bin/bash ${DB}/scripts/sub_blast1.sh -n ${NAME} -q ${nam1}_${array_var} -o ${ODIR} -k ${j} -l blast_ready_${array_var} -d ${DB} -v ${EVAL1:=$BLAST1_eVALUE} -t ${THREAD1:=$BLAST1_NUM_THREADS} -i ${ID1:=$BLAST1_PERC_IDENTITY} -c ${COV1:=$BLAST1_HSP_PERC} -a ${RETURN:=$BLAST1_NUM_ALIGNMENTS} -y ${GO:=$GAP_OPEN} -z ${GE:=$GAP_EXTEND}\n" > ${ODIR}/Run_info/blast_jobs/blast1_${j}.sh
    ${QUEUESUBMIT} ${ODIR}/Run_info/blast_jobs/blast1_${j}.sh
    printf "${BLAST2_HEADER}\n#$ -t 1-${file_count}\n\n\n/bin/bash ${DB}/scripts/sub_blast2.sh -n ${NAME} -q ${nam1}_${array_var} -o ${ODIR} -k ${j} -l blast_ready_${array_var} -d ${DB} -w ${EVAL2:=$BLAST2_eVALUE} -j ${THREAD2:=$BLAST2_NUM_THREADS} -p ${ID2:=$BLAST2_PERC_IDENTITY} -x ${COV2:=$BLAST2_HSP_PERC} -a ${RETURN:=$BLAST2_NUM_ALIGNMENTS} -y ${GO:=$GAP_OPEN} -z ${GE:=$GAP_EXTEND}\n" > ${ODIR}/Run_info/blast_jobs/blast2_${j}.sh
    ${QUEUESUBMIT} ${ODIR}/Run_info/blast_jobs/blast2_${j}.sh
  else
    echo " "
    echo "${str} did not pass the minimum criteria that passes ecoPCR reads to the next step."
    rm ${str}
  fi
 done
else
  for str in ${ODIR}/${NAME}_ecoPCR/cleaned/*_ecoPCR_blast_input_a_and_g_clean.fasta
  do
   str1=${str%_ecoPCR_blast_input_a_and_g_clean.fasta}
   j=${str1#${ODIR}/${NAME}_ecoPCR/cleaned/}
   mkdir -p ${ODIR}/${NAME}_ecoPCR/cleaned/${j}
   echo ""
   echo "run BLAST inline"
   if [ -s "${str}" ];
   then
     mkdir -p ${ODIR}/${NAME}_BLAST/
     mkdir -p ${ODIR}/${NAME}_BLAST/${j}_BLAST_out
     mkdir -p ${ODIR}/${NAME}_BLAST/${j}_BLAST_out/raw
     mkdir -p ${ODIR}/${NAME}_BLAST/${j}_BLAST_out/fasta
     echo " "
     echo "${str} has ecoPCR reads that passed the minimum criteria."
     # split ecopcr output into files with 500 reads each
     split -l 1000 ${str} ${ODIR}/${NAME}_ecoPCR/cleaned/${j}/blast_ready_
      # do something as file has data
     i=1
     for nam in ${ODIR}/${NAME}_ecoPCR/cleaned/${j}/blast_ready_*
     do
       nam1=${nam%_*}
    # submit blast jobs for each file, and then remove reads with duplicate accession version numbers
       cp ${nam} ${nam1}_${i}
       rm ${nam}
       echo ""
       echo "Running BLAST1 on ${nam1}_${i}"
       date
       printf "#!/bin/bash\n\n\n/bin/bash ${DB}/scripts/sub_blast1.sh -n ${NAME} -q ${nam1}_${i} -o ${ODIR} -k ${j} -l blast_ready_${i} -d ${DB} -v ${EVAL1:=$BLAST1_eVALUE} -t ${THREAD1:=$BLAST1_NUM_THREADS} -i ${ID1:=$BLAST1_PERC_IDENTITY} -c ${COV1:=$BLAST1_HSP_PERC} -a ${RETURN:=$BLAST1_NUM_ALIGNMENTS} -y ${GO:=$GAP_OPEN} -z ${GE:=$GAP_EXTEND}\n" > ${ODIR}/Run_info/blast_jobs/blast1_${j}_${i}.sh
       /bin/bash ${ODIR}/Run_info/blast_jobs/blast1_${j}_${i}.sh
       echo "Running BLAST2 on ${nam1}_${i}"
       date
       printf "#!/bin/bash\n\n\n/bin/bash ${DB}/scripts/sub_blast2.sh -n ${NAME} -q ${nam1}_${i} -o ${ODIR} -k ${j} -l blast_ready_${i} -d ${DB} -w ${EVAL2:=$BLAST2_eVALUE} -j ${THREAD2:=$BLAST2_NUM_THREADS} -p ${ID2:=$BLAST2_PERC_IDENTITY} -x ${COV2:=$BLAST2_HSP_PERC} -a ${RETURN:=$BLAST2_NUM_ALIGNMENTS} -y ${GO:=$GAP_OPEN} -z ${GE:=$GAP_EXTEND}\n" > ${ODIR}/Run_info/blast_jobs/blast2_${j}_${i}.sh
       /bin/bash ${ODIR}/Run_info/blast_jobs/blast2_${j}_${i}.sh
       ((i=i+1))
     done
     date
   else
     echo " "
     echo "${str} did not pass the minimum criteria that passes ecoPCR reads to the next step."
     rm ${str}
   fi
  done
fi

# need to check if the array is done before moving on to the next step
if [ "${LOCALMODE}" = "FALSE" ];
then
 filename="${ODIR}/${NAME}_BLAST/blast_complete_outfiles.txt"
 filelines=`cat $filename`
 echo Start
 for line in $filelines ; do
  while ! [ -f ${line} ];
  do
   echo "files not ready"
   sleep 600
  done
 done
else
  echo ""
fi

###

##########################
# Part 2.1: Cleaning up blast results
##########################

################################ once all array jobs are finished run this script
echo " "
echo " "
echo "Part 2.1: Cleaning up blast results"
echo "For each set of BLAST 1 and 2 results"
echo "     Merge and De-replicate by NCBI accession version numbers, and convert to fasta format."
echo "     Then use entrez-qiime to generate a corresponding taxonomy file, and clean the blast output and taxonomy file to eliminate poorly annotated sequences."
mkdir -p ${ODIR}/${NAME}_db_filtered/${NAME}_fasta_and_taxonomy/
mkdir -p ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy

# for each BLAST_out fasta folder
for str in ${ODIR}/${NAME}_BLAST/${NAME}_*_out
do
  str1=${str%_BLAST_out}
  j=${str1#${ODIR}/${NAME}_BLAST/${NAME}_}
  echo "${str}"
  echo "${j}"
  # reduce size blast files by combining and dereplicating by length.
  python ${DB}/scripts/combine_and_dereplicate_fasta.py -o ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_${j}_blast_out.fasta -a ${str}/fasta/*_out.fasta
done

# for all of of derepliated blast hits, combine and depreplicate by length
python ${DB}/scripts/combine_and_dereplicate_fasta.py -o ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_.fasta -a ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/*_blast_out.fasta
rm ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/*_blast_out.fasta

### add taxonomy using entrez_qiime.py
echo "...Running ${j} entrez-qiime and cleaning up fasta and taxonomy files"
python ${ENTREZ_QIIME} -i ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_.fasta -o ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy -n ${TAXO} -a ${A2T} -r superkingdom,phylum,class,order,family,genus,species
# clean up reads based on low resolution taxonomy and store filtered reads in filtered file
python ${DB}/scripts/clean_blast.py ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_.fasta ${ODIR}/${NAME}_db_filtered/${NAME}_fasta_and_taxonomy/${NAME}_.fasta ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt ${ODIR}/${NAME}_db_filtered/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt
python ${DB}/scripts/tax_fix.py ${ODIR}/${NAME}_db_filtered/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt ${ODIR}/${NAME}_db_filtered/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt.tmp
grep '[^[:blank:]]'  ${ODIR}/${NAME}_db_filtered/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt.tmp > ${ODIR}/${NAME}_db_filtered/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt
rm ${ODIR}/${NAME}_db_filtered/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt.tmp
echo "... ${j} final fasta and taxonomy database complete"


##########################
# Part 2.2: Turn the reference libraries into Bowtie2 searchable libraries
##########################

echo " "
echo " "
echo "Part 2.2:"
echo "The bowtie2 database files for ${NAME} can be found in the ${NAME}_bowtie2_databases within the ${NAME}_db_unfiltered and ${NAME}_db_filtered folder's in ${ODIR}:"
#make bowtie2 databases for filtered and unfiltered database
mkdir -p ${ODIR}/${NAME}_db_unfiltered/${NAME}_bowtie2_database
bowtie2-build -f ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_.fasta ${ODIR}/${NAME}_db_unfiltered/${NAME}_bowtie2_database/${NAME}_bowtie2_index
date
echo " "
echo " "
mkdir -p ${ODIR}/${NAME}_db_filtered/${NAME}_bowtie2_database/
bowtie2-build -f ${ODIR}/${NAME}_db_filtered/${NAME}_fasta_and_taxonomy/${NAME}_.fasta ${ODIR}/${NAME}_db_filtered/${NAME}_bowtie2_database/${NAME}_bowtie2_index
date
echo " "
echo " "



##########################
# Part 2.3: Delete the intermediate steps
##########################

echo " "
echo " "
echo "Part 2.3:"
echo "Deleting the intermediate files: ${CLEAN}"
#if [[ ${CLEAN} = "FALSE" ]];
# then
#    echo "nothing to delete"
# else
#    echo "Deleting"
#    echo "...${NAME} ecoPCR directory"
#    rm -r ${ODIR}/${NAME}_ecoPCR
#    echo "...${NAME} BLAST directory"
##    echo "...${NAME} first cluster step directory"
#fi
date
echo " "
echo " "
