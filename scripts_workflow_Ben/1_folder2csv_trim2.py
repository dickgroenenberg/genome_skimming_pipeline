#!/usr/bin/env python

import os
import csv
import sys

def find_files(folder_path):
    # Initialize a dictionary to store the results
    results = {}

    # Walk through the subfolders
    for root, _, files in os.walk(folder_path):
        r1_path, r2_path = None, None
        for filename in files:
            if "_R1_" in filename:
                r1_path = os.path.join(root, filename)
            elif "_R2_" in filename:
                r2_path = os.path.join(root, filename)

        if r1_path and r2_path:
            subfolder_name = os.path.basename(root)
            # Remove the first 15 characters from the subfolder name
            subfolder_name = subfolder_name[15:]
            results[subfolder_name] = (r1_path, r2_path)

    return results

def write_to_csv(results, output_filename):
    with open(output_filename, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['ID', 'forward', 'reverse'])
        for subfolder, (r1_path, r2_path) in results.items():
            writer.writerow([subfolder, r1_path, r2_path])

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <main_folder_path>")
        sys.exit(1)

    main_folder_path = sys.argv[1]
    output_filename = "1." + os.path.basename(main_folder_path) + "_folder2csv_out.csv"

    files_info = find_files(main_folder_path)
    write_to_csv(files_info, output_filename)
    print(f"CSV file '{output_filename}' created successfully.")
