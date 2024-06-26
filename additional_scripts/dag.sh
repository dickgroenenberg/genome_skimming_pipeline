#!/bin/bash

source activate genome_skimming_pipeline

snakemake \
   --configfile config/config_example.yaml \
   --dag results_example/summary/summary_contig.txt | dot -Tpdf > dag_part1.pdf

snakemake \
   --configfile config/config_example.yaml \
   --dag results_example/snakemake.ok | dot -Tpdf > dag_part2.pdf

echo Complete!

