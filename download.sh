# example script to download and data for crux
mkdir Crux
cd Crux
mkdir TAXO
cd TAXO
wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
tar xzvf taxdump.tar.gz
rm taxdump.tar.gz
cd ..

mkdir accession2taxonomy
cd accession2taxonomy
wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz
gunzip nucl_gb.accession2taxid.gz
cd ..

# ~50gb of data
mkdir NCBI_blast_nt
cd NCBI_blast_nt
wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/nt*
time for file in *.tar.gz; do tar -zxvf $file; done
cd ..

mkdir Obitools_databases
cd Obitools_databases
mkdir EMBL_fun
cd EMBL_fun
wget ftp://ftp.ebi.ac.uk/pub/databases/embl/release/std/rel_std_fun*
gunzip *.gz

# ~3hrs
time obiconvert -t ../TAXO --embl --ecopcrdb-output=./OB_dat_EMBL_std_fun ./EMBL_pro/*.dat --skip-on-error

