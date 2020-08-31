## Overview
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4009396.svg)](https://doi.org/10.5281/zenodo.4009396)

This repository is a companion to the author's master thesis. It includes the source code (C++), the analysis scripts (Python/R) and the graphs developed for and used in the thesis. 

## Directory Structure
General remark: The thesis project consists of two subprojects: the first focuses on the existence of a genetic signature and the second one focuses on the interaction of multi-level selection mechanisms in a population.
Material specifically dedicated to the first one is annotated with 'a', whereas material for the second one is annotated with 'b'.

| Folder/File                               | Description
| ------------                              | ----
| 1_MABE/                                   | Source code written for MABE.
| 2_FromHPCC/                               | Data, analysis scripts and file structure from experiments run on MSU's HPCC.
| 3_a_LocalMachineDataProcessing_Python/    | Data processing step done on the author's local machine.
| 4_Graphs_R/                               | Analysis scripts and graphs for the thesis.
| Overview_Runs_and_Random_Seeds.xlsx       | Excel-file, summarizing all runs conducted on the HPCC and the random seeds used for those runs.

### 1_MABE/
This folder contains the source code for the MABE-worlds written by the author. 'DualWorld' was designed for the first part of the project (a) and 'MigrationWorld' for the second one (b). This source code can easily be run when inserted into the overall MABE-code, which is found at https://github.com/Hintzelab/MABE. The author used for her work the branch 'feature-cmake-migration' at commit '1afc0754a36e36d01811ee827a2b413da7720e68'.

### 2_FromHPCC/
This folder contains the source code for the scripts used to aggregate the data from all runs on the HPCC. Moreover, the configuration files used for MABE and the file structure is included to make it comprehensible how this second step of the project was done.

### 3_a_LocalMachineDataProcessing_Python/
This folder contains the data-aggregation scripts for the first part of the project, which is indicated by the 'a' in the folder name. Since many different analyses were conducted for this first part of the project, the author decided to further aggregate the data on her local machine before running R-scripts for visualizations.
There is no such folder for the second part of the project (b) since the data was already sufficiently aggregated on the HPCC (see scripts included in '2_FromHPCC/b_Migration/').

### 4_Graphs_R/
Finally, this folder contains the R-scripts for all analysis shown in the thesis. They are split up by 'a' and 'b' prefixes to make the part of the project, which they were used for, visible at first glance.

## Reproducibility of Results
The MABE-runs can be reproduced by installing MABE (see tutorial https://github.com/Hintzelab/MABE/wiki/Installation-and-getting-started-with-MABE) and including the code provided with folder '1_MABE/'.
An overview of the runs and used random seeds is given with file 'Overview_Runs_and_Random_Seeds.xlsx'.
The scripts for aggregating and plotting the data are provided as well. Therefore, the interested reader should be able to reproduce the work presented in the author's master thesis.
