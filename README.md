# CRUX: Creating Reference libraries Using eXisting tools

### CRUX		last updated 1-05-2018
#### Written by Emily Curd (eecurd@g.ucla.edu), Gaurav Kandlikar (gkandlikar@ucla.edu), and Jesse Gomer (jessegomer@gmail.com)
#### Developed at UCLA for the University of California Conservation Consortium's CALeDNA Program

## Introduction

Taxonomic assignments of metabarcoding reads requires a comprehensive reference library. There are preexisting high quality reference libraries that are compatible with 16S and 18S metabarcode primers (Glöckner et al., 2017, DeSantis et al., 2006). There are few other comprehensive metabarcode specific reference libraries. Using  **CRUX**: **C**onstructing **R**eference libraries **U**sing e**X**isting tools (CRUX) we are able to construct custom reference libraries given a primer set and several publicly available databases.

CRUX generates custon reference libraries by first running in silico PCR (**ecoPCR**; Ficetola et al., 2010) against the EMBL standard nucleotide sequence database (Stoesser et al., 2002) to generate a seed library of reads with unique taxon identifiers. Other nucleotide databases can also be used in this step (e.g. genbank, custom fasta files, etc.).  CRUX verifies that the seed library reads match the amplicon by checking for the correct primer regions and trimming them using **cutadapt** (Martin, 2011).  

