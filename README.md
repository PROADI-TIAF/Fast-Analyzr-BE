# Fast-Analyzr-BE: An automated tool for efficient base editing analysis
Fast Analyzer BE is an open-source tool designed to simplify and standardize base editing analysis. It supports both Adenine Base Editing (ABE) and Cytosine Base Editing (CBE), providing a complete pipeline from raw sequencing data to final results. The tool automates preprocessing, guide classification, haplotype detection, and visualization, ensuring consistent and reproducible outputs. With user-friendly scripts and R-based reports, Fast Analyzer BE enables researchers to accurately quantify and compare editing efficiencies across samples, making it a valuable resource for genome editing studies.

```
                                                         ~~~ Fast Analyzr BE ~~~
                                     A script for quick and easy analysis focused on base editors

                           _    _                                                                                  _    _
                          (_\__/(,_                    ____________________________                               (_\__/(,_
                          | \  _////-._               |  __  __  __ ___    __  __  |                              | \  _////-._
           _    _         L_/__  => __/ \             | |__ |__||__  |    |__)|__  |               _    _         L_/__  => __/ \
          (_\__/(,_       |=====;__/___./             | |   |  | __| |    |__)|__  |              (_\__/(,_       |=====;__/___./
          | \  _////-._   '-'-'-''''''''              |____________________________|              | \  _////-._   '-'-'-''''''''
          J_/___'=> __/ \                                                                         J_/___'=> __/ \
          |=====;__/___./                                     [Version 1.0]                       |=====;__/___./
          '-'-'-''''''''                                                                          '-'-'-''''''''
```        


# Summary
Base editing technologies have transformed gene therapy by enabling precise correction of single-nucleotide mutations without inducing double-strand DNA breaks. Cytosine and adenine base editors (CBEs and ABEs) allow targeted conversions of C•G→T•A and A•T→G•C, respectively. Base editing outcomes are typically assessed by next-generation sequencing (NGS) of PCR amplicons, known as amplicon sequencing. This method provides single-nucleotide resolution, supports high-throughput analysis of multiple targets, and is considered the gold standard for validating genome editing experiments.
Among post-NGS analysis software, CRISPResso2 (https://github.com/pinellolab/CRISPResso2) is widely used. It integrates quality filtering, alignment, report generation, and quantification of editing outcomes, including indels and base editing efficiencies. However, its batch mode requires a strictly formatted input file and produces numerous output files (HTML reports, alignment tables, frequency matrices), making data preparation and consolidation time-consuming and error-prone.
To address these challenges, we developed FastAnalyzr BE, an automated tool for quantifying base editing efficiencies and indel frequencies. Distributed as a Bash script with R-based processing, it installs via Conda and runs on Linux and macOS. FastAnalyzr BE operates in three steps:
1) Batch file creation – An HTML template guides users to fill required fields with validation to prevent formatting errors, exporting a tab-delimited .txt file.
2) Analysis with CRISPResso2 – Validated batch files are processed automatically, generating the necessary outputs.
3) Result compilation & visualization – An R script aggregates outputs into unified summary tables, Excel files, and visualizations (heatmaps, haplotype analysis if needed).
The pipeline supports parallel processing of dozens of amplicons or samples, with outputs ready for statistical analysis. By ensuring format compliance and automating result aggregation, FastAnalyzr BE reduces errors, saves time, and enhances the scalability and reliability of CRISPResso2-based workflows.


# Requirements
1. Conda – https://docs.conda.io/en/latest/miniconda.html
2. Google Chrome – https://www.google.com/chrome/

Note for WSL users: Google Chrome must be installed via terminal. Follow the instructions here: https://scottspence.com/posts/use-chrome-in-ubuntu-wsl


# Installation
The way to install FastAnalyzr BE is via conda, follow these steps:

```
# 1. Clone the repository
git clone https://github.com/PROADI-TIAF/Fast-Analyzr-BE.git
cd Fast-Analyzr-BE

# 2. Make the script executable
chmod +x Fast_Analyzr_BE.sh

# 3. Move script to global PATH (requires sudo)
sudo mv Fast_Analyzr_BE.sh /usr/local/bin/Fast_Analyzr_BE

# 4. Create and activate the Conda environment
conda env create -f Fast_Analyzr_BE.yml
conda activate Fast_Analyzr_BE

# 5. Check that the script works
Fast_Analyzr_BE -h
```


# Usage
After installing FastAnalyzr BE, follow these steps to run an analysis:

```
1. Go to your analysis folder
cd /path/to/your/analysis_folder

# 2. Run the program
Fast_Analyzr_BE

# 3. Use menu options (optional)
Fast_Analyzr_BE -h
```

# Command line options

```
-h, --help                          Display this help message
-n, --no-batch                      Do not open the HTML file and create the Batch file
-s, --skip-batch-crispresso         Skip Batch file creation and CRISPResso2 execution
-c, --crispresso <key> [<value>]    Add a custom argument to CRISPRessoBatch execution.
                                    Allowed keys:   min_frequency_alleles_around_cut_to_plot <0-100>,
                                                    base_editor_output,
                                                    conversion_nuc_from <A,T,C,G>,
                                                    conversion_nuc_to <A,T,C,G>,
                                                    n_processes <Number of processes. Can be set to 'max'>.
-ha, --haplotypes                   Runs haplotype analysis on metadata files.
```
