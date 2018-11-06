#!/bin/bash

source /u/local/Modules/default/init/bash
module load ATS

mkdir -p /u/project/rwayne/eecurd/eecurd/five-fold-test_anacapa_blca/Run
mkdir -p /u/project/rwayne/eecurd/eecurd/five-fold-test_anacapa_blca/Run/runlog
mkdir -p /u/project/rwayne/eecurd/eecurd/five-fold-test_anacapa_blca/Run/runscript

for str in `ls /u/project/rwayne/eecurd/eecurd/five-fold-test/CO1_5-fold/CO1_5-fold_1/subset_*/CO1_5-fold_1_sub*_test_gi.fasta`
do
 str1="${str%/CO1_5-fold_1_sub*_test_gi.fasta}"
 h=${str1#/u/project/rwayne/eecurd/eecurd/five-fold-test/CO1_5-fold/CO1_5-fold_1/subset_}
 str2="${str%/subset_*/CO1_5-fold_1_sub*_test_gi.fasta}"
 j=${str2#/u/project/rwayne/eecurd/eecurd/five-fold-test/CO1_5-fold/}
 echo ${j}
 echo ${h} "..."
 echo 
 printf " #!/bin/bash\n#$ -l highp,h_rt=15:00:00,h_data=48G\n#$ -N r${j}_sub${h}_anacapa_class_test\n#$ -cwd\n#$ -m bea\n#$ -M eecurd\n#$ \n#$ -o /u/project/rwayne/eecurd/eecurd/five-fold-test_anacapa_blca/Run/runlog/${j}_sub${h}run.out.txt\n#$ -e /u/project/rwayne/eecurd/eecurd/five-fold-test_anacapa_blca/Run/runlog/${j}_sub${h}run.err.txt\n\nsh /u/project/rwayne/eecurd/eecurd/five-fold-test_anacapa_blca/scripts/run_5-fold_db_tests_anacapa.sh -m /u/project/rwayne/eecurd/eecurd/five-fold-test_anacapa_blca/ -n ${j}_sub${h}  -s /u/project/rwayne/eecurd/eecurd/five-fold-test/CO1_5-fold/CO1_5-fold_1/subset_${h} " > /u/project/rwayne/eecurd/eecurd/five-fold-test_anacapa_blca/Run/runscript/${j}_sub${h}_blca.sh 
 qsub /u/project/rwayne/eecurd/eecurd/five-fold-test_anacapa_blca/Run/runscript/${j}_sub${h}_blca.sh 
done
