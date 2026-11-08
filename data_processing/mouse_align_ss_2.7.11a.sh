#!/bin/bash
#SBATCH --job-name=ss_mm_comp
#SBATCH --output=ss_mm_comp.out
#SBATCH --ntasks=12
#SBATCH --time=48:00:00
#SBATCH --mem-per-cpu=50GB
#SBATCH --partition=ncpu
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=marcin.falis@crick.ac.uk

echo start

date

# Loading star 2.7.11a
ml purge
ml STAR/2.7.11a-GCC-12.3.0

# Defining variables
GENOME_INDEX=/camp/home/falism/Scratch_MF/sc_Mm/ref_files/SS_Mm_GRCm39_r104/
FASTA_GENOME=/camp/home/falism/Scratch_MF/sc_Mm/ref_files/Mus_musculus.GRCm39.dna.toplevel.fa
GTF=/camp/home/falism/Scratch_MF/sc_Mm/ref_files/Mus_musculus.GRCm39.104.gtf
MULTIMAP_SETTING=EM
MIN_FILT_SCORE=30
OUT=/camp/home/falism/Scratch_MF/sc_Mm/aln/

# Indexing the genome
STAR --runThreadN 4 \
--runMode genomeGenerate \
--genomeDir $GENOME_INDEX \
--genomeFastaFiles $FASTA_GENOME \
--sjdbGTFfile $GTF \
--limitGenomeGenerateRAM=35183220320

# Loading the genome and keeping it
STAR --genomeDir $GENOME_INDEX --genomeLoad LoadAndExit

# Alignment and counting (STARsolo)
for i in {COL3351A26,COL3351A27,COL3351A40,COL3351A5,SN123,SN132,SN139,SN185,SN186,SN215,SN216,SN242,SN307,SN337,SN339,SN356,SN362,SN363,SN365};
do STAR --runThreadN 12 \
--genomeLoad LoadAndKeep \
--runMode alignReads \
--readFilesCommand zcat \
--outSAMtype BAM SortedByCoordinate \
--genomeDir $GENOME_INDEX \
--soloType CB_UMI_Simple \
--soloCBwhitelist /camp/home/falism/Scratch_MF/sc_Oa/ref_files/3M-february-2018.txt \
--soloUMIlen 12 \
--soloFeatures Gene GeneFull \
--soloMultiMappers $MULTIMAP_SETTING \
--outFileNamePrefix $OUT/${i}_SS/ \
--outSAMattributes NH HI nM AS CR UR CB UB GX GN sS sQ sM \
--clipAdapterType CellRanger4 \
--outFilterScoreMin $MIN_FILT_SCORE \
--soloCBmatchWLtype 1MM_multi_Nbase_pseudocounts \
--soloUMIfiltering MultiGeneUMI_CR \
--soloUMIdedup 1MM_CR \
--limitBAMsortRAM 40000000000 \
--readFilesIn $(echo /camp/home/falism/Scratch_MF/sc_Mm/fastq/${i}/*R2* | sort -u | tr ' ' ,) \
$(echo /camp/home/falism/Scratch_MF/sc_Mm/fastq/${i}/*R1* | sort -u | tr ' ' ,) ;
done

#Removing the genome
STAR --genomeLoad Remove --genomeDir $GENOME_INDEX

echo finished

date
