#!/bin/bash
#SBATCH --partition=day
#SBATCH --output=job_go_fetch_%j_%a.out
#SBATCH --error=job_go_fetch_%j_%a.err
#SBATCH --mem-per-cpu=1G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-104%1

TAXID=$(sed -n ${SLURM_ARRAY_TASK_ID}p BGE0000100002_samples_unique_taxids.txt)

source activate go_fetch

mkdir -p go_fetch_output

# mitochondrion
python3 /home/benjp/software/go_fetch/go_fetch.py \
   --taxonomy ${TAXID} \
   --target mitochondrion \
   --db genbank \
   --min 5 --max 20 \
   --output go_fetch_output/${TAXID} \
   --overwrite \
   --getorganelle \
   --email ben.wills.price@gmail.com > go_fetch_output/log_${TAXID}.txt

echo Complete!

