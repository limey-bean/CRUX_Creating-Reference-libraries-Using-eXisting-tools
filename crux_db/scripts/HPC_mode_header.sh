# does not include the array varaible t (e.g. -t 1-${file_count}).  That is inculded in the job submit script writing step (lines 269 and 271)

BLAST1_HEADER="#!/bin/bash\n#$ -l highp,h_rt=05:00:00,h_data=48G\n#$ -N blast1_${NAME}\n#$ -cwd\n#$ -m bea\n#$ -M ${UN} \n#$ -o ${ODIR}/Run_info/blast_logs/blast1_${NAME}.out\n#$ -e ${ODIR}/Run_info/blast_logs/blast1_${NAME}.err"
BLAST2_HEADER="#!/bin/bash\n#$ -l highp,h_rt=05:00:00,h_data=48G\n#$ -N blast2_${NAME}\n#$ -cwd\n#$ -m bea\n#$ -M ${UN} \n#$ -o ${ODIR}/Run_info/blast_logs/blast2_${NAME}.out\n#$ -e ${ODIR}/Run_info/blast_logs/blast2_${NAME}.err"
