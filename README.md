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
Multiple tools have been developed for analyzing base editing outcomes from cytosine and adenine base editors (CBEs and ABEs). Among the most widely used is CRISPResso2 https://github.com/pinellolab/CRISPResso2, which integrates read quality filtering, alignment, reporting, and quantification of editing results, including indels and base-editing efficiencies. For experiments using NGS amplicon sequencing with one or more targets and gRNAs, the CRISPRessoBatch module is particularly useful, as it enables the analysis and comparison of multiple experimental conditions at the same site.
However, in our routine use we identified some limitations. The batch mode requires a strictly formatted input file and produces a large number of output files (HTML reports, alignment tables, frequency matrices), making data preparation and consolidation time-consuming and error-prone. To address these challenges, we developed **Fast-Analyzr-BE**, an automated tool for quantifying base-editing efficiency and indel frequencies. Distributed as a Bash script with R-based processing, it is installed via Conda and runs on both Linux and macOS. The pipeline operates in three main steps:
1. Batch file creation – An HTML template guides users through completing the required fields with built-in validation to prevent formatting errors, exporting a tab-delimited `.txt` file.
2. Analysis with CRISPResso2 – Validated batch files are processed automatically, generating all required outputs.
3. Compilation and visualization of results – An R script aggregates outputs into unified summary tables, Excel files, and visualizations (heatmaps, haplotype analysis if needed). The pipeline supports parallel processing of dozens of amplicons or samples, producing outputs ready for downstream statistical analysis.
By enforcing format consistency and automating result aggregation, Fast-Analyzr-BE reduces errors, saves time, and improves the scalability and reliability of CRISPResso2-based workflows.

Currently, the tool is available in `version 2.0`, which includes all the features of version 1.0 (read analysis, base-editing quantification, and indel detection), with the addition of haplotype calculation based on user-specified nucleotide positions. The `.sh` file of version 1.0 can be found in the `Version_1` folder.


# Requirements
1. Conda – https://docs.conda.io/en/latest/miniconda.html
2. Google Chrome – https://www.google.com/chrome/

Note 1: For WSL users Google Chrome must be installed via terminal. Follow the instructions here: https://scottspence.com/posts/use-chrome-in-ubuntu-wsl

Note 2: Enable Ask Where to Save Downloads in Google Chrome. Open Chrome → *Settings* → *Downloads* (or go to `chrome://settings/downloads`) and enable *Ask where to save each file before downloading*.


# Installation
The way to install Fast-Analyzr-BE is via conda, follow these steps:

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
After installing Fast-Analyzr-BE, follow these steps to run an analysis:

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


# Test the installation

After installing, you can run a quick test to make sure everything is working correctly.  
The repository already contains example batch files in the `Test/` folder.

**Steps**

```
# 1. Enter the test folder:
cd Test/
   
# 2. Run the pipeline with the test data:
Fast_Analyzr_BE -n -ha
```

If everything is correct, you should see the following message (symbolizing that the base editing and indel calculation is complete):

```
                            _    _                                                     _    _
                           (_\__/(,_                                                  (_\__/(,_
                           | \  _////-._                                             | \  _////-._
            _    _         L_/__  => __/ \                            _    _         L_/__  => __/ \
           (_\__/(,_       |=====;__/___./                           (_\__/(,_       |=====;__/___./
           | \  _////-._   '-'-'-''''''''                            | \  _////-._   '-'-'-''''''''
           J_/___'=> __/ \                                           J_/___'=> __/ \
           |=====;__/___./                                           |=====;__/___./
           '-'-'-''''''''                                            '-'-'-''''''''

Base editing and indel calculation completed!
```

Next, you will be asked to provide the positions of the bases for haplotype analysis.

```
Please enter the desired positions (comma-separated) for each guide:

  Positions for 'Guide-1' (GGCAAGGCTGGCCAACCCAT): 4,5
  Positions for 'Guide-2' (AGATATTTGCATTGAGATAG): 3,5,11
```

Once the haplotype analysis is finished, you should see the following message:

```
                            _    _                                                     _    _
                           (_\__/(,_                                                  (_\__/(,_
                           | \  _////-._                                             | \  _////-._
            _    _         L_/__  => __/ \                            _    _         L_/__  => __/ \
           (_\__/(,_       |=====;__/___./                           (_\__/(,_       |=====;__/___./
           | \  _////-._   '-'-'-''''''''                            | \  _////-._   '-'-'-''''''''
           J_/___'=> __/ \                                           J_/___'=> __/ \
           |=====;__/___./                                           |=====;__/___./
           '-'-'-''''''''                                            '-'-'-''''''''

Haplotypes analysis completed!
```

Finally, compare the results you obtained with the expected results located in: `Test/Expected_Final_result/`. If the files match, the installation and execution are working correctly!

# How to fill the Batch file (HTML Batch File Editor)
This page explains how to use the Batch File Editor (the HTML interface) and what each column must contain. The editor exports a tab-delimited .txt file that is used by the pipeline.

**Quick summary**
1. Open the Batch File Editor (the provided HTML file) in your browser.
2. Enter one row per sample. Use Add Rows / Remove Rows to edit rows.
3. Fill all fields (no empty cells) and use the Save Batch File as TXT button to download the tab-delimited batch file. The file is downloaded as batch_file.txt — rename if needed.
   
**Important note about experiment design**
Each Batch file should correspond to a single amplicon and single sgRNA (i.e., the same a and g should be used across rows). If you have different amplicons or different guides, create separate Batch files. Additionally, the FASTQ files must be in the same analysis folder

