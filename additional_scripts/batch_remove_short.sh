#!/bin/bash

# remove reads shorter than 50 bp from fasta
# within the current directory (containing fasta files) a directory
# "out_fasta_gt_50" will be created.

# color definitions
orange='\e[38;5;208m'
reset='\e[0m'

# Directory containing the FASTA files (current directory)
input_dir=$(pwd)
# Output directory
output_dir="$input_dir/out_fasta_gt_50"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Get the total number of .fasta files in the current directory
total_files=$(ls -1 *.fasta 2>/dev/null | wc -l)
current_file_index=1

# Loop over all FASTA files in the input directory
for input_file in "$input_dir"/*.fasta; do
	# Check if any FASTA files are found
	if [ ! -e "$input_file" ]; then
		echo "No FASTA files found in the input directory."
		exit 1
	fi

	# Generate the output file path
	output_file="$output_dir/$(basename "$input_file")"

	# Display progress
	printf "${orange}\nProcessing fasta file $current_file_index out of $total_files: $input_file${reset}"

	# Process the FASTA file
	awk '/^>/ {header = $0; next} {sequence = $0; if (length(sequence) >= 50) print header RS sequence}' "$input_file" > "$output_file"

	# Increment the current file index
	((current_file_index++))

done

printf "\nProcessing complete.\nOutput files are in the directory:\n$output_dir\n"
