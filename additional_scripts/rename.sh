#!/usr/bin/env bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

# Read the filename containing the old and new names
input_file="$1"

# Check if the file exists
if [ ! -f "$input_file" ]; then
    echo "Error: File '$input_file' not found!"
    exit 1
fi

# Read the file and process each line
while IFS=$'\t' read -r old_name new_name; do
    # Check if the old file exists
    if [ -f "$old_name" ]; then
        # Rename the file
        mv "$old_name" "$new_name"
        echo "Renamed '$old_name' to '$new_name'"
    else
        echo "Error: File '$old_name' not found!"
    fi
done < "$input_file"
