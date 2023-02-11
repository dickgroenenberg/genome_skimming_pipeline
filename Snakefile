import pandas as pd

# set configfile
configfile: "config/config.yaml"

# configfile parameters
target_type = config["target_type"]
output_dir = config["output_dir"]
blast_db = config["blast_db"]
taxdump = config["taxdump"]
mitos_refseq = config["mitos_refseq"]
mitos_code = config["mitos_code"]
barrnap_kingdom = config["barrnap_kingdom"] 
threads = config["threads"]

# read sample data
sample_data = pd.read_csv(config["samples"]).set_index("ID", drop=False)

# functions to get forward and reverse reads from sample data
def get_forward(wildcards):
    return sample_data.loc[wildcards.sample, "forward"]

def get_reverse(wildcards):
    return sample_data.loc[wildcards.sample, "reverse"]

def get_seed(wildcards):
    return sample_data.loc[wildcards.sample, "seed"]

def get_gene(wildcards):
    return sample_data.loc[wildcards.sample, "gene"]

# one rule to rule them all :)
rule all:
    input:
        output_dir+"/summary/summary_sample.txt",
        output_dir+"/summary/summary_contig.txt",
        output_dir+"/snakemake.ok"        
       
# convert fastq to fasta
rule fastp:
    input:
        fwd = get_forward,
        rev = get_reverse
    output:
        fwd = output_dir+"/fastp/{sample}_R1.fq.gz",
        rev = output_dir+"/fastp/{sample}_R2.fq.gz",
        html = output_dir+"/fastp/{sample}.html",
        json = output_dir+"/fastp/{sample}.json"
    log:
        output_dir+"/logs/fastp/{sample}.log"
    conda:
        "envs/fastp.yaml"
    threads: threads
    shell:
        """
        fastp --in1 {input.fwd} --in2 {input.rev} \
            --out1 {output.fwd} --out2 {output.rev} \
            --html {output.html} --json {output.json} \
            --disable_quality_filtering \
            --thread {threads} &> {log}
        """

rule getorganelle:
    input:
        fwd = output_dir+"/fastp/{sample}_R1.fq.gz",
        rev = output_dir+"/fastp/{sample}_R2.fq.gz"
    params:
        seed = get_seed,
        gene = get_gene
    output:
        ok = output_dir+"/getorganelle/{sample}/getorganelle.ok"
    log:
        output_dir+"/logs/getorganelle/{sample}.log"
    conda:
        "envs/getorganelle.yaml"
    threads: threads
    shell:
        """
        if [[ {target_type} == "animal_mt" || {target_type} == "embplant_cp" ]]; then 
            get_organelle_from_reads.py \
                -1 {input.fwd} -2 {input.rev} \
                -o {output_dir}/getorganelle/{wildcards.sample} \
                -F {target_type} \
                -s {params.seed} \
                --genes {params.gene} \
                --reduce-reads-for-coverage inf --max-reads inf \
                -R 20 \
                --overwrite -t {threads} &> {log}
        else 
            if [ {target_type} == "anonym" ]; then
                get_organelle_from_reads.py \
                    -1 {input.fwd} -2 {input.rev} \
                    -o {output_dir}/getorganelle/{wildcards.sample} \
                    -F {target_type} \
                    -s {params.seed} \
                    --genes {params.gene} \
                    --reduce-reads-for-coverage inf --max-reads inf \
                    -R 10 \
                    --max-extending-len 100 \
                    -P 0 \
                    --overwrite -t {threads} &> {log}
            fi
        fi
        touch {output.ok}
        """

