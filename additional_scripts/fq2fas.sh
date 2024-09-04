#!/bin/bash

# convert fastq to fasta
# within the current directory (containing fastq files) a "out_fasta"
# directory (containing fasta files) will be created.

# color definitions
orange='\e[38;5;208m'
reset='\e[0m'

# Define the input directory as the current directory
input_dir="$(pwd)"
# Define the output directory as "out_fasta" in the current directory
output_dir="$input_dir/out_fasta"

# Get the total number of .fastq files in the current directory
total_files=$(ls -1 *.fastq 2>/dev/null | wc -l)
current_file_index=1

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Loop through all FASTQ files in the input directory
for input_file in "$input_dir"/*.fastq; do
    # Extract the base name of the file (without extension)
    base_name=$(basename "$input_file" .fastq)
    # Define the output file path
    output_file="$output_dir/$base_name.fasta"

    # Convert FASTQ to FASTA using awk
    awk 'NR%4==1 {print ">" substr($0, 2)} NR%4==2 {print}' "$input_file" > "$output_file"
	
	# Display progress
	printf "${orange}\nProcessing fastq file $current_file_index out of $total_files: $input_file${reset}"

	# Increment the current file index
	((current_file_index++))
	
done

printf "\nConversion completed.\n"
