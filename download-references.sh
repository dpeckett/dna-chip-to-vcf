#!/bin/sh
set -e

mkdir -p data

# Reference genomes.
if [ ! -f data/Homo_sapiens.GRCh37.dna.primary_assembly.fa ]; then
  echo 'Downloading GRCh37 reference genome ...'
  
  curl -fL -o data/Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz ftp://ftp.ensembl.org/pub/grch37/current/fasta/homo_sapiens/dna/Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz
  gunzip data/Homo_sapiens.GRCh37.dna.primary_assembly.fa.gz
fi

if [ ! -f data/Homo_sapiens.GRCh38.dna.primary_assembly.fa ]; then
  echo 'Downloading GRCh38 reference genome ...'

  curl -fL -o data/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz ftp://ftp.ensembl.org/pub/current/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
  gunzip data/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
fi

# For converting between GRCh37/hg19 and GRCh38/hg38.
if [ ! -f data/hg19ToHg38.over.chain.gz ]; then
  echo 'Downloading GRCh37 to GRCh38 liftOver chain ...'

  curl -fL -o data/hg19ToHg38.over.chain.gz http://hgdownload.cse.ucsc.edu/goldenpath/hg19/liftOver/hg19ToHg38.over.chain.gz
fi