rule assembled_sequence:
    input:
        output_dir+"/getorganelle/{sample}/getorganelle.ok"
    output:
        ok = output_dir+"/assembled_sequence/{sample}.ok"
    log:
        output_dir+"/logs/assembled_sequence/{sample}.log"
    shell:
        """
        # find selected path(s) fasta
        FAS=$(find {output_dir}/getorganelle/{wildcards.sample}/ -name *path_sequence.fasta)
        # z option: true if length if string is zero.
        if [[ -z $FAS ]]; then
            echo No assembly produced for {wildcards.sample} > {log}
        # more than one selected path
        elif [ "$(echo $FAS | tr ' ' '\\n' | wc -l)" -gt 1 ]; then
            FAS1=$(echo $FAS | tr ' ' '\\n' | head -n 1)
            echo More than one assembly produced for {wildcards.sample} > {log}
            echo Selecting the first assembly $FAS1 > {log}
            sed 's/>/>{wildcards.sample};/g' $FAS1 | awk NF > {output_dir}/assembled_sequence/{wildcards.sample}.fasta
        elif [ "$(echo $FAS | tr ' ' '\\n' | wc -l)" -eq 1 ]; then
            echo One assembly produced for {wildcards.sample} > {log}
            sed 's/>/>{wildcards.sample};/g' $FAS  | awk NF > {output_dir}/assembled_sequence/{wildcards.sample}.fasta
        fi
        touch {output.ok}
        """

rule seqkit:
    input:
        output_dir+"/assembled_sequence/{sample}.ok"
    output:
        ok = output_dir+"/seqkit/{sample}.ok"
    log:
        output_dir+"/logs/seqkit/{sample}.log"
    conda:
        "envs/seqkit.yaml"
    shell:
        """
        FAS=$(echo {output_dir}/assembled_sequence/{wildcards.sample}.fasta)
        OUT=$(echo {output_dir}/seqkit/{wildcards.sample}.txt)
        if [ -e $FAS ]; then
            echo Running seqkit for {wildcards.sample} > {log}
            seqkit stats -b $FAS > $OUT
        else
            echo No assembled sequence for {wildcards.sample} > {log}
        fi
        touch {output.ok}
        """

rule blastn:
    input: 
        output_dir+"/assembled_sequence/{sample}.ok"
    output:
        ok = output_dir+"/blastn/{sample}.ok"
    log:
        output_dir+"/logs/blastn/{sample}.log"
    conda:
        "envs/blastn.yaml"
    shell:
        """
        FAS=$(echo {output_dir}/assembled_sequence/{wildcards.sample}.fasta)
        OUT=$(echo {output_dir}/blastn/{wildcards.sample}.txt)
        if [ -e $FAS ]; then
            echo Running blastn for {wildcards.sample} > {log}
            blastn \
                -query $FAS \
                -db {blast_db} \
                -out $OUT \
                -outfmt '6 qseqid staxids bitscore std' \
                -max_target_seqs 10 -max_hsps 1 -evalue 1e-25 &> {log} 
        else
            echo No assembled sequence for {wildcards.sample} > {log}
        fi
        touch {output.ok}
        """

rule minimap:
    input:
        output_dir+"/assembled_sequence/{sample}.ok",
        fwd = output_dir+"/fastp/{sample}_R1.fq.gz",
        rev = output_dir+"/fastp/{sample}_R2.fq.gz"
    output:
        ok = output_dir+"/minimap/{sample}.ok"
    log:
        output_dir+"/logs/minimap/{sample}.log"
    conda:
        "envs/minimap2.yaml"
    shell:
        """
        FAS=$(echo {output_dir}/assembled_sequence/{wildcards.sample}.fasta)
        OUT=$(echo {output_dir}/minimap/{wildcards.sample}.bam)
        if [ -e $FAS ]; then
            echo Running minimap for {wildcards.sample} > {log}
            minimap2 -ax sr $FAS {input.fwd} {input.rev} 2> {log} | samtools sort -O BAM -o $OUT - 2> {log}
        else
            echo No assembled sequence for {wildcards.sample} > {log}
        fi
        touch {output.ok}
        """

