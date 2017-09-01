CRUX_release_V1		09-01-2017
CRUX: Creating Reference libraries Using eXisting tools

Written by Emily Curd (eecurd@g.ucla.edu) and Gaurav Kandlikar (gkandlikar@ucla.edu)
Developed at UCLA for the University of California Conservation Consortium's CALeDNA Program

Introduction
  
Taxonomic assignments of metabarcoding reads requires a comprehensive reference library. For 16S and 18S metabarcode reads, we use the Silva high quality ribosomal databases (Glöckner et al., 2017) for reference libraries. For all other metabarcodes we construct custom reference libraries using our in-house wrapper script, CRUX: Constructing Reference libraries Using eXisting tools. CRUX generates reference libraries by running in silico PCR (ecoPCR; Ficetola et al., 2010) against the EMBL standard nucleotide sequence database (Stoesser et al., 2002) to generate a seed library of reads with unique taxon identifiers. Because many sequencing records are deposited to Genbank (Benson et al., 2012) with the primer regions removed from the read, we BLAST (Camacho et al., 2009) the seed library against the NCBI nucleotide blast database (ftp://ftp.ncbi.nlm.nih.gov/blast/). Blast results are de-replicated by version accession number and converted to fasta format. A taxonomy identification file is generated from the fasta formatted blast output using entrez-qiime (https://github.com/bakerccm/entrez_qiime), the NCBI’s taxonomy dump and map of association between taxonomy and accession version numbers (ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/). To minimize the reference library file size and merge highly similar reads, we use Qiime (Caporaso et al., 2010) to cluster the reference library at 99% sequence similarity using Usearch (Edgar, 2010) and generate a corresponding taxonomy file assign taxonomy in Qiime using Uclust (Edgar, 2010) at 97%. 

Next steps: The reference library can then be used to generate a multiple sequence alignment using muscle (ref) and a phylogenetic tree using (decide). 
