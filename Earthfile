VERSION 0.8
FROM debian:bookworm
WORKDIR /workspace

test:
  RUN apt update
  RUN apt install -y python3 python3-pip python3-venv
  RUN apt install -y bcftools tabix
  COPY . .
  RUN python3 -m venv venv \
    && . venv/bin/activate \
    && pip install -r requirements.txt
  RUN ./download-references.sh
  RUN mkdir results
  RUN . venv/bin/activate \
    && gunzip testdata/AncestryDNA.txt.gz \
    && ./dna-chip-to-vcf.sh -o results/genome.vcf.gz -f AncestryDNA testdata/AncestryDNA.txt
  SAVE ARTIFACT results/* AS LOCAL ./results/