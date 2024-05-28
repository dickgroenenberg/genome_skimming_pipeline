set -e

output_dir=$1
wildcards_sample=$2
output_ok=$3

# find selected path(s) fasta
FAS=$(find ${output_dir}/getorganelle/${wildcards_sample}/ -name *path_sequence.fasta | head)
echo "FAS variable before if statement"
echo $FAS
# z option: true if length if string is zero.
if [ -z "$FAS" ]; then
    echo No assembly produced for ${wildcards_sample}
    echo No assembly produced
# more than one selected path
elif [ "$(echo $FAS | tr ' ' '\n' | wc -l)" -gt 1 ]; then
    echo TEST
    echo $FAS
    FAS1="$(echo $FAS | tr ' ' '\n' | head -n 1)"
    echo TEST2
    echo $FAS1
    echo More than one assembly produced for ${wildcards_sample}
    echo Selecting the first assembly $FAS1
    python scripts/rename_assembled.py --input $FAS1 --sample ${wildcards_sample} --output ${output_dir}/assembled_sequence
elif [ "$(echo $FAS | tr ' ' '\n' | wc -l)" -eq 1 ]; then
    echo One assembly produced for ${wildcards_sample}
    python scripts/rename_assembled.py --input $FAS --sample ${wildcards_sample} --output ${output_dir}/assembled_sequence
fi
touch ${output_ok}
