#!/bin/bash

# get abbreviated lineage and species for taxid
# results are tab separated (no headers because of subsequent use in blast2pident.sh)
# usage:    taxid2ablin.sh $1=taxid
# example:  taxid2ablin.sh 649475
# requirement: Entrez Direct (efetch)

#taxid=$1
result=$(efetch -db taxonomy -id $1 -format xml)
order=$(echo "$result" | egrep -m1 -B1 "<Rank>order</Rank>" | head -n1 | awk -F"</" '{print $1}' | awk -F">" '{print $2}')
family=$(echo "$result" | egrep -m1 -B1 "<Rank>family</Rank>" | head -n1 | awk -F"</" '{print $1}' | awk -F">" '{print $2}')
genus=$(echo "$result" | egrep -m1 -B1 "<Rank>genus</Rank>" | head -n1 | awk -F"</" '{print $1}' | awk -F">" '{print $2}')
species=$(echo "$result" | egrep -m1 "<ScientificName>" | head -n1 | awk -F"</" '{print $1}' | awk -F">" '{print $2}')
lineage=$(echo "$result" | egrep "<Lineage>" | awk -F"</" '{print $1}' | awk -F">" '{print $2}')

printf "$1\t$order\t$family\t$genus\t$species\t$lineage\n"



