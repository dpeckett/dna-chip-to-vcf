#!/bin/sh
set -e

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

usage() {
  log "Usage: $0 -o output_file.vcf.gz [-d data_dir] -f input_format input_file.txt"
  log "input_format: AncestryDNA or 23andMe"
  exit 1
}

# Parse command line arguments.
data_dir="./data"
while getopts ":o:d:f:" opt; do
  case $opt in
    o) output_file="$OPTARG"
    ;;
    d) data_dir="$OPTARG"
    ;;
    f) input_format="$OPTARG"
    ;;
    \?) log "Invalid option -$OPTARG" >&2
      usage
    ;;
    :) log "Option -$OPTARG requires an argument." >&2
      usage
    ;;
  esac
done

shift $((OPTIND -1))

input_file="$1"

# Validate inputs.
if [ -z "$output_file" ] || [ -z "$input_format" ] || [ -z "$input_file" ]; then
  usage
fi

if [ "$input_format" != "AncestryDNA" ] && [ "$input_format" != "23andMe" ]; then
  log "Invalid input format. Must be AncestryDNA or 23andMe."
  usage
fi

# Create a temporary directory for working files.
work_dir=$(mktemp -d)
log "Using work directory: $work_dir"

# Ensure the temporary directory is deleted on script exit.
cleanup() {
  log "Cleaning up work directory"
  rm -rf "$work_dir"
}
trap cleanup EXIT

log "Input format: $input_format"
log "Input file: $input_file"

if [ "$input_format" = "AncestryDNA" ]; then
  log "Mapping AncestryDNA chromosomes 23 and 24 to X and Y"
  awk 'NR>1 {
    if ($2 == 23) $2 = "X";
    else if ($2 == 24) $2 = "Y";
    print $1, $2, $3, $4$5
  }' "$input_file" > "$work_dir/dna.23andme"
elif [ "$input_format" = "23andMe" ]; then
  log "Copying 23andMe input file"
  cp "$input_file" "$work_dir/dna.23andme"
fi

log "Converting to VCF format"
bcftools convert -c ID,CHROM,POS,AA -s SampleName -f "$data_dir/Homo_sapiens.GRCh37.dna.primary_assembly.fa" --tsv2vcf "$work_dir/dna.23andme" -Ov -o "$work_dir/dna.vcf"
rm "$work_dir/dna.23andme"

log "Filtering out entries that match the reference genome"
bcftools view -f '.,PASS' -i 'GT!="0/0"' "$work_dir/dna.vcf" -Ov -o "$work_dir/dna_diff.vcf"
rm "$work_dir/dna.vcf"

log "Lifting over to the updated GRCh38 reference genome"
CrossMap vcf "$data_dir/hg19ToHg38.over.chain.gz" "$work_dir/dna_diff.vcf" "$data_dir/Homo_sapiens.GRCh38.dna.primary_assembly.fa" "$work_dir/dna_GRCh38.vcf"
rm "$work_dir/dna_diff.vcf"

log "Renaming chromosomes"
awk 'BEGIN {
  for (i = 1; i <= 22; i++) {
    print i "\tchr" i
  }
  print "X\tchrX"
  print "Y\tchrY"
  print "MT\tchrMT"
}' > "$work_dir/chr_rename.txt"

bcftools annotate --rename-chrs "$work_dir/chr_rename.txt" "$work_dir/dna_GRCh38.vcf" -Ov -o "$work_dir/dna_GRCh38_chr.vcf"
mv "$work_dir/dna_GRCh38_chr.vcf" "$work_dir/dna_GRCh38.vcf"

log "Sorting VCF entries by position"
bcftools sort "$work_dir/dna_GRCh38.vcf" -Ov -o "$work_dir/dna_GRCh38_sorted.vcf"
mv "$work_dir/dna_GRCh38_sorted.vcf" "$work_dir/dna_GRCh38.vcf"

log "Compressing and indexing the VCF file"
bgzip "$work_dir/dna_GRCh38.vcf"
tabix "$work_dir/dna_GRCh38.vcf.gz"

log "Moving the final output to the specified location"
mv "$work_dir/dna_GRCh38.vcf.gz" "$output_file"
mv "$work_dir/dna_GRCh38.vcf.gz.tbi" "${output_file}.tbi"

log "Processing complete"
