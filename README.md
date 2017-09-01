# CRUX: Creating Reference libraries Using eXisting tools

### CRUX_release_V1		09-01-2017
#### Written by Emily Curd (eecurd@g.ucla.edu) and Gaurav Kandlikar (gkandlikar@ucla.edu)
#### Developed at UCLA for the University of California Conservation Consortium's CALeDNA Program

## Introduction
  
Taxonomic assignments of metabarcoding reads requires a comprehensive reference library. For 16S and 18S metabarcode reads, we use the Silva high quality ribosomal databases (Glöckner et al., 2017) for reference libraries. For all other metabarcodes we construct custom reference libraries using our in-house wrapper script, CRUX: Constructing Reference libraries Using eXisting tools. CRUX generates reference libraries by running in silico PCR (ecoPCR; Ficetola et al., 2010) against the EMBL standard nucleotide sequence database (Stoesser et al., 2002) to generate a seed library of reads with unique taxon identifiers. Because many sequencing records are deposited to Genbank (Benson et al., 2012) with the primer regions removed from the read, we BLAST (Camacho et al., 2009) the seed library against the NCBI nucleotide blast database (ftp://ftp.ncbi.nlm.nih.gov/blast/). Blast results are de-replicated by version accession number and converted to fasta format. A taxonomy identification file is generated from the fasta formatted blast output using entrez-qiime (https://github.com/bakerccm/entrez_qiime), the NCBI’s taxonomy dump and map of association between taxonomy and accession version numbers (ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/). To minimize the reference library file size and merge highly similar reads, we use Qiime (Caporaso et al., 2010) to cluster the reference library at 99% sequence similarity using Usearch (Edgar, 2010) and generate a corresponding taxonomy file assign taxonomy in Qiime using Uclust (Edgar, 2010) at 97%. 

Next steps: The reference library can then be used to generate a multiple sequence alignment using muscle (ref) and a phylogenetic tree using (decide). 

## Before CRUX is operable, you will need to download, install and/or build several programs and databases. 
**__First Download the crux_release_V1_db folder.__** The executables and database folders should be accessible from this folder. However, if you already have any these programs or databases, there is no need to add them to the crux_release_V1_db folder. Instead update the file paths or loading commands to the Crux_config.sh and crux_vars.sh folders accordingly.

**__Programs__**


1. OBItools: https://git.metabarcoding.org/obitools/obitools/wikis/home
	* OBItools is used to generate reference libraries for the ecoPCR in silico PCR step for CRUX.
	* OBItools does not need to be installed in the crux_release_V1_db folder.
	* Installation information can be found here: http://metabarcoding.org//obitools/doc/welcome.html#installing-the-obitools

2. ecoPCR: https://git.metabarcoding.org/obitools/ecopcr/wikis/home
	* If you are not modifying the Crux_config.sh, then the path to the ecoPCR executable should be as follows: /crux_release_V1_db/ecoPCR/src/ecoPCR

3. BLAST+: https://www.ncbi.nlm.nih.gov/books/NBK279690/
	* the lastest BLAST executables can be downloaded from: ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.6.0/
	* If you are not modifying the Crux_config.sh, then the path to the blastn executable should be as follows: /crux_release_V1_db/ncbi-blast-2.6.0+/bin/blastn

4. entrez_qiime: https://github.com/bakerccm/entrez_qiime
	* **entrez_qiime.py** is already included in crux_release_V1_db folder

5. Qiime 1: http://qiime.org/index.html
	* Qiime 1 does not need to be installed in the crux_release_V1_db folder, however you will need to verify that the Crux_config.sh is modified for you computing environment. 
	* Installation information can be found here: http://qiime.org/install/install.html
	* We will transition to Qiime 2 by January 01, 2018. 
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
## References:

Benson, D.A., Cavanaugh, M., Clark, K., Karsch-Mizrachi, I., Lipman, D.J., Ostell, J. and Sayers, E.W., 2012. GenBank. Nucleic acids research, 41(D1), pp.D36-D42.

Camacho, C., Coulouris, G., Avagyan, V., Ma, N., Papadopoulos, J., Bealer, K. and Madden, T.L., 2009. BLAST+: architecture and applications. BMC bioinformatics, 10(1), p.421.

Caporaso, J.G., Kuczynski, J., Stombaugh, J., Bittinger, K., Bushman, F.D., Costello, E.K., Fierer, N., Peña, A.G., Goodrich, J.K., Gordon, J.I. and Huttley, G.A., 2010. QIIME allows analysis of high-throughput community sequencing data. Nature methods, 7(5), pp.335-336.

Edgar, R.C., 2010. Search and clustering orders of magnitude faster than BLAST. Bioinformatics, 26(19), pp.2460-2461.

Ficetola, G.F., Coissac, E., Zundel, S., Riaz, T., Shehzad, W., Bessière, J., Taberlet, P. and Pompanon, F., 2010. An in silico approach for the evaluation of DNA barcodes. BMC genomics, 11(1), p.434.

Glöckner, F.O., Yilmaz, P., Quast, C., Gerken, J., Beccati, A., Ciuprina, A., Bruns, G., Yarza, P., Peplies, J., Westram, R. and Ludwig, W., 2017. 25 years of serving the community with ribosomal RNA gene reference databases and tools. Journal of Biotechnology.

Stoesser, G., Baker, W., van den Broek, A., Camon, E., Garcia-Pastor, M., Kanz, C., Kulikova, T., Leinonen, R., Lin, Q., Lombard, V. and Lopez, R., 2002. The EMBL nucleotide sequence database. Nucleic acids research, 30(1), pp.21-26.
