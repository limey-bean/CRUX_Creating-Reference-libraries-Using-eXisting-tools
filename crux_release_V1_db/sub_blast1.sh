#! /bin/bash

### this script is run as follows
# sh ~/sub_blast.sh -n ${NAME} -q ${st} -o ${ODIR} -j ${j} -l ${l} -d ${DB}
NAME=""
QU=""
ODIR=""
TYPE=""
FILE=""
DB=""
while getopts "n:q:o:j:l:d:" opt; do
    case $opt in
    	n) NAME="$OPTARG"
    	;;
        q) QU="$OPTARG"
        ;;
        o) ODIR="$OPTARG"
        ;;
        j) TYPE="$OPTARG"
        ;;
        l) FILE="$OPTARG"
        ;;
        d) DB="$OPTARG"
        ;;
    esac
done

source ${DB}/scripts/crux_vars.sh
source ${DB}/scripts/crux_config.sh

#submit blast job for a given fasta file
mkdir -p ${QU}_blast1

${BLASTn_CMD} -query ${QU} -out ${QU}_blast1/blast1_out.txt -db ${BLAST_DB} -evalue 0.00001 -outfmt "6 saccver staxid sseq" -num_threads ${BLAST_NUM_THREADS} -perc_identity 50 -qcov_hsp_perc 100 -num_alignments 5000 -gapopen 1 -gapextend 1

# remove duplicate version accession numbers and convert to fasta file

cat ${QU}_blast1/blast1_out.txt | sed "s/-//g" | awk 'BEGIN { FS="\t"; } {print ">"$1"\n"$3}' >> ${QU}_blast1/blast1_out.fasta

awk '/^>/ {printf("%s%s\t",(N>0?"\n":""),$0);N++;next;} {printf("%s",$0);} END {printf("\n");}' ${QU}_blast1/blast1_out.fasta  | awk -F '\t' '{printf("%d\t%s\n",length($2),$0);}' | sort -k1,1rn | cut -f 2- | tr "\t" "\n" >> ${QU}_blast1/blast1_out.fasta.temp

awk '/^>/{f=!d[$1];d[$1]=1}f' ${QU}_blast1/blast1_out.fasta.temp > ${QU}_blast1/blast1_out.fasta

rm ${QU}_blast1/blast1_out.txt

rm ${QU}_blast1/blast1_out.fasta.temp


