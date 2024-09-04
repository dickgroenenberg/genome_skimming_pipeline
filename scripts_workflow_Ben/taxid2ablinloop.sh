#!/bin/bash

# this script will retrieve abbreviated lineage information
# for a file of taxids ("unique_taxids" from sample2taxid.py
# as part of the go_fetch or batch_go_fetch workflow)
#
# run taxid2ablin.sh for each taxid in "unique_taxids" file ($1)
# usage: ./taxid2ablinloop.sh $1
# dependency: taxid2ablin.sh (and thus Eutils)

# Specify the name of the output file
outfile="lineage_$1"

# Check if the output file already exists
if [ -f "$outfile" ]; then
    echo "Output file already exists. Aborting."
    exit 1
else
    # If the output file doesn't exist, create it
    touch "$outfile"
    echo "Output file created: $outfile"
fi

count=0
while IFS= read -r line; do
    ((count++))
    taxids=$(wc -l $1 | awk '{print $1}')
    # Process each line here
    # echo "Line $count: $line"
    lineage=$(taxid2ablin.sh $line)
    printf "Passed taxid:\t$count\tof $taxids\n"
    printf "$count\t$lineage\n" >> $outfile
done < "$1"