# need to have taxdump in same dir 
rule blobtools:
    input:
        output_dir+"/assembled_sequence/{sample}.ok",
        output_dir+"/blastn/{sample}.ok",
        output_dir+"/minimap/{sample}.ok"
    output:
        ok = output_dir+"/blobtools/{sample}/{sample}.ok"
    log:
        output_dir+"/logs/blobtools/{sample}.log"
    container:
        "docker://genomehubs/blobtoolkit"
    shell:
        """
        FAS=$(echo {output_dir}/assembled_sequence/{wildcards.sample}.fasta)
        BLA=$(echo {output_dir}/blastn/{wildcards.sample}.txt)
        MAP=$(echo {output_dir}/minimap/{wildcards.sample}.bam)
        OUT=$(echo {output_dir}/blobtools/{wildcards.sample}/table.tsv)
        if [ -e $FAS ]; then            
            blobtools create \
                --fasta $FAS \
                --hits $BLA \
                --taxrule bestsumorder \
                --taxdump {taxdump} \
                --cov $MAP \
                {output_dir}/blobtools/{wildcards.sample} &> {log}
            blobtools filter \
                --table $OUT \
                --table-fields gc,length,{wildcards.sample}_cov,{wildcards.sample}_read_cov,bestsumorder_superkingdom,bestsumorder_kingdom,bestsumorder_phylum,bestsumorder_class,bestsumorder_order,bestsumorder_family,bestsumorder_species \
                {output_dir}/blobtools/{wildcards.sample} &> {log}
        else
            echo No assembled sequence for {wildcards.sample} > {log}
        fi
        touch {output.ok}
        """

# treats all assemblies as circular
rule annotations:
    input:
        output_dir+"/assembled_sequence/{sample}.ok"
    output:
        ok = output_dir+"/annotations/{sample}/{sample}.ok"
    log:
        output_dir+"/logs/annotations/{sample}.log"
    conda:
        "envs/annotations.yaml"
    shell:
        """
        FAS=$(echo {output_dir}/assembled_sequence/{wildcards.sample}.fasta)
        if [ -e $FAS ]; then
            if [[ {target_type} == "animal_mt" ]]; then
                runmitos.py \
                    --input $FAS \
                    --code {mitos_code} \
                    --outdir {output_dir}/annotations/{wildcards.sample}/ \
                    --refseqver {mitos_refseq} \
                    --refdir . \
                    --noplots &> {log}    
            else
                if [[ {target_type} == "anonym" ]]; then
                    barrnap \
                        --kingdom {barrnap_kingdom} \
                        --outseq {output_dir}/annotations/{wildcards.sample}/result.fas $FAS 1> {output_dir}/annotations/{wildcards.sample}/result.gff 2> {log}
                fi
            fi

        else
            echo No assembled sequence for {wildcards.sample} > {log}
        fi
        touch {output.ok}
        """

rule summarise:
    input: 
        expand(output_dir+"/seqkit/{sample}.ok", sample=sample_data["ID"].tolist()),
        expand(output_dir+"/blobtools/{sample}/{sample}.ok", sample=sample_data["ID"].tolist()),
        expand(output_dir+"/annotations/{sample}/{sample}.ok", sample=sample_data["ID"].tolist())    
    output:
        table_sample = output_dir+"/summary/summary_sample.txt",
        table_contig = output_dir+"/summary/summary_contig.txt"
    log:
        output_dir+"/logs/summarise/summarise.log"
    conda:
        "envs/r_env.yaml"
    shell:
        """
        # cat seqkit output for each sample
        echo -e "sample format type num_seqs sum_len min_len avg_len max_len" > {output_dir}/summary/tmp_summary_sample.txt
        cat {output_dir}/seqkit/*.txt | grep file -v >> {output_dir}/summary/tmp_summary_sample.txt
        column -t {output_dir}/summary/tmp_summary_sample.txt > {output.table_sample}
        rm {output_dir}/summary/tmp_summary_sample.txt
        
        # join blobtools with mitos annotations for each contig
        if [[ {target_type} == "animal_mt" ]]; then
            Rscript scripts/summarise.R {output_dir}/ mitos {output.table_contig} &> {log}
        else
            if [[ {target_type} == "anonym" ]]; then
                Rscript scripts/summarise.R {output_dir}/ barrnap {output.table_contig} &> {log}
            fi
        fi
        """

