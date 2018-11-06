#!/bin/bash

maindir=""
reps=""
db_name=""
db_folder=""

while getopts "m:r:d:f:" opt; do
    case $opt in
        m) maindir="$OPTARG" # path to desired Anacapa output
        ;;
        r) reps="$OPTARG"  # path to Anacapa_db
        ;;
        d) db_name="$OPTARG"  # path to Anacapa_db
        ;;
        f) db_folder="$OPTARG"  # path to Anacapa_db
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
	#first subsample
	subsample_fasta.py -i ${db_folder}/*_.fasta -p 0.2 -o ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_test.fasta
	#make list of reads to remove from main file
	grep -e ">" ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_test.fasta | awk 'sub(/^>/, "")'  >  ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_sub1_rm_list.txt
	#filer test data from full dataset for next random sub sampling
	filter_fasta.py -f ${db_folder}/*_.fasta -o ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_rd_minus_sub1_test.fasta -s ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_sub1_rm_list.txt -n

	#second subsample
	subsample_fasta.py -i ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_rd_minus_sub1_test.fasta -p 0.25 -o ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub2_test.fasta
	#make list of those to remove from main file
	grep -e ">" ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub2_test.fasta | awk 'sub(/^>/, "")'  >  ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_sub2_rm_list.txt
	#filer test data from remaining dataset for next random sub sampling
	filter_fasta.py -f ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_rd_minus_sub1_test.fasta -o ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_rd_minus_sub1-2.fasta -s ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_sub2_rm_list.txt -n

	#third subsample
	subsample_fasta.py -i ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_rd_minus_sub1-2.fasta -p 0.33333333 -o ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub3_test.fasta
	#make list of those to remove from main file
	grep -e ">" ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub3_test.fasta | awk 'sub(/^>/, "")'  >  ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_sub3_rm_list.txt
	#filer test data from remaining dataset for next random sub sampling
	filter_fasta.py -f ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_rd_minus_sub1-2.fasta -o ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_rd_minus_sub1-2-3.fasta -s ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_sub3_rm_list.txt -n

	#final subsample
	subsample_fasta.py -i ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_rd_minus_sub1-2-3.fasta -p 0.5 -o ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub4_test.fasta
	#make list of those to remove from main file
	grep -e ">" ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub4_test.fasta | awk 'sub(/^>/, "")'  >  ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_sub4_rm_list.txt
	#filer test data from remaining dataset left over = fifth subsample
	filter_fasta.py -f ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_rd_minus_sub1-2-3.fasta -o ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub5_test.fasta -s ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_sub4_rm_list.txt -n
	#make list of remaining read names
	grep -e ">" ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub5_test.fasta | awk 'sub(/^>/, "")'  >  ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_sub5_rm_list.txt

	# pull out subsample taxonomy from original db taxonomy file, remove white space and : and replace with _ add gi to make compatible with other scripts
	# add gi to fasta to make compatible with other scripts
	for i in {1..5};
	do 
		grep -Ff ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/temp/${db_name}_5-fold_${rep}_sub${i}_rm_list.txt ${db_folder}/*_taxonomy.txt > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy.txt
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy.txt | sed 's/ /_/g' | sed 's/:/_/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_.txt.tmp; mv ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_.txt.tmp ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy.txt
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy.txt | sed 's/^/gi_/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_taxonomy_gi.txt
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test.fasta | sed 's/^/gi_/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_test_gi.fasta
	done
	
	#make training set fasta files by concatenating all but the current test subsample e.g. for subsample 1 concatenate subsamples 2-5
	cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub2_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub3_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub4_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub5_test.fasta > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_train.fasta
	cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub3_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub4_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub5_test.fasta > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub2_train.fasta
	cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub2_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub4_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub5_test.fasta > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub3_train.fasta
	cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub2_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub3_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub5_test.fasta > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub4_train.fasta
	cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub2_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub3_test.fasta ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub4_test.fasta > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub5_train.fasta

	#make training set taxonomy files by concatenating all but the current test subsample e.g. for subsample 1 concatenate subsamples 2-5
	cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub2_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub3_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub4_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub5_test_taxonomy.txt > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_train_taxonomy.txt
	cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub3_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub4_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub5_test_taxonomy.txt > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub2_train_taxonomy.txt
	cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub2_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub4_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub5_test_taxonomy.txt > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub3_train_taxonomy.txt
	cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub2_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub3_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub5_test_taxonomy.txt > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub4_train_taxonomy.txt
	cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub2_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub3_test_taxonomy.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub4_test_taxonomy.txt > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub5_train_taxonomy.txt

	#reformat the training taxonomy files to be compatible with the namecount script....   balls
	for i in {1..5};
	do 
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy.txt | sed 's/^/gi_/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi.txt
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy.txt | sed 's/^/REF_GI_/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_REF_GI.txt
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_train.fasta | sed 's/^/gi_/g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub1_train_gi.fasta
		python2 ${maindir}/scripts/format_CRUX_tax_for_taxxi.py ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi_taxxi.txt ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi_taxxi.txt
		cat ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi_taxxi.txt | sed 's/ //g' > ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi_taxxi.txt.tmp; mv ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi_taxxi.txt.tmp ${maindir}/${db_name}_5-fold/${db_name}_5-fold_${rep}/${db_name}_5-fold_${rep}_sub${i}_train_taxonomy_gi_taxxi.txt 
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



