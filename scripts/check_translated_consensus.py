import logging
from pathlib import Path
import os
from Bio import SeqIO

# setup the logging
logger = logging.getLogger('logging')
fh = logging.FileHandler(str(snakemake.log[0]))
fh.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
fh.setFormatter(formatter)
logger.addHandler(fh)

try:
    # parse only samples translated
    with open(snakemake.output[0], 'a') as fw:
        # snakemake.input.trans_cons_files is a list of file paths
        for trans_file in os.listdir(snakemake.input[0]):
            if trans_file[0] == ".":
                continue
            trans_file = os.path.join(snakemake.input[0], trans_file)
            marker = Path(trans_file).stem
            valid_prot = False
            with open(trans_file, 'r') as fh:
                # parse the 6 sequences (6 frames) in the current fasta
                for record in SeqIO.parse(fh, "fasta"):
                    sample_id = record.id.split(";")[0]
                    if len(record.seq) != 0 and '*' not in str(record.seq):
                        valid_prot = True
                        break  # stop if one is valid
            fw.write(f"{sample_id}\t{marker}\t{valid_prot}\n")
except Exception as e:
    print(e)
    logger.error(e, exc_info=True)
    exit(1)