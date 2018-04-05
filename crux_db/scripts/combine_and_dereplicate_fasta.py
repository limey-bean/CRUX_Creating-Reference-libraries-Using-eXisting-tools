# Written by Jesse Gomer (jessegomer@gmail.com)
# for the University of California Conservation Consortium's CALeDNA Program

#example   python combine_and_dereplicate_fasta.py -o my_file.fasta -a a.fasta b.fasta c.fasta
#    or    python combine_and_dereplicate_fasta.py -o myout.fasta -d my_data_directory/
import argparse
import shutil
import glob


def add_sequences_to_dictionary(fasta, sequences):
    lines = fasta.readlines()
    for i in xrange(0, len(lines), 2):
        accession = lines[i].strip()
        seq = lines[i+1].strip()
        if accession in sequences:
            if len(seq) > len(sequences[accession]):
                sequences[accession] = seq
        else:
            sequences[accession] = seq


def combine_and_dereplicate(output_name, file_names):
    # dictionary from accession to sequence
    sequences = {}
    for file_name in file_names:
        with open(file_name) as f:
            add_sequences_to_dictionary(f, sequences)

    with open(output_name + '.tmp', 'w') as outfile:
        for accession, seq in sequences.items():
            outfile.write('{}\n{}\n'.format(accession, seq))

    shutil.move(output_name + '.tmp', output_name)


parser = argparse.ArgumentParser(description='Combine and dereplicate FASTA files NOTE: currently works quickly only ' +
                                             'if the output is smaller than than memory')
parser.add_argument('-o', '--out', type=str,
                    help='Write to a different output file (by default writes to out.fasta)')
parser.add_argument('-a', '--fasta', nargs='+',  help='FASTA files to combine and dereplicate')
parser.add_argument('-d', '--directory', help='Run on all FASTA files in a directory')

if __name__ == "__main__":
    args = parser.parse_args()
    files = args.fasta

    if args.out:
        outfile = args.out
    else:
        outfile = 'out.fasta'

    if args.directory:
        directory = args.directory
        if args.directory[-1] != '/':
            directory = directory + '/'
        files = glob.glob(directory + '*.fasta')

    combine_and_dereplicate(outfile, files)
