#! /bin/bash

### this script is run as follows
# sh ~/Crux-v2.sh -n <primer_name> -f <forward_primer> -r <reverse_primer> -o <output_directory> -d <database_directory>
NAME=""
FP=""
RP=""
ODIR=""
DB=""

while getopts "n:f:r:o:d:" opt; do
    case $opt in
        n) NAME="$OPTARG"
        ;;
        f) FP="$OPTARG"
        ;;
        r) RP="$OPTARG"
        ;;
        o) ODIR="$OPTARG"
        ;;
        d) DB="$OPTARG"
        ;;
    esac
done


{

###########################################
                                                                                                                                                
# Emily Curd (eecurd@g.ucla.edu), Gaurav Kandlikar (gkandlikar@ucla.edu), and Jesse Gomer (jessegomer@gmail.com)
# Updated 07 September 2017

# this is a draft of a pipeline that takes any pair of primer sequences and generages a comprehensive reference database that could be amplified with those primers, using as much data from published sequences as posible. 

# THE GOAL: is to capture not only the sequences that were submitted with primers included in the read (ecoPCR gets these), but also those that do not include primer regions but are some % of the length of the expected amplion (BLAST fills in these holes), and generate reference libraries and taxonomy files compatible with qiime or kraken taxonomy pipelines.

# Source the config and vars file so that we have programs and variables available to us
source $DB/crux_vars.sh
source $DB/crux_config.sh

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
echo "     minimum length = ${ECOPCR_l}"
echo "     maximum length = ${ECOPCR_L}"
echo "If this is not what you want, then modify ${DB}/crux_vars.sh"
mkdir -p ${ODIR}
mkdir -p ${ODIR}/${NAME}_ecoPCR
###
for db in ${OBI_DB}/*/
do
 db1=${db%/}
 j=${db1#${OBI_DB}/}
 echo "..."${j}" ecoPCR is running"
 ${ecoPCR} -d ${db}${j} -e ${ECOPCR_e} -l ${ECOPCR_l} -L ${ECOPCR_L} ${FP} ${RP} > ${ODIR}/${NAME}_ecoPCR/${NAME}_${j}_ecoPCR_out
 echo "..."${j}" ecoPCR is finished"
date
done
###
echo " "
echo " "
echo "Part 1.2:"
echo "Clean ${NAME} ecoPCR output for blasting"
for str in ${ODIR}/${NAME}_ecoPCR/*_ecoPCR_out
do
 str1=${str%_ecoPCR_out}
 j=${str1#${ODIR}/${NAME}_ecoPCR/}
 tail -n +14 ${str} |cut -d "|" -f 3,21|sed "s/ | /,/g"|awk -F"," '!_[$1]++' | sed "s/\s//g" |awk 'BEGIN { FS=","; } {print ">"$1"\n"$2}' > ${str}_ecoPCR_blast_input.fasta
 echo "..."${j}" is clean"
date
done
###


##########################
# Part 2: blasting
##########################
echo " "
echo " "
echo "Part 2.1:" 
echo "Run blast with ${NAME} ecoPCR results and these parameters:" 
echo "     BLAST e-value = ${BLAST_eVALUE}"
echo "     number of threads = ${BLAST_NUM_THREADS}"
echo "     minimum percent identity for a genbank read that aligns to an ecoPCR generated sequences = ${BLAST_PERC_IDENTITY}"
echo "     minimum percent of coverage length for a genbank read that aligns to an ecoPCR generated sequence= ${BLAST_HSP_PERC}"
echo "     number of alignments to include in the output = ${BLAST_NUM_ALIGNMENTS}"
echo "If this is not what you want, then modify ${DB}/crux_vars.sh"
mkdir -p ${ODIR}/${NAME}_BLAST
${MODULE_SOURCE}
${LOAD_BLAST}
for str in ${ODIR}/${NAME}_ecoPCR/*_ecoPCR_blast_input.fasta
do
 str1=${str%_ecoPCR_blast_input.fasta}
 j=${str1#${ODIR}/${NAME}_ecoPCR/}
 echo "..."${j}" is running"
 ${BLASTn_CMD} -query ${str} -out ${ODIR}/${NAME}_BLAST/${NAME}_${j}_BLAST_out.txt -db ${BLAST_DB} -evalue ${BLAST_eVALUE} -outfmt "6 saccver staxid sseq" -num_threads ${BLAST_NUM_THREADS} -perc_identity ${BLAST_PERC_IDENTITY} -qcov_hsp_perc ${BLAST_HSP_PERC} -num_alignments ${BLAST_NUM_ALIGNMENTS} 
 echo "..."${j}" is finished"
date
done
###
echo " "
echo " "
echo "Part 2.2:" 
echo "Merge BLAST results, de-replicate by NCBI accession version numbers, and convert to fasta format." 
cat ${ODIR}/${NAME}_BLAST/${NAME}_*_BLAST_out.txt  > ${ODIR}/${NAME}_BLAST/${NAME}_merged_BLAST_out.txt
cat ${ODIR}/${NAME}_BLAST/${NAME}_merged_BLAST_out.txt  | sed "s/-//g"| awk -F"\t" '!_[$1]++' |awk 'BEGIN { FS="\t"; } {print ">"$1"\n"$3}' > ${ODIR}/${NAME}_BLAST/${NAME}_dirty_dereplicated_BLAST.fasta
echo "...uncleaned BLAST results are formated"
date
###
echo " "
echo " "
echo "Part 2.3:" 
echo "Run entrez-qiime to generate a taxonomy file corresponding to the NCBI accession version numbers for BLAST reads." 
${MODULE_SOURCE}
${LOAD_QIIME}
python ${ENTREZ_QIIME} -i ${ODIR}/${NAME}_BLAST/${NAME}_dirty_dereplicated_BLAST.fasta -o ${ODIR}/${NAME}_BLAST/${NAME}_dirty_dereplicated_BLAST_taxonomy -n ${TAXO} -a ${A2T} 
sed ’s/|/;/g’ ${ODIR}/${NAME}_BLAST/${NAME}_dirty_dereplicated_BLAST_taxonomy.txt
echo "...uncleaned Taxonomy file is complete"
date
#####
echo " "
echo " "
echo "Part 2.4:"
echo "Clean the output of BLAST"
python ${DB}/clean_blast.py ${ODIR}/${NAME}_BLAST/${NAME}_dirty_dereplicated_BLAST.fasta ${ODIR}/${NAME}_BLAST/${NAME}_dereplicated_BLAST.fasta ${ODIR}/${NAME}_BLAST/${NAME}_dirty_dereplicated_BLAST_taxonomy.txt ${ODIR}/${NAME}_BLAST/${NAME}_dereplicated_BLAST_taxonomy.txt
echo "...BLAST results and Taxonomy file are clean"
date


##########################
# Part 3: Clustering
##########################
echo " "
echo " "
echo "Part 3.1:" 
echo "Run Qiime Pick OTUs to cluster ${NAME} BLAST results with the following parameters:" 
echo "     Clustering method = ${METHOD_OTU}"
echo "     Read sorting method = ${USEARCH61_SORT_METHOD}"
echo "     Percent similarity within clusters  = ${USEARCH_SIM}"
echo "     Minimum number of reads per cluster= ${MINSIZE}"
echo "If this is not what you want, then modify ${DB}/crux_vars.sh"
echo "...running Pick OTUs"
pick_otus.py -m ${METHOD_OTU} --usearch61_sort_method ${USEARCH61_SORT_METHOD} -i ${ODIR}/${NAME}_BLAST/${NAME}_dereplicated_BLAST.fasta -o ${ODIR}/${NAME}_dereplicated_BLAST_${METHOD_OTU}_${USEARCH_SIM} -s ${USEARCH_SIM} --suppress_reference_chimera_detection --minsize ${MINSIZE} --enable_rev_strand_match 
echo "...Pick OTUs is finished"
date
###
echo " "
echo " "
echo "Part 3.2:" 
echo "Run Qiime Assign Taxonomy on the ${USEARCH_SIM} clustered ${NAME} BLAST results with the following parameters:" 
echo "     Clustering method = ${METHOD_AT}"
echo "     Percent similarity within clusters  = ${UCLUST_SIMILARITY}"
echo "     Maximum number of references that can match to a cluster = ${UCLUST_MIN_CONSENSUS_FRACTION}"
echo "     Minimum percent of taxonomic consensus needed for taxonomy assignment= ${UCLUST_MIN_CONSENSUS_FRACTION}"
echo "If this is not what you want, then modify ${DB}/crux_vars.sh"
echo " "
echo "...running Assign Taxonomy"
assign_taxonomy.py -i ${ODIR}/${NAME}_dereplicated_BLAST_${METHOD_OTU}_${USEARCH_SIM}/enumerated_otus.fasta -o ${ODIR}/${NAME}_dereplicated_BLAST_assign_taxonomy_${METHOD_AT}_${UCLUST_SIMILARITY} -r ${ODIR}/${NAME}_BLAST/${NAME}_dereplicated_BLAST.fasta -t ${ODIR}/${NAME}_BLAST/${NAME}_dereplicated_BLAST_taxonomy.txt  -m ${METHOD_AT} --uclust_min_consensus_fraction ${UCLUST_MIN_CONSENSUS_FRACTION} --uclust_max_accepts ${UCLUST_MAX_ACCEPT} --uclust_similarity ${UCLUST_SIMILARITY} 
echo "...Assign Taxonomy is finished"
date
###

##########################
# Part 4: Move the final files to the cleaned data
##########################
echo " "
echo " "
echo "Part 4.1:" 
echo "The final database files can be found in the ${NAME}_database folder in ${ODIR}:" 
mkdir -p ${ODIR}/${NAME}_database
cp ${ODIR}/${NAME}_dereplicated_BLAST_${METHOD_OTU}_${USEARCH_SIM}/enumerated_otus.fasta ${ODIR}/${NAME}_database/${NAME}_crux.fasta
cp ${ODIR}/${NAME}_dereplicated_BLAST_assign_taxonomy_${METHOD_AT}_${UCLUST_SIMILARITY}/enumerated_otus_tax_assignments.txt ${ODIR}/${NAME}_database/${NAME}${UCLUST_SIMILARITY}_crux_taxonomy.txt

} | tee -a ${ODIR}/CRUX_${NAME}_log_file.txt
