#!/bin/bash
#  bash /CRUX_database_comparison_TAXXI_metrics.sh  -m ~/CRUX_database_comparison_TAXXI_metrics -n MitoFish_vs_12S -a ~/MitoFish_.fasta -b ~/MitoFish_taxonomy.txt -c ~/12S_.fasta -d ~/12S_taxonomy.txt
maindir=""
name=""  #e.g. 12S_vs_MitoFish
query_fasta=""
query_taxonomy=""
subject_fasta=""
subject_taxonomy=""
B_VALUE=""
PER_MIN_LEN=""
Best_hit=""
PARAMS=""

while getopts "m:n:s:a:b:c:d:b:l:k:p:h?" opt; do
    case $opt in
        m) maindir="$OPTARG" # path to desired Anacapa output
        ;;
        n) name="$OPTARG"  # path to Anacapa_db
        ;;
        a) query_fasta="$OPTARG"  # path to query database fasta
        ;;
        b) query_taxonomy="$OPTARG"  # path to query database taxonomy
        ;;
        c) subject_fasta="$OPTARG"  # path to subject database fasta
        ;;
        d) subject_taxonomy="$OPTARG"  # path to subject database taxonomy
        ;;
        b) B_VALUE="$OPTARG" # percent match between query and subject
        ;;
        l) PER_MIN_LEN="$OPTARG" # minimum lengt of match between query and subject
        ;;
        k) Best_hit="$OPTARG" # maximum number of bowtie2 best hits include in BLCA
        ;;
        p) PARAMS="$OPTARG" # parameter file
        ;;
        h) HELP="TRUE"  # calls help screen
        ;;
    esac
done

if [ "${HELP}" = "TRUE" ]
then
  printf "\n\n\n\n<<< Anacapa: CRUX_database_comparison_TAXXI_metrics.sh help screen >>>\n\nThe purpose of this script to test the taxonomic classification ability of two crux formatted databases.  For example, this script can be used to test how well the Mitofish-R database (subject) does in classifying the CRUX-12S (query) reference database using the Anacapa_calassifier.  The success of taxonomic calls is determined using the framework of Edgar 2018.\n\nArguments:\n- Required:\n  -m	path to directory containing scripts and where output will go\n  -n 	database comparison testname e.g. \n  -a	path to the CRUX formated query fasta file\n  -b	path to the CRUX formated query taxonomy file\n  -c	path to the CRUX formated subject fasta file\n  -d 	path to the CRUX formated subject taxonomy file\n    \n- Optional:\n	-b	percent match between query and subject (default = .90)\n	-l	minimum lengt of match between query and subject (default = 0.85)\n	-k	maximum number of bowtie2 best hits include in BLCA (default = 50)\n		\n- Other:\n  -h	Shows program usage then quits\n\n\n"
  exit
else
  echo ""
fi


# load module
source ${maindir}scripts/CRUX_database_comparison_TAXXI_metrics_config.sh
${MODULE_SOURCE}
${ATS}
${QIIME}
${BOWTIE2}
${ANACONDA}

#change directory into the scripts folder so hoffman can find python modules
cd ${maindir}scripts

#	get prefix and make it name
#	get query name
#	get training name

#####################  make directories
mkdir -p ${maindir}query_subject/
traindir=${maindir}query_subject/${name}
mkdir -p $traindir

mkdir -p ${maindir}namecounts
namecountsdir=${maindir}namecounts/${name}
mkdir -p $namecountsdir

mkdir -p ${maindir}bowtie2_libs/
bowtie2dir=${maindir}bowtie2_libs/${name}
mkdir -p $bowtie2dir

mkdir -p ${maindir}raw_output/
rawdir=${maindir}raw_output/${name}
mkdir -p $rawdir
raw=$rawdir

mkdir -p ${maindir}pred/
preddir=${maindir}pred/${name}
mkdir -p $preddir
pred=$preddir/${name}

mkdir -p ${maindir}stats/
statsdir=${maindir}stats/${name}
mkdir -p $statsdir

