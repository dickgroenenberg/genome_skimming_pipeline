#!/usr/bin/env bash

# script creates sample_list.csv which should be specified in config.yaml
# run it in the "config" folder

# accomodates:
# https://github.com/o-william-white/genome_skimming_pipeline

# assumptions: 
# sequence data and reference genome db are located in "genome_skimming_pipeline/ref_db"
# the first 3 columns of the sequence name (underscore as separator) are the ID (eg. BGE00421_A01_UNIFIBGE0107)
#
# raw sequences (reads in fq.gz) are in genome_skimming/input/_path_/_to_/raw_sequences
#
# reference databases (created with go_fetch) are in genome_skimming/ref_db

# usage: ./create_sample_list.sh $1 $2 $3
# $1 = path to the folder that contains the R1 and R2 fastq.gz files (raw data)
# $2 = path to the seed file (reference genome db)
# $3 = path to the gene file (reference genome db)
#
# example: ./create_sample_list_BGE.sh \
# /data/dick.groenenberg/genome_skimming_pipeline/input/156494/raw_sequences \
# /data/dick.groenenberg/genome_skimming_pipeline/ref_db/hymenoptera_db/seed.fasta \
# /data/dick.groenenberg/genome_skimming_pipeline/ref_db/hymenoptera_db/gene.fasta

# outfile name
tempfile=tempfile.txt
tempfile2=tempfile2.txt
tempfile3=tempfile3.txt
outfile=sample_list.csv

# test if temp- and outfiles exist; exit if they do, create them if they don't exit
if [[ -e "$tempfile" || -e "$tempfile2" || -e "$outfile" ]]; then
	printf "script terminated:\n tempfile(s) or sample_list.csv already exist\n" && exit 1
else
	touch "$tempfile" "$tempfile2" "$tempfile3" "$outfile"
fi

# put forward and reverse in tempfile (files are selected based on not having "empty" in their name)
ls -1 "$1"/*.gz | egrep -v "empty" | awk -F"genome_skimming_pipeline/" '{print $2}' | sed 'N;s/\(.*\)\n\(.*\)/\1,\2/' > "$tempfile"

# add seed and gene dbs (tempfile2)
seed=$(echo "$2" |  awk -F"genome_skimming_pipeline/" '{print $2}')
gene=$(echo "$3" |  awk -F"genome_skimming_pipeline/" '{print $2}')
while read line; do
    printf "$line,$seed,$gene\n" >> "$tempfile2"
done < $tempfile

# extract ID (tempfile3)
awk -F"raw_sequences/" '{print $2}' "$tempfile2"| awk -F"_" '{print $1"_"$2"_"$3}' > "$tempfile3"

# merge tempfile3 and tempfile2
paste -d"," "$tempfile3" "$tempfile2" > "$outfile"

# add header
awk -i inplace 'BEGINFILE{print "ID,forward,reverse,seed,gene"}{print}' "$outfile"

# warn if ID (tempfile3) contains duplicates!
cat "$tempfile3" | sort -n | uniq -c | awk '{if ($1 > 1) print "\nDuplicate ID(s) detected!"; exit 1}'
cat "$tempfile3" | sort -n | uniq -c | awk '{if ($1 > 1) print $2}'

# remove tempfiles
rm "$tempfile" "$tempfile2" "$tempfile3"
