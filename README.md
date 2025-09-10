# Fast-Analyzr-BE: An automated tool for efficient base editing analysis


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
          |=====;__/___./                                     [Version 2.0]                       |=====;__/___./
          '-'-'-''''''''                                                                          '-'-'-''''''''
```        


# Summary
Multiple tools have been developed for analyzing base editing outcomes from cytosine and adenine base editors (CBEs and ABEs). Among the most widely used is CRISPResso2
, which integrates read quality filtering, alignment, reporting, and quantification of editing results, including indels and base-editing efficiencies. For experiments using NGS amplicon sequencing with one or more targets and gRNAs, the CRISPRessoBatch module is particularly useful, as it enables the analysis and comparison of multiple experimental conditions at the same site.
However, in our routine use we identified some limitations. The batch mode requires a strictly formatted input file and produces a large number of output files (HTML reports, alignment tables, frequency matrices), making data preparation and consolidation time-consuming and error-prone. To address these challenges, we developed FastAnalyzr BE, an automated tool for quantifying base-editing efficiency and indel frequencies. Distributed as a Bash script with R-based processing, it is installed via Conda and runs on both Linux and macOS. The pipeline operates in three main steps:
1. Batch file creation – An HTML template guides users through completing the required fields with built-in validation to prevent formatting errors, exporting a tab-delimited .txt file.
2. Analysis with CRISPResso2 – Validated batch files are processed automatically, generating all required outputs.
3. Compilation and visualization of results – An R script aggregates outputs into unified summary tables, Excel files, and visualizations (heatmaps, haplotype analysis if needed). The pipeline supports parallel processing of dozens of amplicons or samples, producing outputs ready for downstream statistical analysis.
By enforcing format consistency and automating result aggregation, FastAnalyzr BE reduces errors, saves time, and improves the scalability and reliability of CRISPResso2-based workflows.


# Requirements
1. Conda – https://docs.conda.io/en/latest/miniconda.html
2. Google Chrome – https://www.google.com/chrome/

Note for WSL users: Google Chrome must be installed via terminal. Follow the instructions here: https://scottspence.com/posts/use-chrome-in-ubuntu-wsl


# Installation
The way to install FastAnalyzr BE is via conda, follow these steps:

```
# 1. Create the Conda environment
conda create -n Fast_Analyzr_BE \
  -c conda-forge -c bioconda -c defaults \
  crispresso2 \
  r-base=4.3.0 r-essentials r-rmarkdown r-knitr \
  r-dplyr r-tidyr r-readxl r-openxlsx \
  bioconductor-biostrings \
  r-ggplot2 r-scales r-ggtext r-stringr r-rcolorbrewer \
  r-png

# 2. Activate the Conda environment
conda activate Fast_Analyzr_BE

# 3. Clone the repository
git clone https://github.com/PROADI-TIAF/Fast-Analyzr-BE.git
cd Fast-Analyzr-BE

# 4. Make the script executable
chmod +x Fast_Analyzr_BE.sh

# 5. Move script to global PATH (optional)
sudo mv Fast_Analyzr_BE.sh /usr/local/bin/Fast_Analyzr_BE

# 6. Check the script menu
Fast_Analyzr_BE -h
```


# Usage
After installing FastAnalyzr BE, follow these steps to run an analysis:

```
# 1. Go to your analysis folder
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
