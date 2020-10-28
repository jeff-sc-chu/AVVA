# Analysis of Variations Via Assembly (AVVA)

AVVA is a suit of tools to call structural variations from contig-assembly or assembly-assembly alignments. The current version is only specific for alignment using MUMer (https://mummer4.github.io/). The workflow generally follows:
1. Run MUMer
2. Run AVVA
3. Filter

## Running MUMer

MUMer can be downloaded from https://mummer4.github.io/. One will need to understand the alignment needs of your project to select the proper settings. In the case of contig-assembly alignment, I have typically used:

`nucmer --mum -l 100 -c 500 reference_genome contig_sequence > aln.delta`

`delta-filter -q aln.delta > aln.qdelta`

`show-coords -cdHlqT aln.qdelta > aln.qqcoords`

## Running AVVA
AVVA takes query sorted coord file from MUMer and look for alignment breaks to call inversions and translocations. Larger insertions and deletions are not called. For these variants, please consider show-diff from MUMer or Assemblytics (https://github.com/MariaNattestad/assemblytics). 

`perl avva.pl -T Categorize -i aln.qqcords > output.SV`

#### AVVA output

The output is a tab delimited file with the following columns:
1. query contig ID
2. Complex, Simple, or Contigous. Simple is when there is only one SV signal on the contig; Complex when there is >1 SV signal on the contig; Contigous when there isn't any SV signal. Note: only inversions and translocations are considered as SV here. 
3. Number of SV signals
4. SV type: Inv = Inversion; Tn = Inter-chromosomal translocation; Tr = Intra-chromosomal translocation 
5. SV breakpoints on the reference
6. Alignment blocks before and after the SV signal on the reference
7. Alignment blocks before and after the SV signal on the query

## Filtering AVVA SV output

There are many ways to filter this output. One may consider filtering SVs near assembly gaps, or filter SVs found in a control sample, or filter SVs found in a VCF file. This is what avva_filter.pl attemps to do.

    Filter SV events from AVVA

        -T <Int>        Task:
                FilterRefContig:        Filter restuls of Categorize with a reference event set
                FilterGap:      Filter events bordering gaps
                FilterVCF:      Filter with a Illumina/PacBio Call set
        -i <File>       Output file from avva.pl to be filtered
        -j <File>       Output file from avva.pl to be used a reference
        -g <File>       GapInfo file
        -k [Bool]       Keep filtered results (1) or remove filtered results (default, or 0).
        -h [Bool]       Help. Show this and exits.

#### Preparing GapInfo file
GapInfo file is a tab delimited two column file describing where the gaps are in the reference genome. The format is as follows:
Column 1. Chromosome:Start-End

Column 2. Gap_size

