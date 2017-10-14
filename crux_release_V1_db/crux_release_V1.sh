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
${BOWTIE@}

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
echo "     De-replicate by NCBI accession version numbers, and convert to fasta format."
echo "     Then use entrez-qiime to generate a corresponding taxonomy file, and clean the blast output and taxonomy file to eliminate poorly annotated sequences." 
mkdir -p ${ODIR}/${NAME}_first_cluster_step/
mkdir -p ${ODIR}/${NAME}_first_cluster_step/clean_up_first_cluster/
mkdir -p ${ODIR}/${NAME}_second_cluster_step
mkdir -p ${ODIR}/${NAME}_second_cluster_step/clean_first_cluster
###
for str in ${ODIR}/${NAME}_BLAST/${NAME}_*_BLAST_out.txt
do
 str1=${str%_BLAST_out.txt}
 j=${str1#${ODIR}/${NAME}_BLAST/}
 echo " "
 echo "...Processing ${j} blast output"
 cat ${str1}_BLAST_out.txt  | sed "s/-//g"| awk -F"\t" '!_[$1]++' |awk 'BEGIN { FS="\t"; } {print ">"$1"\n"$3}' > ${str1}_dirty_dereplicated_BLAST.fasta
 echo "...Running ${j} entrez-qiime" 
 python ${ENTREZ_QIIME} -i ${str1}_dirty_dereplicated_BLAST.fasta -o ${str1}_dirty_dereplicated_BLAST_taxonomy -n ${TAXO} -a ${A2T} 
 mkdir -p ${ODIR}/${NAME}_first_cluster_step/${j}
 python ${DB}/scripts/clean_blast.py ${str1}_dirty_dereplicated_BLAST.fasta ${ODIR}/${NAME}_first_cluster_step/${j}/${j}_dereplicated_BLAST.fasta ${str1}_dirty_dereplicated_BLAST_taxonomy.txt ${ODIR}/${NAME}_first_cluster_step/${j}/${j}_dereplicated_BLAST_taxonomy.txt
 echo "... ${j} blast output is ready for the next step"
 date
done
### Cycle through the clean blast output for each of the percent identity uclusts
# for uclust in uslusts...
echo " "
echo "Part 3.2:" 
echo "Run Qiime Pick OTUS and Assign Taxonomy on the cleaned ${NAME} BLAST results with the following parameters:" 
echo "     Pick OTUs "
echo "               = ${METHOD_OTU} Clustering method at ${METHOD_OTU}"
echo "               = Read sorting method is ${USEARCH61_SORT_METHOD}"
echo "               = Minimum number of reads per cluster is ${MINSIZE}"
echo "     Assign Taxonomy "
echo "               = ${METHOD_AT} Clustering method at ${UCLUST_SIMILARITY}"
echo "               = Percent similarity within clusters is ${UCLUST_SIMILARITY}"
echo "               = Maximum number of references that can match to a cluster is ${UCLUST_MIN_CONSENSUS_FRACTION}"
echo "               = Minimum percent of taxonomic consensus needed for taxonomy assignment is ${UCLUST_MIN_CONSENSUS_FRACTION}"
echo "If this is not what you want, then modify ${DB}/scripts/crux_vars.sh"
echo " "
for perc in ${SIM}
 do
 echo "##################Clustering reads at ${perc}##################"
# do the following
 for str in ${ODIR}/${NAME}_BLAST/${NAME}_*_BLAST_out.txt
 do
  str1=${str%_BLAST_out.txt}
  j=${str1#${ODIR}/${NAME}_BLAST/} 
  echo " "
  echo "****for reads in ${j}****"
  echo "...Running Pick OTUs"
  pick_otus.py -m ${METHOD_OTU} --usearch61_sort_method ${USEARCH61_SORT_METHOD} -i ${ODIR}/${NAME}_first_cluster_step/${j}/${j}_dereplicated_BLAST.fasta -o ${ODIR}/${NAME}_first_cluster_step/${j}/${j}_dereplicated_BLAST_${METHOD_OTU}_${perc} -s ${perc} --suppress_reference_chimera_detection --minsize ${MINSIZE} --enable_rev_strand_match 
  echo "...Pick OTUs is finished"
  date
  echo " "
  echo "...Running Assign Taxonomy"
  assign_taxonomy.py -i ${ODIR}/${NAME}_first_cluster_step/${j}/${j}_dereplicated_BLAST_${METHOD_OTU}_${perc}/dereplicated_seqs.fasta -o ${ODIR}/${NAME}_first_cluster_step/${j}/${NAME}_dereplicated_BLAST_assign_taxonomy_${METHOD_AT}_${perc} -r ${ODIR}/${NAME}_first_cluster_step/${j}/${j}_dereplicated_BLAST.fasta -t ${ODIR}/${NAME}_first_cluster_step/${j}/${j}_dereplicated_BLAST_taxonomy.txt  -m ${METHOD_AT} --uclust_min_consensus_fraction ${UCLUST_MIN_CONSENSUS_FRACTION} --uclust_max_accepts ${UCLUST_MAX_ACCEPT} --uclust_similarity ${perc} 
  echo "...Assign Taxonomy is finished"
  date
  echo " "
  echo "...Clean up taxonomy files"
  python ${DB}/scripts/clean_blast.py ${ODIR}/${NAME}_first_cluster_step/${j}/${j}_dereplicated_BLAST_${METHOD_OTU}_${perc}/dereplicated_seqs.fasta ${ODIR}/${NAME}_first_cluster_step/clean_up_first_cluster/${j}_first_cluster_unclean_${perc}.fasta ${ODIR}/${NAME}_first_cluster_step/${j}/${NAME}_dereplicated_BLAST_assign_taxonomy_${METHOD_AT}_${perc}/dereplicated_seqs_tax_assignments.txt ${ODIR}/${NAME}_first_cluster_step/clean_up_first_cluster/${j}_first_cluster_taxonomy_unclean_${perc}.txt
  echo "...Taxonomy is clean"
  echo " "
  done
done
#### modify taxonomy and fasta files so that when they are merged they are unique
echo " "
echo " "
for str in ${ODIR}/${NAME}_first_cluster_step/clean_up_first_cluster/*_first_cluster_taxonomy_unclean_*.txt
  do
  str1=${str%.txt}
  j=${str1#${ODIR}/${NAME}_first_cluster_step/clean_up_first_cluster/*_first_cluster_taxonomy_unclean_}
  str2=${str%_first_cluster_taxonomy_unclean_*.txt}
  k=${str2#${ODIR}/${NAME}_first_cluster_step/clean_up_first_cluster/}
  python ${DB}/scripts/rname_tax_fix.py ${str1}.txt ${ODIR}/${NAME}_second_cluster_step/clean_first_cluster/${k}_first_cluster_taxonomy_${j}.txt ${k}
  sed -s  "s/>/>${k}/g" ${ODIR}/${NAME}_first_cluster_step/clean_up_first_cluster/${k}_first_cluster_unclean_${j}.fasta > ${ODIR}/${NAME}_second_cluster_step/clean_first_cluster/${k}_first_cluster_${j}.fasta
done
###
echo " "
echo " "
echo "Part 4.1:" 
echo "Run Qiime Pick OTUS and Assign Taxonomy on the merged ${NAME} references libraries with the following parameters:" 
echo "     Pick OTUs = ${FMETHOD_OTU} Clustering method at ${FUSEARCH_SIM}"
echo "               = Read sorting method is ${FUSEARCH61_SORT_METHOD}"
echo "               = Minimum number of reads per cluster is ${FMINSIZE}"
echo "     Assign Taxonomy = ${FMETHOD_AT} Clustering method at ${FUCLUST_SIMILARITY}"
echo "                     = Percent similarity within clusters is ${FUCLUST_SIMILARITY}"
echo "                     = Maximum number of references that can match to a cluster is ${FUCLUST_MIN_CONSENSUS_FRACTION}"
echo "                     = Minimum percent of taxonomic consensus needed for taxonomy assignment is ${FUCLUST_MIN_CONSENSUS_FRACTION}"
echo "If this is not what you want, then modify ${DB}/scripts/crux_vars.sh"
echo " "
###
for perc in ${SIM}
 do
 cat ${ODIR}/${NAME}_second_cluster_step/clean_first_cluster/*_first_cluster_${perc}.fasta > ${ODIR}/${NAME}_second_cluster_step/clean_first_cluster/merged_first_cluster_${perc}.fasta
 cat ${ODIR}/${NAME}_second_cluster_step/clean_first_cluster/*_first_cluster_taxonomy_${perc}.txt > ${ODIR}/${NAME}_second_cluster_step/clean_first_cluster/merged_first_cluster_taxonomy_${perc}.txt
 for str in ${ODIR}/${NAME}_second_cluster_step/clean_first_cluster/merged_first_cluster_taxonomy_${perc}.txt
  do
  echo "##################For reads at ${perc}##################"
  echo "...Run Pick OTUs"
  pick_otus.py -m ${FMETHOD_OTU} --usearch61_sort_method ${FUSEARCH61_SORT_METHOD} -i ${ODIR}/${NAME}_second_cluster_step/clean_first_cluster/merged_first_cluster_${perc}.fasta -o ${ODIR}/${NAME}_second_cluster_step/${NAME}_merged_pick_otus_${perc} -s ${FUSEARCH_SIM} --suppress_reference_chimera_detection --minsize ${FMINSIZE} --enable_rev_strand_match 
  echo "...Pick OTUs is finished"
  date
  ###
  echo ""
  echo "...Running Assign Taxonomy"
  assign_taxonomy.py -i ${ODIR}/${NAME}_second_cluster_step/${NAME}_merged_pick_otus_${perc}/dereplicated_seqs.fasta -o ${ODIR}/${NAME}_second_cluster_step/${NAME}_merged_assign_taxonomy_${perc} -r ${ODIR}/${NAME}_second_cluster_step/clean_first_cluster/merged_first_cluster_${perc}.fasta -t ${ODIR}/${NAME}_second_cluster_step/clean_first_cluster/merged_first_cluster_taxonomy_${perc}.txt  -m ${FMETHOD_AT} --uclust_min_consensus_fraction ${FUCLUST_MIN_CONSENSUS_FRACTION} --uclust_max_accepts ${FUCLUST_MAX_ACCEPT} --uclust_similarity ${FUCLUST_SIMILARITY} 
  echo "...Assign Taxonomy is finished"
  date
  echo ""
 done
done
###

##########################
# Part 5: Move the final files to the cleaned data
##########################
echo " "
echo " "
echo "Part 5:" 
echo "The final ${NAME} taxonomy and fasta database files can be found in the ${NAME}_final_database folder in ${ODIR}:" 
mkdir -p ${ODIR}/${NAME}_final_database
for perc in ${SIM}
 do
 python ${DB}/scripts/clean_blast.py ${ODIR}/${NAME}_second_cluster_step/${NAME}_merged_pick_otus_${perc}/dereplicated_seqs.fasta ${ODIR}/${NAME}_final_database/${NAME}_${perc}.fasta ${ODIR}/${NAME}_second_cluster_step/${NAME}_merged_assign_taxonomy_${perc}/dereplicated_seqs_tax_assignments.txt ${ODIR}/${NAME}_final_database/${NAME}_taxonomy_${perc}.txt
 python ${DB}/scripts/tax_fix.py ${ODIR}/${NAME}_final_database/${NAME}_taxonomy_${perc}.txt ${ODIR}/${NAME}_final_database/${NAME}_taxonomy_${perc}.txt.tmp
 cp ${ODIR}/${NAME}_final_database/${NAME}_taxonomy_${perc}.txt.tmp ${ODIR}/${NAME}_final_database/${NAME}_taxonomy_${perc}.txt
 rm ${ODIR}/${NAME}_final_database/${NAME}_taxonomy_${perc}.txt.tmp
 date
 echo " "
 echo " "
done
###


##########################
# Part 6: Turn the reference libraries into Bowtie2 searchable libraries
##########################

echo " "
echo " "
echo "Part 6:" 
echo "The bowtie2 database files for ${NAME} can be found in the ${NAME}_bowtie2_databases folder in ${ODIR}:" 
mkdir -p ${ODIR}/${NAME}_bowtie2_databases
for perc in ${SIM}
 do
 mkdir -p ${ODIR}/${NAME}_bowtie2_databases/${NAME}_bowtie2_${perc}
 bowtie2-build -f ${ODIR}/${NAME}_final_database/${NAME}_${perc}.fasta ${ODIR}/${NAME}_bowtie2_databases/${NAME}_bowtie2_${perc}/${NAME}_${perc}_bowtie2_index
 date
 echo " "
 echo " "
done


##########################
# Part 7: Delete the intermediate steps
##########################

echo " "
echo " "
echo "Part 7:" 
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
	rmdir ${ODIR}/${NAME}_first_cluster_step/
	echo "...${NAME} second cluster step directory"
	rmdir ${ODIR}/${NAME}_second_cluster_step
	echo "Deletion is finished"
 else
    echo "-c variable not recognized, nothing to delete"
fi
date
echo " "
echo " "
