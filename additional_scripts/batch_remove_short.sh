#!/bin/bash

# Directory containing the FASTA files (current directory)
input_dir=$(pwd)
# Output directory
output_dir="$input_dir/out_fasta_gt_50"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Loop over all FASTA files in the input directory
for input_file in "$input_dir"/*.fasta; do
  # Check if any FASTA files are found
  if [ ! -e "$input_file" ]; then
    echo "No FASTA files found in the input directory."
    exit 1
  fi

  # Generate the output file path
  output_file="$output_dir/$(basename "$input_file")"

  # Process the FASTA file
  awk '/^>/ {header = $0; next} {sequence = $0; if (length(sequence) >= 50) print header RS sequence}' "$input_file" > "$output_file"
done

printf "Processing complete.\nOutput files are in the directory:\n$output_dir\n"
