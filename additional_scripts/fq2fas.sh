#!/bin/bash

# Define the input directory as the current directory
input_dir="$(pwd)"
# Define the output directory as "out_fasta" in the current directory
output_dir="$input_dir/out_fasta"

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
done

echo "Conversion completed."