################## format files
# remove white space and : and replace with _ add gi to make compatible with other scripts
#reformat taxonomy files to be compatible with the namecount script....   balls
# query
cat ${query_taxonomy} | sed 's/ /_/g' | sed 's/:/_/g' > ${traindir}/${name}_query_taxonomy.txt
cat ${traindir}/${name}_query_taxonomy.txt | sed 's/^/gi_Q/g' > ${traindir}/${name}_query_taxonomy_gi.txt
python2 ${maindir}/scripts/format_CRUX_tax_for_taxxi.py ${traindir}/${name}_query_taxonomy_gi.txt ${traindir}/${name}_query_taxonomy_gi_taxxi.txt
cat ${traindir}/${name}_query_taxonomy_gi_taxxi.txt | sed 's/ //g' > ${traindir}/${name}_query_taxonomy_gi_taxxi.txt.tmp; mv ${traindir}/${name}_query_taxonomy_gi_taxxi.txt.tmp ${traindir}/${name}_query_taxonomy_gi_taxxi.txt
cat ${traindir}/${name}_query_taxonomy_gi_taxxi.txt | sed 's/gi_Q/>REF_gi_Q/g' | sed 's/$/\natgc/g' | sed 's/;c:/,c:/g' | sed 's/;f:/,f:/g' | sed 's/;g:/,g:/g' | sed 's/;s:/,s:/g' | sed 's/;p:/,p:/g' | sed 's/;o:/,o:/g' > ${traindir}/${name}_query_taxonomy_gi_taxxi.fasta

#subject
cat ${subject_taxonomy} | sed 's/ /_/g' | sed 's/:/_/g' > ${traindir}/${name}_subject_taxonomy.txt
cat ${traindir}/${name}_subject_taxonomy.txt | sed 's/^/gi_/g' > ${traindir}/${name}_subject_taxonomy_gi.txt
cat ${traindir}/${name}_subject_taxonomy.txt | sed 's/^/REF_GI_/g' > ${traindir}/${name}_subject_taxonomy_REF_GI.txt
python2 ${maindir}/scripts/format_CRUX_tax_for_taxxi.py ${traindir}/${name}_subject_taxonomy_gi.txt ${traindir}/${name}_subject_taxonomy_gi_taxxi.txt
#this file is ugly and historical...
cat ${traindir}/${name}_subject_taxonomy_gi_taxxi.txt | sed 's/ //g' > ${traindir}/${name}_subject_taxonomy_gi_taxxi.txt.tmp; mv ${traindir}/${name}_subject_taxonomy_gi_taxxi.txt.tmp ${traindir}/${name}_subject_taxonomy_gi_taxxi.txt

# add gi to fasta to make compatible with other scripts
#query
cat ${query_fasta} | sed 's/>/>gi_Q/g' > ${traindir}/${name}_query_gi.fasta

#subject
cat ${subject_fasta} | sed 's/>/>gi_/g' > ${traindir}/${name}_subject_gi.fasta



################## make name count files.  These are critical for the stats!!!!
# get the frequency of occurrences of a taxonomic rank make a file
python2 run_namecount.py ${traindir}/${name}_subject_taxonomy_gi_taxxi.txt ${namecountsdir} ${name}
# clean up the file by removing the damn space and also any lines without : and then remove temp files
cat ${namecountsdir}/${name}_namecount | sed 's/ //g' > ${namecountsdir}/${name}_namecount.txt
grep ':' ${namecountsdir}/${name}_namecount.txt > ${namecountsdir}/${name}_namecount; mv ${namecountsdir}/${name}_namecount ${namecountsdir}/${name}_namecount.txt


