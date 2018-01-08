#! /bin/bash

### this script is run as follows
# sh ~/crux_release_V1_from_blast_out.sh -n <primer_name> -f <forward_primer> -r <reverse_primer> -l <shortest amplicon expected> -m <longest amplicon expected> -o <output_directory> -d <database_directory> -c <clean up intermediate files y/n> -h <user>
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


##########################
# Part 3: Cleaning up blast results
##########################

################################ once all array jobs are finished run this script




echo " "
echo " "
echo "Part 3.1: Cleaning up blast results"
echo "For each set of BLAST results"
echo "     Merge and De-replicate by NCBI accession version numbers, and convert to fasta format."
echo "     Then use entrez-qiime to generate a corresponding taxonomy file, and clean the blast output and taxonomy file to eliminate poorly annotated sequences."
mkdir -p ${ODIR}/${NAME}_db_filtered_to_remove_ambigous_taxonomy/${NAME}_fasta_and_taxonomy/
mkdir -p ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy

cat ${ODIR}/${NAME}/${NAME}_ecoPCR/cleaned/${NAME}_EMBL_*_std_*/blast1_all.fasta >> ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_blast.fasta

for str in ${ODIR}/${NAME}_BLAST/${NAME}_*_out
do
  echo "${str}"
  echo "${str}/fasta/*.fasta"
  cat ${str}/fasta/*.fasta >> ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_blast.fasta
  awk '/^>/ {printf("%s%s\t",(N>0?"\n":""),$0);N++;next;} {printf("%s",$0);} END {printf("\n");}' ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_blast.fasta  | awk -F '\t' '{printf("%d\t%s\n",length($2),$0);}' | sort -k1,1rn | cut -f 2- | tr "\t" "\n" > ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_blast.fasta.temp
  awk '/^>/{f=!d[$1];d[$1]=1}f' ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_blast.fasta.temp > ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_blast.fasta
  rm ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_blast.fasta.temp
done

cp ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_blast.fasta ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_.fasta
rm ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_blast.fasta


### merge and clean blast data
echo "...Running ${j} entrez-qiime and cleaning up fasta and taxonomy files"
python ${ENTREZ_QIIME} -i ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_.fasta -o ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy -n ${TAXO} -a ${A2T} -r superkingdom,phylum,class,order,family,genus,species
python ${DB}/scripts/clean_blast.py ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_.fasta ${ODIR}/${NAME}_db_filtered_to_remove_ambigous_taxonomy/${NAME}_fasta_and_taxonomy/${NAME}_.fasta ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt ${ODIR}/${NAME}_db_filtered_to_remove_ambigous_taxonomy/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt
python ${DB}/scripts/tax_fix.py ${ODIR}/${NAME}_db_filtered_to_remove_ambigous_taxonomy/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt ${ODIR}/${NAME}_db_filtered_to_remove_ambigous_taxonomy/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt.tmp
grep '[^[:blank:]]'  ${ODIR}/${NAME}_db_filtered_to_remove_ambigous_taxonomy/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt.tmp > ${ODIR}/${NAME}_db_filtered_to_remove_ambigous_taxonomy/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt
rm ${ODIR}/${NAME}_db_filtered_to_remove_ambigous_taxonomy/${NAME}_fasta_and_taxonomy/${NAME}_taxonomy.txt.tmp
echo "... ${j} final fasta and taxonomy database complete"


##########################
# Part 4: Turn the reference libraries into Bowtie2 searchable libraries
##########################

echo " "
echo " "
echo "Part 5:"
echo "The bowtie2 database files for ${NAME} can be found in the ${NAME}_bowtie2_databases within the ${NAME}_db_unfiltered and ${NAME}_db_filtered_to_remove_ambigous_taxonomy folder's in ${ODIR}:"
mkdir -p ${ODIR}/${NAME}_db_unfiltered/${NAME}_bowtie2_database
bowtie2-build -f ${ODIR}/${NAME}_db_unfiltered/${NAME}_fasta_and_taxonomy/${NAME}_.fasta ${ODIR}/${NAME}_db_unfiltered/${NAME}_bowtie2_database/${NAME}_bowtie2_index
date
echo " "
echo " "
mkdir -p ${ODIR}/${NAME}_db_filtered_to_remove_ambigous_taxonomy/${NAME}_bowtie2_database/
bowtie2-build -f ${ODIR}/${NAME}_db_filtered_to_remove_ambigous_taxonomy/${NAME}_fasta_and_taxonomy/${NAME}_.fasta ${ODIR}/${NAME}_db_filtered_to_remove_ambigous_taxonomy/${NAME}_bowtie2_database/${NAME}_bowtie2_index
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
