#!/bin/bash

input_file="$1"
output_file="output.fasta"

awk '/^>/ {header = $0; next} {sequence = $0; if (length(sequence) >= 55) print header RS sequence}' "$input_file" > "$output_file"