**Column definitions, required format and examples**
The editor shows a header row and the following editable columns (order in the saved file is the same as the visible headers):


| **Column name** | **Meaning**                   | **Allowed values / characters** | **Example**           |
| ---------------- | ----------------------------- | ------------------------------- | --------------------- |
| `fastq_r1`       | FASTQ file name (R1)          | Letters, digits, `.`, `_`, `-`  | `sampleA_R1.fastq.gz` |
| `fastq_r2`       | FASTQ file name (R2)          | Letters, digits, `.`, `_`, `-`  | `sampleA_R2.fastq.gz` |
| `n`              | Output report name (ID)       | Letters, digits, `_`, `-`       | `sampleA_rep1`        |
| `a`              | Amplicon sequence (DNA)       | A, C, G, T only                 | `ATGCGTACG...`        |
| `an`             | Amplicon name                 | Letters, digits, `_`, `-`       | `amplicon_1`          |
| `g`              | sgRNA sequence (guide)        | A, C, G, T only                 | `GACGTTACGT...`       |
| `gn`             | sgRNA name                    | Letters, digits, `_`, `-`       | `guide_A`             |
| `DNA_F_or_R`     | Strand where guide was designed | `F` (forward) or `R` (reverse) | `F`                   |
| `BE`             | Base editor                   | `ABE` or `CBE`                  | `CBE`                 |

After saving the batch file, you can click to create a new one, which will erase all previous information. When you're finished, simply close the Google Chrome page and press `y` or `yes` to confirm the analysis in the terminal.


# Output layout and post-analysis files

**File tree**

```
Final_result/
├─ Batch_01/
│  ├─ Batch_01_compiled_reads/
│  │  ├─ sample1.tiff
│  │  ├─ sample2.tiff
│  │  └─ ...
│  ├─ Batch_01_compiled_heatmaps/
│  │  ├─ sample1.tiff
│  │  └─ sample2.tiff
│  │  └─ ...  
│  ├─ Batch_01_final_result.xlsx
│  ├─ Batch_01_final_result_1.tiff
│  ├─ Batch_01_final_result_2.tiff            # If >12 samples
│  ├─ Batch_01_indels.xlsx                    # Generated when indel > 0.2% in at least one sample
│  ├─ Batch_01_haplotypes.xlsx                # Present when -ha/--haplotypes is active
│  └─ Batch_01_haplotypes_stacked_bar.png     # Present when -ha/--haplotypes is active
├─ Batch_02/
│  └─ ...
└─ Instructions.txt                           # This file with post-analysis instructions
```

---

**What you will find in each Batch folder**

* `compiled_reads/` – allele plots (one file per sample) generated by CRISPResso2.
* `compiled_heatmaps/` – heatmap(s) summarizing base-editing rates with per-sample indel values.
* `final_result.xlsx` – consolidated results workbook (structure below).
* `final_result.tiff` – summary heatmap image. If there are more than 12 samples, multiple heatmaps will be produced.
* `indels.xlsx` – produced only when one or more samples have indel frequency > 0.2%. Each qualifying sample is exported to its own sheet.

---

**`final_result.xlsx` (workbook structure)**

1. *Reads* (sheet)

   * Per-sample read metrics with a legend and color-coded columns. Key columns:

     * `Total_reads`
     * `Aligned_reads`
     * `Aligned_percentage`

2. *Editing* (sheet)

   * Base-editing rates as percentages. For ABE report A→G; for CBE report C→T.
   * Only A (for ABE) or C (for CBE) positions inside the gRNA window are reported, alongside their relative positions.

3. *Indel* (sheet)

   * Indel statistics with these columns:

     * `Insertion_Reads`
     * `Insertion_Percentage`
     * `Deletion_Reads`
     * `Deletion_Percentage`
     * `Indel_Percentage`

---

**`final_result.tiff`**

A heatmap image that summarizes editing rates and indel values across samples. When the pipeline detects >12 samples it splits results across multiple heatmap files to keep figures readable.

---

**`indels.xlsx` (when present)**

* Generated when any sample displays indel frequency > 0.2%.
* Each sample that meets the threshold is exported to a separate sheet for inspection.

---

**Haplotype analysis (optional)**

If the haplotypes function is enabled (`-ha`; `--haplotypes` ), the pipeline will:

1. List all detected gRNA sequences after finishing the main editing analysis.
2. Prompt the user to specify which positions to analyze.
3. For each Batch file, generate:

   * `haplotypes.xlsx` — table of observed haplotypes for the chosen positions.
   * `haplotypes_stacked_bar.png` — stacked-bar visualization of haplotype frequencies.

*Visualization note:* In the stacked bar graph haplotypes with frequency < 1% are grouped into *Other Haplotypes* and are not listed individually in the chart legend to improve readability.

---

**Troubleshooting**

If files are missing or the output structure differs from the example above:

1. Check the pipeline console/log output for error messages.
2. Verify that your Batch file follows the required tab-delimited format.
3. Inspect CRISPResso2 raw outputs for clues.
4. Re-run the affected batch after fixing the input format.


## About us

Fast-Analyzr-BE was developed as part of a project funded by **PROADI-SUS Anemia Falciforme**, Ministry of Health, Brazil, and created by researchers at **Hospital Israelita Albert Einstein**, São Paulo, Brazil.  

**Contributors (Proponents):**
- Paulo Alfonso Schüroff  
- Davi Coe Torres  
- Ricardo Weinlich  
