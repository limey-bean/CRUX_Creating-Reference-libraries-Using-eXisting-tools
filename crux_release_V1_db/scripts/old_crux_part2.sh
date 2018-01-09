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

#for each ecoPCR seed that ran through the first blast
##########################
# Part 3.1: Cleaning up blast results
##########################

################################ once all array jobs are finished run this script
echo " "
echo " "
echo "Part 2.1: Clean up BLAST 1 results and submit BLAST 2 array"
echo "For each set of BLAST results"
echo "     Merge and De-replicate by NCBI accession version numbers, and convert to fasta format."
echo "     Split files and resubmit BLAST array to get partial length reads (up to ${BLAST_HSP_PERC}% length)"

for dir in ${ODIR}/${NAME}_ecoPCR/cleaned/${NAME}_OB_dat_*/
do
 dir1=${dir%/}
 j=${dir1#${ODIR}/${NAME}_ecoPCR/cleaned/}
 #concatonate and sort for the longest single reads
 cat ${dir}blast_ready_*_blast1/blast1_out.fasta >> ${dir}blast1_all.fasta
 awk '/^>/ {printf("%s%s\t",(N>0?"\n":""),$0);N++;next;} {printf("%s",$0);} END {printf("\n");}' ${dir}blast1_all.fasta   | awk -F '\t' '{printf("%d\t%s\n",length($2),$0);}' | sort -k1,1rn | cut -f 2- | tr "\t" "\n" >> ${dir}blast1_all.fasta.tmp
 awk '/^>/{f=!d[$1];d[$1]=1}f' ${dir}blast1_all.fasta.tmp > ${dir}blast1_all.fasta
 rm ${dir}blast1_all.fasta.tmp
 # split the final dereplicated file into chunks and rename chunks so that they are in numerical order
 split -l 3000 ${dir}blast1_all.fasta ${dir}blast2_ready_
 i=1
 for nam in ${dir}blast2_ready_*
 do
	 nam1=${nam%_*}

	 # submit blast jobs for each file, and then remove reads with duplicate accession version numbers
     cp ${nam} ${nam1}_${i}
     rm ${nam}
	 ((i=i+1))
  done
 ### count number of files in the directory
 file_count=$( shopt -s nullglob ; set -- ${dir}blast2_ready_* ; echo $#)
 # submit blast jobs for each file, and then remove reads with duplicate accession version numbers
 array_var="\$SGE_TASK_ID"
 echo ${array_var}
 # submit an array job for each OB_dat blast output folder
 printf "#!/bin/bash\n#$ -l highp,h_rt=5:00:00,h_data=30G\n#$ -N blast2_${j}_${NAME}\n#$ -cwd\n#$ -m bea\n#$ -M ${UN} \n#$ -o ${ODIR}/blast_logs/${NAME}_blast2.out\n#$ -e ${ODIR}/blast_logs/${NAME}_blast2.err \n#$ -t 1-${file_count} \n\n\n sh ${DB}/scripts/sub_blast2.sh -n ${NAME} -q ${nam1}_${array_var} -o ${ODIR} -l blast2_ready_${array_var} -j ${j} -d ${DB} \n" >> ${ODIR}/blast_jobs/${j}_blast2.sh
 qsub ${ODIR}/blast_jobs/${j}_blast2.sh
 rm -r ${dir}blast_ready_*_blast1"
done
###

echo "  Once all array jobs have run, submit crux_par3.sh"
