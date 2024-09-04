#!/usr/bin/env python

import sys
import os
import pandas as pd

def add_seed_and_gene(input_file1, input_file2):
    # Read data from both CSV files
    df1 = pd.read_csv(input_file1)
    df2 = pd.read_csv(input_file2)

    # Merge dataframes based on matching "ID" and "Process ID"
    merged_df = pd.merge(df1, df2, left_on="ID", right_on="Process ID", how="inner")

    # Add new columns "seed" and "gene"
    # in our setup this needs to be changed: /ref_db/BGE#####
    bge_number = input_file1.split("_")[0].split('.')[1]
    print(f"bge_number: {bge_number}")
    merged_df["seed"] = "ref_db/" + bge_number + "/" + merged_df["taxid"].astype(str) + "/seed.fasta"
    # test_seed = "ref_db/" + bge_number + "/" + merged_df["taxid"].astype(str) + "/seed.fasta"
    # print(f"seed: {test_seed}")
    merged_df["gene"] = "ref_db/" + bge_number + "/" + merged_df["taxid"].astype(str) + "/gene.fasta"
    # test_gene = "ref_db/" + bge_number + "/" + merged_df["taxid"].astype(str) + "/gene.fasta"
    # print(f"gene: {test_gene}")

    # Select only the desired columns
    # selected_columns = ["Sample_ID", "forward", "reverse", "seed", "gene"]
    selected_columns = ["Sample ID", "forward", "reverse", "seed", "gene"]
    merged_df = merged_df[selected_columns]

    # Get the directory and filename from input_file1
    output_dir, input_filename = os.path.split(input_file1)
    # output_filename = "4." + os.path.splitext(input_filename)[0] + "_merged.csv"
    output_filename = "4." + os.path.basename(input_file1)[2:] + "_merged.csv"
    output_path = os.path.join(output_dir, output_filename)

    # Write the merged dataframe to the output CSV file
    merged_df.to_csv(output_path, index=False)
    print(f"Output written to {output_path}")

# file1.csv = 1.BGE00###_folder2csv_out.csv
# file2.csv = 2.BGE00###.csv_taxid_rank.csv

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py file1.csv file2.csv")
    else:
        input_file1, input_file2 = sys.argv[1], sys.argv[2]
        add_seed_and_gene(input_file1, input_file2)
