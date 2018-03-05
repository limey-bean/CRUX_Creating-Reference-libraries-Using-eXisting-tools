# function templates used to generate the job files that get submitted using qsub
# if your environment needs different arguments for your job scheduling system you can change these
# example usage:
# source crux_qsub_templates.sh
# printf "$(CRUX_PART1_BLAST1_TEMPLATE)" > some_file

CRUX_PART1_BLAST1_TEMPLATE() {
read -d '' String <<"EOF"
#!/bin/bash
#$ -l highp,h_rt=05:00:00,h_data=30G
#$ -N blast1_${j}_${NAME}
#$ -cwd
#$ -m bea
#$ -M ${UN} 
#$ -o ${ODIR}/blast_logs/blast1_${j}_${NAME}.out
#$ -e ${ODIR}/blast_logs/blast1_${j}_${NAME}.err
#$ -t 1-${file_count}

sh ${DB}/scripts/sub_blast1.sh -n ${NAME} -q ${nam1}_${array_var} -o ${ODIR} -j ${j} -l blast_ready_${array_var} -d ${DB} 
EOF
echo "${String}" 
}

CRUX_PART1_BLAST2_TEMPLATE() {
read -d '' String <<"EOF"
#!/bin/bash
#$ -l highp,h_rt=05:00:00,h_data=30G
#$ -N blast2_${j}_${NAME}
#$ -cwd
#$ -m bea
#$ -M ${UN} 
#$ -o ${ODIR}/blast_logs/blast2_${j}_${NAME}
#$ -e ${ODIR}/blast_logs/blast2_${j}_${NAME}.err
#$ -t 1-${file_count}


sh ${DB}/scripts/sub_blast2.sh -n ${NAME} -q ${nam1}_${array_var} -o ${ODIR} -j ${j} -l blast_ready_${array_var} -d ${DB} 
EOF
echo "${String}"
}



DADA2_PAIRED_TEMPLATE() {
  echo "#!/bin/bash\n#$ -q std.q\n#$ -cwd\n#$ -l mem_free=48G\n#$ -pe smp 1\n#$ -N paired_${j}_dada2\n#$ -o ${OUT}/Run_info/hoffman2/run_logs/${j}_paired_$JOB_ID.out\n#$ -e ${OUT}/Run_info/hoffman2/run_logs/${j}_paired_$JOB_ID.err\n\necho _BEGIN_ [run_dada2_bowtie2_paired.sh]: `date`\n\n${RUNNER} ${DB}/scripts/run_dada2.sh  -o ${OUT} -d ${DB} -m ${j} -t paired\n\necho _END_ [run_dada2_paired.sh]"
}
