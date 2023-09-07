#!/bin/bash

# sort output per sample instead of per run
# convenient if this could be added to the Snakefile
# create a folder for each sample (based on annotations)
# location of the output folder?
# the commands are run from the folder that contains the Snakefile - not the results folder currently tested

# $1 = output_dir = specified in config/*yaml e.g. results/run_number
# $2 = per_sample_dir = could be added to config/*yaml as well e.g. results/per_sample
# ./scripts/run2sample.sh results/152815 results/per_sample

declare -a folders=("annotations" "assembled_sequence" "assess_assembly"
"blastn" "blobtools" "fastp" "fastqc" "getorganelle" "minimap" "seqkit")

declare -a samples=$(ls "$1"/seqkit/*txt | sed 's/\.txt//g' | awk -F"/" '{print $NF}')

# create a folder for e
for sample in ${samples[@]}; do
mkdir -p "$2"/$sample
    for val in "${folders[@]}"; do
    mkdir -p "$2"/$sample/$val
    done
done

# move (for now copy) the results to per_sample
for sample in ${samples[@]}; do
cp -r "$1"/annotations/$sample/* "$2"/$sample/annotations
cp -r "$1"/assembled_sequence/$sample* "$2"/$sample/assembled_sequence
cp -r "$1"/assess_assembly/$sample* "$2"/$sample/assess_assembly
cp -r "$1"/blastn/$sample* "$2"/$sample/blastn
cp -r "$1"/blobtools/$sample/* "$2"/$sample/blobtools
cp -r "$1"/fastp/$sample* "$2"/$sample/fastp
cp -r "$1"/fastqc/$sample* "$2"/$sample/fastqc
cp -r "$1"/getorganelle/$sample/* "$2"/$sample/getorganelle
cp -r "$1"/minimap/$sample* "$2"/$sample/minimap
cp -r "$1"/seqkit/$sample* "$2"/$sample/seqkit
done
