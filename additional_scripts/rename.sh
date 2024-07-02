#!/usr/bin/env bash

# this script replaces filenames based on a two column 
# tab separated file (old_name new_name)
#
# usage: ./rename.sh $1
# where $1 is the two column file (old_new.txt)
#
# requirements: rename


# create associative array based on $1
declare -A index_array
while read index name
do
	index_array[$index]=$name
done < $1

for item in "${!index_array[@]}"; do
  value="${index_array[$item]}"
  # echo "$item --> $value"
  # rename "s/$item/$value/g" *gz
  rename "s/$item/$value/g" *
done