checkpoint extract_protein_coding_genes:
    input: 
        expand(output_dir+"/annotations/{sample}/{sample}.ok", sample=sample_data["ID"].tolist())
    output:
        directory(output_dir+"/protein_coding_genes/")
    log:
        output_dir+"/logs/protein_coding_genes/protein_coding_genes.log"
    shell:
        """
        if [[ {target_type} == "animal_mt" ]]; then
            python scripts/mitos_alignments.py {output_dir}/annotations/ {output_dir}/protein_coding_genes &> {log}
        else
            if [[ {target_type} == "anonym" ]]; then
                python scripts/barrnap_alignments.py {output_dir}/annotations/ {output_dir}/protein_coding_genes &> {log}
            fi
        fi
        """

rule mafft:
    input:
        output_dir+"/protein_coding_genes/{dataset}.fasta"
    output:
        output_dir+"/mafft/{dataset}.fasta"
    log:
        output_dir+"/logs/mafft/{dataset}.log"
    conda:
        "envs/alignments.yaml"
    shell:
        """
        mafft \
            --maxiterate 1000 \
            --localpair \
            --adjustdirection \
            {input} 1> {output} 2> {log}
        """

rule filter_alignments:
    input:
        output_dir+"/mafft/{dataset}.fasta"
    output:
        output_dir+"/mafft_filtered/{dataset}.fasta"
    log:
        output_dir+"/logs/mafft_filtered/{dataset}.log"
    shell:
        """
        python scripts/alignments_filter.py  --input {input} --output {output} --threshold 0.75 > {log}
        """

rule pasta:
    input:
        output_dir+"/mafft_filtered/{dataset}.fasta"
    output:
        cp = output_dir+"/pasta/{dataset}.fasta",
        al = output_dir+"/pasta/{dataset}.marker001.{dataset}.aln"
    log:
        output_dir+"/logs/pasta/{dataset}.log"
    conda:
        "envs/alignments.yaml"
    shell:
        """
        cp {input} {output.cp}
        PASTA_TOOLS_DEVDIR=$CONDA_PREFIX/bin/ run_pasta.py -i {output.cp} -j {wildcards.dataset} &> {log}
        """

rule gblocks:
    input:
        output_dir+"/pasta/{dataset}.marker001.{dataset}.aln"
    output:
        cp = output_dir+"/gblocks/{dataset}.fasta",
        gb = output_dir+"/gblocks/{dataset}.fasta-gb"
    log:
        output_dir+"/logs/gblocks/{dataset}.log"
    conda:
        "envs/gblocks.yaml"
    shell:
        """
        cp {input} {output.cp}
        # gblocks always gives error code of 1. Ignore.
        Gblocks {output.cp} -t=d &> {log} || true
        """

rule iqtree:
    input:
        output_dir+"/gblocks/{dataset}.fasta-gb"        
    output:
        output_dir+"/iqtree/{dataset}.contree",
        renamed = output_dir+"/iqtree/{dataset}.fasta"
    log:
        output_dir+"/logs/iqtree/{dataset}.log"
    conda:
        "envs/iqtree.yaml"
    shell:
        """
        # remove special characters from sample names
        sed -e 's/;/_/g' -e 's/+//g' -e 's/(//g' -e 's/)//g' -e 's/__/_/g' \
            {input} > {output.renamed}

        # iqtree
        iqtree -s {output.renamed} -B 1000 --prefix {output_dir}/iqtree/{wildcards.dataset} &> {log}
        """

rule plot_tree:
    input:
        output_dir+"/iqtree/{dataset}.contree"
    output:
        output_dir+"/plot_tree/{dataset}.png"
    log:
        output_dir+"/logs/plot_tree/{dataset}.log"
    conda:
        "envs/r_env.yaml"
    shell:
        """
        Rscript scripts/plot_tree.R {input} {output} &> {log}
        """

def get_plot_tree_output(wildcards):
    checkpoint_output = checkpoints.extract_protein_coding_genes.get(**wildcards).output[0]
    return expand(output_dir+"/plot_tree/{i}.png", i=glob_wildcards(os.path.join(checkpoint_output, "{i}.fasta")).i)

# create final log when complete 
rule final_log:
    input:
        get_plot_tree_output
    output:
        output_dir+"/snakemake.ok"
    shell:
        """
        touch {output}
        """


