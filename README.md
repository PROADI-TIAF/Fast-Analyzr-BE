# Fast-Analyzr-BE: An automated tool for efficient base editing analysis in gene therapy
Fast Analyzer BE is an open-source tool designed to simplify and standardize base editing analysis. It supports both Adenine Base Editing (ABE) and Cytosine Base Editing (CBE), providing a complete pipeline from raw sequencing data to final results. The tool automates preprocessing, guide classification, haplotype detection, and visualization, ensuring consistent and reproducible outputs. With user-friendly scripts and R-based reports, Fast Analyzer BE enables researchers to accurately quantify and compare editing efficiencies across samples, making it a valuable resource for genome editing studies.
# Summary
Base editing technologies have revolutionized gene therapy by enabling precise correction of single-nucleotide mutations without inducing double-strand DNA breaks. Cytosine and adenine base editors (CBEs and ABEs) allow targeted conversions of C•G→T•A and A•T→G•C, respectively. The assessment of base editing outcomes, with high sensitivity and resolution, is typically performed using next-generation sequencing (NGS) of PCR amplicons—a method known as amplicon sequencing. This approach enables high-throughput analysis of multiple genomic targets at single-nucleotide resolution and is considered the gold standard for validating genome editing experiments.
Among the various post-NGS analysis software for genome editing, CRISPResso2 (https://github.com/pinellolab/CRISPResso2) is widely used. It integrates quality filtering, alignment, report generation, and precise quantification of results. CRISPResso2 provides comprehensive analysis of base editing efficiencies, detection of genomic insertions/deletions (indels), and a batch mode for comparing multiple experiments. However, this batch mode requires a strictly formatted input file, which can be a barrier for non-expert users. Additionally, it generates numerous output files (HTML reports, alignment tables, and frequency matrices), making data consolidation time-consuming and prone to errors.
To address these challenges, we developed FastAnalyzr BE, an automated tool that simplifies the quantification of base editing efficiencies and indel frequencies. FastAnalyzr BE is distributed as an executable shell (Bash) script with additional R-based processing steps. Installation is managed via Conda (https://anaconda.org/anaconda/conda) and the tool is compatible with Linux and macOS platforms.
FastAnalyzr BE consists of three main steps:
1) Batch file creation: When launched, the software opens a template HTML file containing a table with all required columns. Integrated validations prevent the inclusion of incorrect characters or blank spaces. After filling out the table, the user exports a tab-delimited .txt file. The program also identifies any incorrect .txt files in the working directory.
2) Analysis via CRISPResso2: Once the batch format is validated, FastAnalyzr BE runs CRISPResso2 for each specified target, generating the output files needed for the next step.
3) Compilation and visualization of results: An R script automatically traverses the CRISPResso2 output directories, compiling total counts, aligned reads, base editing efficiencies, indel frequencies and haplotypes (if necessary). All results are organized into unified summary tables. Visual summaries, including heatmaps and Excel tables, are also generated to facilitate comparative and interpretative analysis.
The pipeline supports parallel processing of dozens of amplicons or samples in a single run, making it ideal for high-throughput applications. All output tables and graphs are formatted for immediate statistical analysis. By ensuring compliance with the expected batch file format and automating result aggregation, FastAnalyzr BE significantly reduces formatting and transcription errors, as well as overall analysis time.
In summary, FastAnalyzr BE simplifies the analysis of base editing data by automating key steps—batch file creation, CRISPResso2 execution, result interpretation, and visualization—enhancing efficiency, scalability, and reliability of CRISPResso2-based workflows.

# Installation


```

# 1. Create and activate the Conda environment
conda env create -f environment.yml
conda activate Fast_Analyzr_BE

# 2. Clone the repository
git clone https://github.com/PROADI-TIAF/Fast-Analyzr-BE.git
cd Fast-Analyzr-BE

# 3. Make the script executable
chmod +x Fast_Analyzr_BE.sh

# 4. (Optional) Move script to global PATH (requires sudo)
sudo mv Fast_Analyzr_BE.sh /usr/local/bin/Fast_Analyzr_BE

# 5. Check that the script works
Fast_Analyzr_BE -h

```