################### run anacapa BLCA
# prepare for anacapa BLCA by making a bowtie2 database
bowtie2-build -f ${traindir}/${name}_subject_gi.fasta ${bowtie2dir}/${name}_bowtie2_index
# need biopython -> might be a waste of effort but Qiime alone did not seem to be working
echo "global"
bowtie2 -x ${bowtie2dir}/${name}_bowtie2_index  -f -U ${traindir}/${name}_query_gi.fasta -S ${maindir}query_subject/${name}/${name}_query_end_to_end.sam --no-hd --no-sq --very-sensitive --end-to-end --no-unal -p 120 -k ${Best_hit:=50} --un ${maindir}query_subject/${name}/${name}_query_end_to_end_reject.fasta
#unmerged pair reads local
echo "local"
bowtie2 -x ${bowtie2dir}/${name}_bowtie2_index  -f -U ${maindir}query_subject/${name}/${name}_query_end_to_end_reject.fasta -S ${maindir}query_subject/${name}/${name}_query_local.sam --no-hd --no-sq --very-sensitive --local --no-unal -p 120 -k ${Best_hit:=50} --un ${maindir}query_subject/${name}/${name}_query_end_to_end_and_local_reject.fasta
### concat all of the sam files for blca
cat ${maindir}query_subject/${name}/*.sam > ${maindir}query_subject/${name}/${name}_bowtie2_all.sam


if [ -z ${PARAMS} ]
then

  ### run BLCA
  python ${maindir}scripts/blca_from_bowtie.py -i ${maindir}query_subject/${name}/${name}_bowtie2_all.sam -r ${traindir}/${name}_subject_taxonomy_gi.txt -q ${traindir}/${name}_subject_gi.fasta -b ${B_VALUE:=0.90} -l ${PER_MIN_LEN:=0.85} -n 100


  ################### Summary stats
  # move a files around
  python ${maindir}scripts/rename_anacapa_blca_to_blast_BLCA.py ${maindir}query_subject/${name}/${name}_bowtie2_all.sam.blca.out	${raw}/raw_BLCA.out.100.tmp
  cat ${raw}/raw_BLCA.out.100.tmp | sed 's/ //g' > ${raw}/raw_BLCA.out.100; rm ${raw}/raw_BLCA.out.100.tmp
  # make a file that compares the actual taxonomy with the BLCA determined taxonomy

  for j in "100" "95" "90" "80" "70" "60" "50" "40"
	 do
	    python2 ${maindir}scripts/blca2tab_varaible_BCC.py ${rawdir}/raw_BLCA.out.100 ${traindir}/${name}_query_taxonomy_gi_taxxi.fasta ${j} > $preddir/pred_${j}BLCA.out.100
      # make a stats file
	     for i in "s" "g" "f" "o" "c" "p"
	      do
		        python2 ${maindir}scripts/taxbench.py $preddir/pred_${j}BLCA.out.100 anacapa_blca ${i} ${name} ${namecountsdir} >> $statsdir/stats_anacapa_BLCA.out.100_${j}.txt
	     done
  done

else
  source ${PARAMS}
  for id in ${IDENTITY} # minimum percent identity between query and subject
   do
    for min in ${MIN_LENGTH} # minimum percent subject length relative to the query
      do
      ### run BLCA
      python ${maindir}scripts/blca_from_bowtie.py -i ${maindir}query_subject/${name}/${name}_bowtie2_all.sam -r ${traindir}/${name}_subject_taxonomy_gi.txt -q ${traindir}/${name}_subject_gi.fasta -b ${id} -l ${min} -n 100


      ################### Summary stats
      # move a files around
      python ${maindir}scripts/rename_anacapa_blca_to_blast_BLCA.py ${maindir}query_subject/${name}/${name}_bowtie2_all.sam.blca.out	${raw}/raw_BLCA_id_${id}_minlength${min}.out.100.tmp
      cat ${raw}/raw_BLCA_id_${id}_minlength${min}.out.100.tmp | sed 's/ //g' > ${raw}/raw_BLCA_id_${id}_minlength${min}.out.100; rm ${raw}/raw_BLCA_id_${id}_minlength${min}.out.100.tmp
      # make a file that compares the actual taxonomy with the BLCA determined taxonomy

      for j in "100" "95" "90" "80" "70" "60" "50" "40"
      do
        python2 ${maindir}scripts/blca2tab_varaible_BCC.py ${raw}/raw_BLCA_id_${id}_minlength${min}.out.100 ${traindir}/${name}_query_taxonomy_gi_taxxi.fasta ${j} > $preddir/pred_id_${id}_minlength${min}_bcc${j}BLCA.out.100
        # make a stats file
        for i in "s" "g" "f" "o" "c" "p"
          do
            python2 ${maindir}scripts/taxbench.py $preddir/pred_id_${id}_minlength${min}_bcc${j}BLCA.out.100 anacapa_blca ${i} ${name} ${namecountsdir} >> $statsdir/stats_anacapa_BLCA.out.100_id_${id}_minlength${min}_bcc${j}.txt
          done
      done
    done
  done
fi
