# if you want to test of parameters for
  # minimum percent identity between query and subject
  # and
  # minimum percent subject length relative to the query
# then modify the fractions below and pass this file with the -p flags
# e.g.: #  bash /CRUX_database_comparison_TAXXI_metrics.sh  -m ~/CRUX_database_comparison_TAXXI_metrics -n MitoFish_vs_12S -a ~/MitoFish_.fasta -b ~/MitoFish_taxonomy.txt -c ~/12S_.fasta -d ~/12S_taxonomy.txt -p ~/Bowtie2_BLCA_classifier_params.sh


IDENTITY="0.8 0.6"    #"1.0 0.90 0.80 0.70 0.60" # minimum percent identity between query and subject
MIN_LENGTH="0.8 0.6"  #"1.0 0.90 0.80 0.70 0.60" # minimum percent subject length relative to the query
