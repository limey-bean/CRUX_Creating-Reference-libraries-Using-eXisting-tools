#! /bin/bash

### this script is run as follows
# sh ~/crux_release_V1_from_blast_out.sh -n <primer_name> -f <forward_primer> -r <reverse_primer> -l <shortest amplicon expected> -m <longest amplicon expected> -o <output_directory> -d <database_directory> -c <clean up intermediate files y/n>
NAME=""
FP=""
RP=""
ODIR=""
DB=""
SHRT=""
LNG=""
CLEAN=""

while getopts "n:f:r:l:m:o:d:c:" opt; do
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
##########################
# Part 1: ecoPCR
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
for db in ${OBI_DB}/EMBL*/
do
 db1=${db%/}
 j=${db1#${OBI_DB}/}
 echo "..."${j}" ecoPCR is running"
 ${ecoPCR} -d ${db}${j} -e ${ECOPCR_e} -l ${SHRT} -L ${LNG} ${FP} ${RP} -D 1 > ${ODIR}/${NAME}_ecoPCR/raw_out/${NAME}_${j}_ecoPCR_out
 echo "..."${j}" ecoPCR is finished"
date
done
###
${MODULE_SOURCE}
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
#run cutadapt through out fiels
for str in ${ODIR}/${NAME}_ecoPCR/raw_out/*_ecoPCR_out
do
 str1=${str%_ecoPCR_out}
 j=${str1#${ODIR}/${NAME}_ecoPCR/raw_out/}
 tail -n +14 ${str} |cut -d "|" -f 3,21|sed "s/ | /,/g"|awk -F"," '!_[$1]++' | sed "s/\s//g" |awk 'BEGIN { FS=","; } {print ">"$1"\n"$2}' > ${ODIR}/${NAME}_ecoPCR/clean_up/${j}_ecoPCR_blast_input.fasta
 ${CUTADAPT} -e .2 -a file:${DB}/cutadapt_files/a_${NAME}.fasta  --untrimmed-output ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_untrimmed_1.fasta -o ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_ecoPCR_blast_input_a_clean.fasta ${ODIR}/${NAME}_ecoPCR/clean_up/${j}_ecoPCR_blast_input.fasta >> ${ODIR}/${NAME}_ecoPCR/clean_up/${j}_cutadapt-report.txt
 ${CUTADAPT} -e .2 -g file:${DB}/cutadapt_files/g_${NAME}.fasta  --untrimmed-output ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_untrimmed_2.fasta -o ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_ecoPCR_blast_input_a_and_g_clean.fasta ${ODIR}/${NAME}_ecoPCR/cleaned/${j}_ecoPCR_blast_input_a_clean.fasta >> ${ODIR}/${NAME}_ecoPCR/clean_up/${j}_cutadapt-report.txt
 echo "..."${j}" is clean"
date
done
### if file 0b discard?code from https://www.cyberciti.biz/faq/linux-unix-script-check-if-file-empty-or-not/
## loop through ecoPCR results
for str in ${ODIR}/${NAME}_ecoPCR/cleaned/*_ecoPCR_blast_input_a_and_g_clean.fasta
do
 [ $# -eq 0 ] && { echo "Usage: $0 filename"; exit 1; }
 [ ! -f "${str}" ] && { echo "Error: $0 file not found."; exit 2; }
 if [ -s "${str}" ] 
  then
  echo " "
  echo "${str} has ecoPCR reads that passed the minimum criteria to move to the next step."
    # do something as file has data
 else
  echo " "
  echo "${str} did not pass the minimum criteria that passes ecoPCR reads to the next step."
  rm ${str}
  echo " Don't panic ${str} was deleted because it was empty, and we do not need it in the next step"
  # do something as file is empty 
 fi
done 
###

##########################
# Part 2: blasting
##########################
echo " "
echo " "
echo "Part 2:" 
echo "Run blast with ${NAME} ecoPCR results and these parameters:" 
echo "     BLAST e-value = ${BLAST_eVALUE}"
echo "     number of threads = ${BLAST_NUM_THREADS}"
echo "     minimum percent identity for a genbank read that aligns to an ecoPCR generated sequences = ${BLAST_PERC_IDENTITY}"
echo "     minimum percent of coverage length for a genbank read that aligns to an ecoPCR generated sequence= ${BLAST_HSP_PERC}"
echo "     number of alignments to include in the output = ${BLAST_NUM_ALIGNMENTS}"
echo "If this is not what you want, then modify ${DB}/scripts/crux_vars.sh"
mkdir -p ${ODIR}/${NAME}_BLAST
${LOAD_BLAST}
for str in ${ODIR}/${NAME}_ecoPCR/cleaned/*_ecoPCR_blast_input_a_and_g_clean.fasta
do
 str1=${str%_ecoPCR_blast_input_a_and_g_clean.fasta}
 j=${str1#${ODIR}/${NAME}_ecoPCR/cleaned/}
 echo "..."${j}" is running"
 ${BLASTn_CMD} -query ${str} -out ${ODIR}/${NAME}_BLAST/${j}_BLAST_out.txt -db ${BLAST_DB} -evalue ${BLAST_eVALUE} -outfmt "6 saccver staxid sseq" -num_threads ${BLAST_NUM_THREADS} -perc_identity ${BLAST_PERC_IDENTITY} -qcov_hsp_perc ${BLAST_HSP_PERC} -num_alignments ${BLAST_NUM_ALIGNMENTS} -gapopen 1 -gapextend 1
 echo "..."${j}" is finished"
date
done
###


##########################
# Part 3: Cleaning up blast results
##########################
echo " "
echo " "
echo "Part 3.1: Cleaning up blast results" 
echo "For each set of BLAST results"
echo "     Merge and De-replicate by NCBI accession version numbers, and convert to fasta format."
echo "     Then use entrez-qiime to generate a corresponding taxonomy file, and clean the blast output and taxonomy file to eliminate poorly annotated sequences." 
mkdir -p ${ODIR}/${NAME}_fasta_and_taxonomy/
mkdir -p ${ODIR}/${NAME}_fasta_and_taxonomy/dirty
### merge and clean blast data
cat ${ODIR}/${NAME}_BLAST/*_BLAST_out.txt  | sed "s/-//g"| awk -F"\t" '!_[$1]++' |awk 'BEGIN { FS="\t"; } {print ">"$1"\n"$3}' >> ${ODIR}/${NAME}_fasta_and_taxonomy/dirty/${NAME}_dirty.fasta
echo "...Running ${j} entrez-qiime and cleaning up fasta and taxonomy files" 
python ${ENTREZ_QIIME} -i ${ODIR}/${NAME}_fasta_and_taxonomy/dirty/${NAME}_dirty.fasta -o ${ODIR}/${NAME}_fasta_and_taxonomy/dirty/${NAME}_dirty_taxonomy -n ${TAXO} -a ${A2T} 
python ${DB}/scripts/clean_blast.py ${ODIR}/${NAME}_fasta_and_taxonomy/dirty/${NAME}_dirty.fasta ${ODIR}/${NAME}_fasta_and_taxonomy/${NAME}_.fasta ${ODIR}/${NAME}_fasta_and_taxonomy/dirty/${NAME}_dirty_taxonomy.txt ${ODIR}/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt
python ${DB}/scripts/tax_fix.py ${ODIR}/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt ${ODIR}/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt.tmp
grep '[^[:blank:]]'  ${ODIR}/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt.tmp > ${ODIR}/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt
rm ${ODIR}/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt.tmp
echo "... ${j} final fasta and taxonomy database complete"


##########################
# Part 4: Turn the reference libraries into Bowtie2 searchable libraries
##########################

echo " "
echo " "
echo "Part 5:" 
echo "The bowtie2 database files for ${NAME} can be found in the ${NAME}_bowtie2_databases folder in ${ODIR}:" 
mkdir -p ${ODIR}/${NAME}_bowtie2_database
bowtie2-build -f ${ODIR}/${NAME}_fasta_and_taxonomy/${NAME}_.fasta ${ODIR}/${NAME}_bowtie2_database/${NAME}_bowtie2_index
date
echo " "
echo " "

##########################
# Part 5: Delete the intermediate steps
##########################

echo " "
echo " "
echo "Part 5:" 
echo "Deleting the intermediate files: ${CLEAN}" 
if [ ${CLEAN} = "n" ]
 then
    echo "nothing to delete"
 elif [ ${CLEAN} = "y" ]
 then
    echo "Deleting"
    echo "...${NAME} ecoPCR directory"
    rmdir ${ODIR}/${NAME}_ecoPCR
    echo "...${NAME} BLAST directory"
    rmdir ${ODIR}/${NAME}_BLAST
    echo "...${NAME} first cluster step directory"
 else
    echo "-c variable not recognized, nothing to delete"
fi
date
echo " "
echo " "
