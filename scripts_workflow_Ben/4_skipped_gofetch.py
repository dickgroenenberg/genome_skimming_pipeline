#!/usr/bin/env python

import os
import sys

def check_files(target_path):
    skipped_folders = set()  # Use a set to store unique folder names

    # Iterate through all folders in the target path
    for folder_name in os.listdir(target_path):
        folder_path = os.path.join(target_path, folder_name)

        # Check if it's a directory (ignore files)
        if os.path.isdir(folder_path):
            # Check if "gene.fasta" is missing in the folder
            if not os.path.exists(os.path.join(folder_path, "gene.fasta")):
                skipped_folders.add(folder_name)

            # Check if "seed.fasta" is missing in the folder
            if not os.path.exists(os.path.join(folder_path, "seed.fasta")):
                skipped_folders.add(folder_name)

    # Write unique skipped folder names to the output file
    with open("6.skip_gofetch.txt", "w") as output_file:
        for folder_name in skipped_folders:
            output_file.write(folder_name + "\n")

    print(f"Unique skipped folders written to 'skip_gofetch.txt'.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script_name.py <target_directory>")
        sys.exit(1)

    target_directory = sys.argv[1]
    check_files(target_directory)
