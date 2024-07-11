#!/bin/bash

# requirements: MitoGeneExtractor
# usage: batch_MGE $1
# where $1 is optional, but when provided should be the
# complete path to the protein_reference_file

# Keep in mind, when adjusting this reference, the genetic
# code (-C parameter; default 5 for invertebrate mitochondrial)
# might need to be adjusted as well.

# color definitions
orange='\e[38;5;208m'
reset='\e[0m'

# Set default value for -p parameter
prot_ref="/data/dick.groenenberg/MitoGeneExtractor/Amino-Acid-references-for-taxonomic-groups/COI-references-for-different-taxonomic-groups/insecta_COI_genera_consensus.fasta"

# Check if the first argument is provided
if [ -n "$1" ]; then
	prot_ref="$1"
fi

# Get the total number of .fas and .fasta files in the current directory
total_files=$(ls -1 *.fas *.fasta 2>/dev/null | wc -l)
current_file_index=1

# Loop through all .fas and .fasta files in the current directory
for fasta_file in *.fas *.fasta; do

	# Check if fasta_file is a regular file
	if [ -f "$fasta_file" ]; then
		# Get the basename of the file (without extension)
		base_name="${fasta_file%.*}"

	# Display progress
	printf "${orange}\nProcessing fasta file $current_file_index out of $total_files: $fasta_file${reset}\n\n"

	# Increment the current file index
	((current_file_index++))

	# Run MitoGeneExtractor-v1.9.5 with the appropriate parameters
	MitoGeneExtractor-v1.9.5 \
	-d "$fasta_file" \
	-p "$prot_ref" \
	-o "${base_name}_aln_" \
	-n 0 \
	-c "${base_name}_" \
	-t 0.5 \
	-r 1 \
	-C 5 \
	--verbosity 0 \
	--report_gaps_mode 1
	fi
done

rename s/_aln_Consensus.fas/_aln.fas/g *
rename s/_Consensus.fas/_cns.fas/g *
rm tmp-vulgar.txt.log