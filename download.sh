#! /bin/bash

# example script to download and data for crux
# make a crux_db directory
mkdir crux_db
cd crux_db

# make a TAXO directory and download and unpack the taxdump file
mkdir TAXO
cd TAXO
wget ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
tar xzvf taxdump.tar.gz
rm taxdump.tar.gz
cd ..

# make a accession2taxonomy directory and download and unpack the nucl_gb.accession2taxid.gz file

mkdir accession2taxonomy
cd accession2taxonomy
wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz
gunzip nucl_gb.accession2taxid.gz
cd ..

# make an NCBI_blast_nt directory and download and unpack the blast db files
# ~50gb of data
mkdir NCBI_blast_nt
cd NCBI_blast_nt
wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/nt*
time for file in *.tar.gz; do tar -zxvf $file; done
cd ..

# make an Obitools_databases directory and download and unpack the database files of interest
# note this is only an example of the fungal db download.
# rinse and repeat for the other databases

mkdir Obitools_databases
cd Obitools_databases
mkdir EMBL_fun
cd EMBL_fun
wget ftp://ftp.ebi.ac.uk/pub/databases/embl/release/std/rel_std_fun*
gunzip *.gz

# Build the Obitools_databases
# note this is only an example of the fungal OBITools db conversion.
# rinse and repeat for the other databases

# ~3hrs
time obiconvert -t ../TAXO --embl --ecopcrdb-output=./OB_dat_EMBL_std_fun ./EMBL_pro/*.dat --skip-on-error