Because many sequencing records are deposited to Genbank (Benson et al., 2012) with the primer regions removed from the read, we **BLAST** (Camacho et al., 2009) the seed library against the NCBI nucleotide blast database (ftp://ftp.ncbi.nlm.nih.gov/blast/). CRUX runs blastn twice.  The first blastn run only accepts full length reads (e.g. the same length as the Reference) and then de-replicates the resulting fasta files by NCBI accession version number. The second blastn run accepts reads up to 70% of full length (because many hits to metabarcodes do not cover the entire read length).  The resulting reads are sorted by length and de-replicated so that only the longest version of a read is retained.

A corresponding taxonomy identification file (superkingdom, phylum, class, order, family, genus, species) is generated from the fasta formatted blast output using **entrez-qiime** (https://github.com/bakerccm/entrez_qiime), the NCBI’s taxonomy dump and map of association between taxonomy and accession version numbers (ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/). Because NCBI taxonomy is not always complete (e.g. uncultured organisms, organisms with unknown taxonomy, etc.) CRUX generates two reference files; filtered and unfiltered.  The filtered reference files exclude reads with the following in their taxonomic path: 'uncultured', 'environmental', 'sample', of 'NA;NA;NA;NA'.

The down stream metabarcoding Anacapa pipeline (https://github.com/limey-bean/Anacapa)runs **Bowtie2** (Langmead et al., 2009) to assigns reads to these references databases and generate a corresponding taxonomy file. Thus the final step is to generate **Bowtie2** formatted data index libraries.

## Overview
<p align="center">
<img src="Crux_flow.png" height="500" width="300">
</p>

## Before CRUX is operable, you will need to download, install and/or build several programs and databases.
**__First Download the crux_release_V1_db folder.__** The executables and database folders should be accessible from this folder. However, if you already have any these programs or databases, there is no need to add them to the crux_release_V1_db folder. Instead update the file paths or loading commands to the Crux_config.sh and crux_vars.sh files.

**__Programs__**


1. OBItools:
         https://git.metabarcoding.org/obitools/obitools/wikis/home
	* OBItools is used to generate reference libraries for the ecoPCR in silico PCR step for CRUX.
	* OBItools does not need to be installed in the crux_release_V1_db folder.
	* Installation information can be found here:  
           http://metabarcoding.org//obitools/doc/welcome.html#installing-the-obitools

2. ecoPCR:
         https://git.metabarcoding.org/obitools/ecopcr/wikis/home
	* If you are not modifying the Crux_config.sh, then the path to the ecoPCR executable should be as follows:

```
~/crux_release_V1_db/ecoPCR/src/ecoPCR
```

3. cutadapt:
         http://cutadapt.readthedocs.io/en/stable/index.html
      * cutadapt does not need to be installed in the crux_release_V1_db folder, however you will need to verify that the Crux_config.sh is modified for you computing environment.

4. BLAST+:
         https://www.ncbi.nlm.nih.gov/books/NBK279690/
	* the lastest BLAST executables can be downloaded from: ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.6.0/
	* If you are not modifying the Crux_config.sh, then the path to the blastn executable should be as follows:

  ```
  ~/crux_release_V1_db/ncbi-blast-2.6.0+/bin/blastn
  ```

5. entrez_qiime:
        https://github.com/bakerccm/entrez_qiime
	* **entrez_qiime.py** is already included in crux_release_V1_db folder

6. Bowtie2:
        http://bowtie-bio.sourceforge.net/bowtie2/index.shtml
	* Bowtie2 does not need to be installed in the crux_release_V1_db folder, however you will need to verify that the Crux_config.sh is modified for you computing environment.


**__Databases to download__**

1. NCBI taxonomy dump:  
        ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
 * If you are not modifying the Crux_config.sh, then the path to the taxonomy folder should be as follows:

 ```
 ~/crux_release_V1_db/TAXO
 ```

  * The folder should contain the following files: delnodes.dmp, merged.dmp, names.dmp, nodes.dmp
  * download information can be found here: https://github.com/bakerccm/entrez_qiime/blob/master/entrez_qiime.pdf

2. NCBI accession2taxonomy file: ftp://ftp.ncbi.nih.gov/pub/taxonomy/accession2taxid/nucl_gb.accession2taxid.gz
	* If you are not modifying the Crux_config.sh, then the path to the accession to taxonomy file should be as follows:

    ```ruby
    ~/crux_release_V1_db/accession2taxonomy/nucl_gb.accession2taxid
    ```

	* download information can be found here: https://github.com/bakerccm/entrez_qiime/blob/master/entrez_qiime.pdf

3. NCBI BLAST nt library: ftp://ftp.ncbi.nlm.nih.gov/blast/db/

  ```
  mkdir ~/crux_release_V1_db/NCBI_blast_nt
  cd ~/crux_release_V1_db/NCBI_blast_nt
  wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/nt*
  gunzip tar -zxvf \*.tar.gz
  ```

4. Database files for generating ecoPCR compatible OBItools libraries
  * see Obitools documentation for range of file types that can be converted into ecoPCR searchable libraries
  * Example using EMBL_date_std database files:
          ftp://ftp.ebi.ac.uk/pub/databases/embl/release/std
	* Determine which EMBL databases you wish to include.  
		* One strategy is to download all of the files for only some of the organism: fun, inv, mam, phg, pln, pro, rod, syn, tgn, vrl, vrt
		* It is ok to skipped hum, and mus because those reads will be picked up while blasting.
	* These do not need to be stored in crux_release_V1_db, but they need to be stored as a single folder or as a series of folders based on taxonomic groupings (e.g. store all prokaryotes (pro) in a single and separate folder, store all plant (pln) in a single and separate folder, etc.)
	* These are very large files, and it is less memory intensive to download them in small batches, and convert them into many small obitools/ecopcr readable databases.

    ```
    wget ftp://ftp.ebi.ac.uk/pub/databases/embl/release/std/rel_std_fun
    wget ftp://ftp.ebi.ac.uk/pub/databases/embl/release/std/rel_std_pro
    ```

    etc...

    ```
    gunzip *.gz
    ```


**__Building OBItools/ecoPCR Readable Databases__**  
 Example: Convert embl databases into obitools/ecopcr readable databases using obiconvert
* the obiconvert python script is part of the OBItools.
	* the documentation can be found here:
          http://metabarcoding.org/obitools/doc/scripts/obiconvert.html
	* a tutorial can be found here:
          http://metabarcoding.org/obitools/doc/wolves.html
* The obiconvert command requires:
	* the path to the ncbi taxonomy folder (-t)
		* downloaded above ~/crux_release_V1_db/TAXO
	* the file format (--embl)
	* the output folder path (--ecopcrdb-output)
		* the file path needs to be

    ```
    ~/crux_release_V1_db/Obitools_databases/some_folder_name_that_corresponds_to_the_type_of_embl_sequences
    ```
    e.g.

    ```
    ~/crux_release_V1_db/Obitools_databases/EMBL_6167017_std_pro
    ```
    * the input file(s) path(s)
    * e.g. the folder where all prokaryote (pro) files are stored in a single and separate folder
    * Depending on the size of the EMBL database files this may take a lot of time and a lot of RAM
    * The command is as follows:

    ```ruby
    obiconvert -t </path/to/taxonfile> --embl --ecopcrdb-output=/path/to/output /path/to/inputs --skip-on-error
    ```
	  e.g.

     ```ruby
     obiconvert -t ~/crux_release_V1_db/TAXO --embl --ecopcrdb-output=~/crux_release_V1_db/Obitools_databases/EMBL_6167017_std_pro ~/EMBL_pro/\*.dat --skip-on-error
     ```

## Running CRUX
### CRUX was developed to run on an a computer cluster with an SGE scheduler

## Step by Step Explanation of CRUX

### Crux Part 1: ecoPCR and BLAST 1
1. Run ecoPCR using the user specified primer on the user generated OBItools compatible databases.  
	* ecoPCR parameters can be altered in the /crux_release_V1_db/crux_vars.sh file
2. ecoPCR results are de-replicated based on taxon id (taxid), and converted to fasta format.
3. cutadapt is used to verify and retain only the ecoPCR reads with correct primer sequences, then trim the primers from the 5' and 3' ends.
4. Clean fasta files are used as seeds to generate full length BLAST libraries.
 * these seed files are broken in to 500 read chunks and blasted as an array against blasted against the NCBI nucleotide blast databases using blastn.
 * Only full length hits with 50% identity or better are accepted.
 * up to 5000 hits are retained
 * BLAST array jobs submission scripts can be found in:

  ```
  ~/crux_release_V1_db/CO1/blast_jobs/*_blast1.sh
  ```

The command for CRUX Part 1 is as follows:

  ```
  sh crux_part1.sh -n metabarcode_target_name -f forward_primer_sequence -r reverse_primer_sequence -l shortest expected length of an amplicon -m longest expected length of an amplicon -d path_to_CRUX_db_folder -o path_to_output_folder -c clean up intermediate files "y/n" -h "cluster username"
  ```

* An example:

  ```
  sh ~/crux_release_V1_db/crux_part1.sh -n CO1 -f GGWACWGGWTGAACWGTWTAYCCYCC  -r TANACYTCnGGRTGNCCRAARAAYCA -l 200 -m 650 -d ~/crux_release_V1_db -o ~/crux_release_V1_db/CO1 -c n -h eecurd
  ```

### Crux Part 2: Blast 2
1. The BLAST results from BLAST 1 are dereplicated by NCBI version accession number
2. The fasta files are broken into smaller pieces and once agin blasted against the NCBI nucleotide blast databases using blastn.
	* blastn parameters can be altered in the /crux_release_V1_db/crux_vars.sh file
	* default parameters are
	     * e-value = 0.0000000001
	     * minimum percent of subject that needs to be covered by the query = 80%
	     * minimum percent identity of the query relative to the subject = 70%
	     * maximum number of hits to retain per subject = 2000
	     * number of threads to launch = 40
  * For CO1 this requires up to ~25 GB of memory for 1.5 hours
  * BLAST array jobs submission scripts can be found in:

  ```
  ~/crux_release_V1_db/CO1/blast_jobs/*_blast2.sh
  ```

The command to run CRUX Part 2 is:

```
sh crux_part2.sh -n metabarcode_target_name -f forward_primer_sequence -r reverse_primer_sequence -l shortest expected length of an amplicon -m longest expected length of an amplicon -d path_to_CRUX_db_folder -o path_to_output_folder -c clean up intermediate files "y/n" -h "cluster username"
```

### Crux Part 3: Cleaning up blast results, generating bowtie2 libraries, and removing intermediate steps
1. The blast results are sorted by length (longest to shortest) and then de-replicated by NCBI accession version number and converted into fasta format. Only the longest instance of a read is retained.
2. entrez-qiime is used to determine taxonomy for each read based on NCBI version accession number.
3. An additional data base of taxonomy filtered reads is generated.  
  * Reads with taxonomy identified as NA;NA;NA;NA, or with uncultured, unknown, unassigned, or environmental in the name are removed from the cleaned blast results fasta output and corresponding taxonomy file.
4. Build bowtie2 index libraries for the filtered and unfiltered Databases
5. Remove intermediate steps

The command to run CRUX Part 3 is:

  ```
  sh crux_part3.sh -n metabarcode_target_name -f forward_primer_sequence -r reverse_primer_sequence -l shortest expected length of an amplicon -m longest expected length of an amplicon -d path_to_CRUX_db_folder -o path_to_output_folder -c clean up intermediate files "y/n" -h "cluster username"
  ```

The database files are found in:

```
~/crux_release_V1_db/<metabarcode_target_name>/<metabarcode_target_name>_db_filtered_to_remove_ambigous_taxonomy
```

and

```
~/crux_release_V1_db/<metabarcode_target_name>/<metabarcode_target_name>_db_unfiltered
```

## References:

Benson, D.A., Cavanaugh, M., Clark, K., Karsch-Mizrachi, I., Lipman, D.J., Ostell, J. and Sayers, E.W., 2012. GenBank. Nucleic acids research, 41(D1), pp.D36-D42.

Camacho, C., Coulouris, G., Avagyan, V., Ma, N., Papadopoulos, J., Bealer, K. and Madden, T.L., 2009. BLAST+: architecture and applications. BMC bioinformatics, 10(1), p.421.

Caporaso, J.G., Kuczynski, J., Stombaugh, J., Bittinger, K., Bushman, F.D., Costello, E.K., Fierer, N., Peña, A.G., Goodrich, J.K., Gordon, J.I. and Huttley, G.A., 2010. QIIME allows analysis of high-throughput community sequencing data. Nature methods, 7(5), pp.335-336.

DeSantis, T.Z., Hugenholtz, P., Larsen, N., Rojas, M., Brodie, E.L., Keller, K., Huber, T., Dalevi, D., Hu, P. and Andersen, G.L., 2006. Greengenes, a chimera-checked 16S rRNA gene database and workbench compatible with ARB. Applied and environmental microbiology, 72(7), pp.5069-5072.

Edgar, R.C., 2010. Search and clustering orders of magnitude faster than BLAST. Bioinformatics, 26(19), pp.2460-2461.

Ficetola, G.F., Coissac, E., Zundel, S., Riaz, T., Shehzad, W., Bessière, J., Taberlet, P. and Pompanon, F., 2010. An in silico approach for the evaluation of DNA barcodes. BMC genomics, 11(1), p.434.

Glöckner, F.O., Yilmaz, P., Quast, C., Gerken, J., Beccati, A., Ciuprina, A., Bruns, G., Yarza, P., Peplies, J., Westram, R. and Ludwig, W., 2017. 25 years of serving the community with ribosomal RNA gene reference databases and tools. Journal of Biotechnology.

Martin, M., 2011. Cutadapt removes adapter sequences from high-throughput sequencing reads. EMBnet. journal, 17(1), pp.pp-10.

Langmead, B., Trapnell, C., Pop, M. and Salzberg, S.L., 2009. Ultrafast and memory-efficient alignment of short DNA sequences to the human genome. Genome biology, 10(3), p.R25.

Stoesser, G., Baker, W., van den Broek, A., Camon, E., Garcia-Pastor, M., Kanz, C., Kulikova, T., Leinonen, R., Lin, Q., Lombard, V. and Lopez, R., 2002. The EMBL nucleotide sequence database. Nucleic acids research, 30(1), pp.21-26.
