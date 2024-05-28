#!/usr/bin/env python

import sys
import csv
import os
from Bio import Entrez
from pathlib import Path

def fetch_taxid(taxon_name, taxonomic_rank):
    try:
        term = f"{taxon_name}[{taxonomic_rank}]"
        handle = Entrez.esearch(db="taxonomy", term=term)
        record = Entrez.read(handle)
        handle.close()
        if record['IdList']:
            return record['IdList'][0]
        else:
            return None
    except Exception as e:
        print(f"Error fetching TaxID for {taxon_name} ({taxonomic_rank}): {e}")
        return None

def main(input_file):
    Entrez.email = "dickgroenenberg@gmail.com"  # Add your email for NCBI API usage

    # Generate output file name based on input file name
    # the slice [2:] is used to convert 0.input to 2.output
    output_file = "2." + os.path.basename(input_file)[2:] + "_taxid_rank.csv"
    
    with open(input_file, 'r') as infile, open(output_file, 'w', newline='') as outfile:
        reader = csv.DictReader(infile)  # Read input as a dictionary
        fieldnames = reader.fieldnames + ["taxid", "matched_rank"]  # Add taxid and matched_rank columns
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()

        rownumber = 0

        unique_taxids = set()  # To store unique TaxIDs

        for row in reader:
            species_name = row.get("Species")
            genus_name = row.get("Genus")
            family_name = row.get("Family")
            order_name = row.get("Order")

            rownumber += 1
            perc = round(rownumber / 0.95, 1)
            print("Fetching taxonomy for ", rownumber, " of 95 \t(", perc, " %)")

            matched_rank = None  # Initialize matched rank

            if species_name:
                species_taxid = fetch_taxid(species_name, 'species')
                if species_taxid:
                    row["taxid"] = species_taxid
                    matched_rank = "species"
                    unique_taxids.add(species_taxid)

            if not matched_rank and genus_name:
                genus_taxid = fetch_taxid(genus_name, 'genus')
                if genus_taxid:
                    row["taxid"] = genus_taxid
                    matched_rank = "genus"
                    unique_taxids.add(genus_taxid)

            if not matched_rank and family_name:
                family_taxid = fetch_taxid(family_name, 'family')
                if family_taxid:
                    row["taxid"] = family_taxid
                    matched_rank = "family"
                    unique_taxids.add(family_taxid)

            if not matched_rank and order_name:
                order_taxid = fetch_taxid(order_name, 'order')
                if order_taxid:
                    row["taxid"] = order_taxid
                    matched_rank = "order"
                    unique_taxids.add(order_taxid)

            row["matched_rank"] = matched_rank
            writer.writerow(row)

    # Write unique TaxIDs to a separate file
    input_filename = Path(input_file).stem  # Get the filename without extension
    unique_taxids_file = "3." + os.path.basename(input_file)[2:] + "_unique_taxids.txt"
    with open(unique_taxids_file, 'w') as unique_file:
        for taxid in unique_taxids:
            unique_file.write(f"{taxid}\n")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py input_file.csv")
    else:
        main(sys.argv[1])
