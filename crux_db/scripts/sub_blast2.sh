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


while getopts "n:q:o:k:l:d:t:v:i:c:a:j:w:p:x:b:z:y:" opt; do
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
        x) COV2="$OPTARG"
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

${BLASTn_CMD} -query ${QU} -out ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/raw/${FILE}_blast2_out.txt -db ${BLAST_DB} -evalue ${EVAL2:=$BLAST2_eVALUE} -outfmt "6 saccver staxid sseq" -num_threads ${THREAD2:=$BLAST2_NUM_THREADS} -perc_identity  ${ID2:=$BLAST2_PERC_IDENTITY} -qcov_hsp_perc ${COV2:=$BLAST2_HSP_PERC} -num_alignments ${RETURN:=$BLAST2_NUM_ALIGNMENTS} -gapopen ${GO:=$GAP_OPEN} -gapextend ${GE:=$GAP_EXTEND}

# remove duplicate version accession numbers and convert to fasta file

cat ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/raw/${FILE}_blast2_out.txt | sed "s/-//g" | awk 'BEGIN { FS="\t"; } {print ">"$1"\n"$3}' >> ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/fasta/${FILE}_blast2_out.fasta

python ${DB}/scripts/combine_and_dereplicate_fasta.py -o ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/fasta/${FILE}_blast2_out.fasta -a ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/fasta/${FILE}_blast2_out.fasta

printf "${FILE}_blast_2.complete" > ${QU}_blast_2.complete
rm ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/raw/${FILE}_blast2_out.txt

if [ -e "${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/fasta/${FILE}_blast2_out.fasta.tmp" ];
then
  rm ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/fasta/${FILE}_blast2_out.fasta.tmp
else
  echo ""
fi
