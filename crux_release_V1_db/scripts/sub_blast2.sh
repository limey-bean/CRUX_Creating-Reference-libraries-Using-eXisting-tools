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

${BLASTn_CMD} -query ${QU} -out ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/raw/${FILE}_blast2_out.txt -db ${BLAST_DB} -evalue ${BLAST2_eVALUE} -outfmt "6 saccver staxid sseq" -num_threads ${BLAST2_NUM_THREADS} -perc_identity ${BLAST2_PERC_IDENTITY} -qcov_hsp_perc ${BLAST2_HSP_PERC} -num_alignments ${BLAST2_NUM_ALIGNMENTS} -gapopen 1 -gapextend 1

# remove duplicate version accession numbers and convert to fasta file

cat ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/raw/${FILE}_blast2_out.txt | sed "s/-//g" | awk 'BEGIN { FS="\t"; } {print ">"$1"\n"$3}' >> ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/fasta/${FILE}_blast2_out.fasta

${DB}/scripts/combine_and_dereplicate_fasta.py -o ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/fasta/${FILE}_blast2_out.fasta -a ${ODIR}/${NAME}_BLAST/${TYPE}_BLAST_out/fasta/${FILE}_blast2_out.fasta
