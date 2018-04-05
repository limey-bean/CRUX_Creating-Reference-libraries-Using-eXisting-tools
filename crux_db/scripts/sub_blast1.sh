#! /bin/bash

### this script is run as follows
# sh ~/sub_blast.sh -n ${NAME} -q ${st} -o ${ODIR} -k ${j} -l ${l} -d ${DB} -t <The number of threads to launch for the first round of BLAST>  -v <The minimum accepted value for BLAST hits in the first round of BLAST >  -i <The minimum percent ID for BLAST hits in the first round of BLAST>  -c <Minimum percent of length of a query that a BLAST hit must cover >  -a <Maximum number of
# BLAST hits to return for each query>  -j <The number of threads to launch for the first round of BLAST>  -w <The minimum accepted value for BLAST hits in the first round of BLAST>  -p  <The minimum percent ID for BLAST hits in the first round of BLAST >  -f <Minimum percent of length of a query that a BLAST hit must cover> -y <penalty for gap open> -z <penalty for gap extend>
NAME=""
QU=""
ODIR=""
TYPE=""
FILE=""
DB=""
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


while getopts "n:q:o:k:l:d:t:v:i:c:a:j:w:p:f:b:z:y:" opt; do
    case $opt in
    	n) NAME="$OPTARG"
    	;;
        q) QU="$OPTARG"
        ;;
        o) ODIR="$OPTARG"
        ;;
        k) TYPE="$OPTARG"
        ;;
        l) FILE="$OPTARG"
        ;;
        d) DB="$OPTARG"
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
        j) THREAD2="$OPTARG"
        ;;
        w) EVAL2="$OPTARG"
        ;;
        p) ID2="$OPTARG"
        ;;
        f) COV2="$OPTARG"
        ;;
        y) GO="$OPTARG"
        ;;
        z) GE="$OPTARG"
        ;;
    esac
done

source ${DB}/scripts/crux_vars.sh
source ${DB}/scripts/crux_config.sh

#submit blast job for a given fasta file
${BLASTn_CMD} -query ${QU} -out ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/raw/${FILE}_blast1_out.txt -db ${BLAST_DB} -evalue ${EVAL1} -outfmt "6 saccver staxid sseq" -num_threads ${THREAD1} -perc_identity ${ID1} -qcov_hsp_perc ${COV1} -num_alignments ${RETURN} -gapopen ${GO} -gapextend ${GE}

# remove duplicate version accession numbers and convert to fasta file

cat ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/raw/${FILE}_blast1_out.txt | sed "s/-//g" | awk 'BEGIN { FS="\t"; } {print ">"$1"\n"$3}' >> ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/fasta/${FILE}_blast1_out.fasta

python ${DB}/scripts/combine_and_dereplicate_fasta.py -o ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/fasta/${FILE}_blast1_out.fasta -a ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/fasta/${FILE}_blast1_out.fasta

printf "${FILE}_blast_1.complete" > ${QU}_blast_1.complete
rm ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/raw/${FILE}_blast1_out.txt
rm ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/fasta/${FILE}_blast1_out.fasta.tmp
