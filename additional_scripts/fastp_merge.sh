#!/bin/bash

# Set the input directory to the current directory
input_dir="$(pwd)"

# Create an output directory for merged files
output_dir="${input_dir}/merged"
mkdir -p $output_dir

# Set variables
# correct filecount for the folder that is added by running this script
filecount=$(ls -1 $input_dir | wc -l | awk '{print $1 - 1}' | bc)
counter=0
green='\e[92m'
reset='\e[0m'

# Loop through all directories in the current directory
for dir in ${input_dir}/*/; do
    # Skip the "merged" output directory
    if [[ "$dir" == "$output_dir/" ]]; then
        continue
    fi

    (( counter += 1 ))
    printf "${green}Running Fastp on $counter of $filecount ${reset}\n"

    # Find the _R1 and _R2 files in the current directory
    r1_file=$(find "$dir" -type f -name '*_R1*.fastq.gz')
    r2_file=$(find "$dir" -type f -name '*_R2*.fastq.gz')
    
    # Check if both R1 and R2 files exist
    if [[ -f "$r1_file" && -f "$r2_file" ]]; then
        # Derive the base name for the output files
        base_name=$(basename ${dir%/})
        
        # Define the output file names
        merged_output="${output_dir}/${base_name}_merged.fastq"
        html_report="${output_dir}/${base_name}_report.html"
        json_report="${output_dir}/${base_name}_report.json"
        
        # Run fastp with merging option
        fastp \
            --in1 "$r1_file" \
            --in2 "$r2_file" \
            -m \
            --merged_out "$merged_output" \
            --html "$html_report" \
            --json "$json_report" \
            --detect_adapter_for_pe \
            --adapter_sequence=AGATCGGAAGAGCACACGTCTGAACTCCAGTCA \
            --adapter_sequence_r2=AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT \
            --trim_poly_g \
            --correction \
            --dedup
        
        echo "Processed: $r1_file and $r2_file -> $merged_output"
    else
        echo "Skipping: $dir (R1 or R2 file missing)"
    fi
done




