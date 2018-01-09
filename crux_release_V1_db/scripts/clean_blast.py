# Written by Jesse Gomer (jessegomer@gmail.com)
# for the University of California Conservation Consortium's CALeDNA Program

import shutil
import re
import sys

class FastA(object):
    def __init__(self, file_name):
        self.file_name = file_name

    def iterate_through_reads(self, file_iterator):
        identifier = None
        data = []
        group = []
        try:
            while True:
                line = next(file_iterator)
                if line[0] == '>':
                    if len(data) > 0:
                        yield identifier, ''.join(data), ''.join(group)
                    identifier = line[1:].strip()
                    data = []
                    group = [line]
                else:
                    data.append(line)
                    group.append(line)

        except StopIteration:
            yield identifier, ''.join(data), ''.join(group)

    def create_excluded_copy(self, output_name, exclusions):
        with open(self.file_name) as source:
            # using a tmp file just incase source and dest are the same
            with open(output_name + '.tmp', 'w') as dest:
                for identifier, _, whole_group in self.iterate_through_reads(source):
                    if identifier not in exclusions:
                        dest.write(whole_group)
        # move the temp file to the real one
        shutil.move(output_name + '.tmp', output_name)


class TaxonomyFile(object):
    def __init__(self, file_name):
        self.file_name = file_name

    def split_line(self, line):
        raw_split = line.split('\t')
        identifier = raw_split[0]
        taxonomy = raw_split[1]
        taxonomy_pieces = re.split(r';|\s', taxonomy)

        return identifier, taxonomy, taxonomy_pieces

    def find_identifiers_to_exclude(self, exclusion_words, exclusion_phrases):
        exclusions = set()
        with open(self.file_name) as f:
            for line in f:
                identifier, taxonomy, taxonomy_pieces = self.split_line(line)
                for phrase in exclusion_phrases:
                    if phrase in taxonomy:
                        exclusions.add(identifier)
                for word in exclusion_words:
                    if word in taxonomy_pieces:
                        exclusions.add(identifier)

        return exclusions

    def create_excluded_copy(self, output_name, exclusions):
        with open(self.file_name) as source:
            # using a tmp file just incase source and dest are the same
            with open(output_name + '.tmp', 'w') as dest:
                for line in source:
                    identifier, _, _ = self.split_line(line)
                    if identifier not in exclusions:
                        dest.write(line)
        # move the temp file to the real one
        shutil.move(output_name + '.tmp', output_name)


def clean_blast(input_fasta_file_name, output_fasta_file_name,
                input_taxonomy_file_name, output_taxonomy_file_name,
                exclusion_words, exclusion_phrases):

    input_fasta = FastA(input_fasta_file_name)
    input_taxonomy = TaxonomyFile(input_taxonomy_file_name)

    to_exclude = input_taxonomy.find_identifiers_to_exclude(exclusion_words, exclusion_phrases)

    input_taxonomy.create_excluded_copy(output_taxonomy_file_name, to_exclude)
    input_fasta.create_excluded_copy(output_fasta_file_name, to_exclude)

#todo use argparse and warn on bad args
clean_blast(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4],
            ['uncultured', 'environmental', 'sample'], ['NA;NA;NA;NA'])