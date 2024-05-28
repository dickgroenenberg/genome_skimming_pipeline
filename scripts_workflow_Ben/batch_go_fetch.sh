#!/bin/bash

# Create ref_db for the genome_skimming_pipeline (=skim2phylo)

# usage:
# go_fetch_batch.mod.sh $1 $2
# $1 = unique_taxids file
# $2 = output_dir
# example:
# batch_go_fetch.sh

# requirements:
# conda go_fetch_env
# go_fetch.py has to be added to PATH
# 
# activate conda env
# source activate go_fetch
# 
# For some reason source activate gave "activate no such file"
# Just activate the env prior to running go_fetch_batch.sh


# Define the input file
input_file="$1"
outfolder="$2"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
	echo "Input file '$input_file' not found."
	exit 1
fi

# check if outfolder already exists, if not create one
[ -d "$outfolder" ] && { printf "$outfolder folder EXISTS !!! 
\nplease remove to continue\n"; exit 1; }
mkdir -p $outfolder

# Read each line of the input file and execute commands
while IFS= read -r line; do
	# Print the argument for clarity (optional)
	echo "Processing argument: $line"
	# touch "$outfolder"/"$line"_ref_db
	go_fetch.py \
		--taxonomy "$line" \
		--target mitochondrion \
		--db genbank \
		--min 2 --max 20 \
		--output "$outfolder"/"$line" \
		--overwrite \
		--getorganelle \
		--email dick.groenenberg@naturalis.nl > "$outfolder"/log_"$line".txt
done < "$input_file"


echo Complete!

