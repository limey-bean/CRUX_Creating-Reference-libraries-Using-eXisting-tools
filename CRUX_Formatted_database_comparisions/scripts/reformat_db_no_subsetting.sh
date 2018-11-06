#!/bin/bash
# usage: sh /u/project/rwayne/eecurd/eecurd/five-fold-test/scripts/rand_sub_5-fold.sh -m /u/project/rwayne/eecurd/eecurd/five-fold-test -r 1 -d 12S  -f /u/project/rwayne/software/Anacapa/Anacapa_db/12S/12S_fasta_and_taxonomy
maindir=""
reps=""
db_name=""

while getopts "m:r:d:" opt; do
    case $opt in
        m) maindir="$OPTARG" # path to desired Anacapa output
        ;;
        r) reps="$OPTARG"  # path to Anacapa_db
        ;;
        d) db_name="$OPTARG"  # path to Anacapa_db
        ;;
    esac
done

# load modules
source /u/local/Modules/default/init/bash
module load ATS
module load qiime/1.8.0


mkdir -p ${maindir}/${db_name}_5-fold

# sh /Users/limeybean/Dropbox/taxxi/fasta_100s/rand_sub_5-fold.sh -m /Users/limeybean/Downloads/Erin_test_data/COI_ZBJ -f /Users/limeybean/Downloads/Erin_test_data/COI_ZBJ/COI_ZBJ_fasta_and_taxonomy -d COI_ZBJ -r 2

#For 5-fold sampling

START=1
END=${reps}
 
for ((rep=$START; rep<=$END; rep++ ))
do
	mkdir -p ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}
	mkdir -p ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp

	# pull out subsample taxonomy from original db taxonomy file, remove white space and : and replace with _ add gi to make compatible with other scripts
	# add gi to fasta to make compatible with other scripts
		
	#reformat the training taxonomy files to be compatible with the namecount script....   balls
	for i in {1..5};
	do 

		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy.txt | sed 's/ /_/g' | sed 's/:/_/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_.txt.tmp; mv ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_.txt.tmp ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy.txt
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy.txt | sed 's/^/gi_/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_gi.txt
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test.fasta | sed 's/>/>gi_/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_gi.fasta


		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test.fasta | sed 's/^>/>gi_/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_gi.fasta 
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy.txt | sed 's/^/gi_/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi.txt
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy.txt | sed 's/^/REF_GI_/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_REF_GI.txt
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train.fasta | sed 's/>/>gi_/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_gi.fasta
		python2 ${maindir}/scripts/format_CRUX_tax_for_taxxi.py ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi_taxxi.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi_taxxi.txt
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi_taxxi.txt | sed 's/ //g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi_taxxi.txt.tmp; mv ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi_taxxi.txt.tmp ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi_taxxi.txt 
		python2 ${maindir}/scripts/format_CRUX_tax_for_taxxi.py ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_gi.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_gi_taxxi.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_gi_taxxi.txt
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_gi_taxxi.txt | sed 's/ //g' | sed 's/gi/>REF_GI/g' | sed 's/$/;/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_gi_taxxi.txt.tmp; mv ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_gi_taxxi.txt.tmp ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_gi_taxxi.txt 
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_gi_taxxi.txt | sed 's/REF_//g' | sed 's/;$/;\natgc/g' | sed 's/;c:/,c:/g' | sed 's/;f:/,f:/g' | sed 's/;g:/,g:/g' | sed 's/;s:/,s:/g' | sed 's/;p:/,p:/g' | sed 's/;o:/,o:/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_gi_taxxi.fasta 



	done

	# move the subsample test and training sets to folders
	for i in {1..5};
	do 	
		mkdir -p ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/subset_${i}
		mv ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}*gi* ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/subset_${i}
		mv ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}*GI* ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/subset_${i}

	done
	
	# move non gi formated files to different folder
	mkdir -p ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/Non_gi_renamed_files
	mv ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/*.* ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/Non_gi_renamed_files
	
	rm -r ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp

done



