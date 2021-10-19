# How to set a up a conda environment in HPC (with R)

## What is conda?
Conda is an open-source package and environment management software. 
- Anaconda is an offshoot of conda. 
- Miniconda is a light version of Anaconda.

Both R and Python can be run within conda.

### Environments
Environments can be thought of as different rooms that you run code in. Let's pretend you want to run two R scripts, but each requires a different version of R or a specific package. You can set up unique environments using conda, each with separate versions of R/packages, and then run your scripts simultaneously but in their respective rooms. If you didn't use conda, for example on HPC, then you could only use whatever version of R that HPC is running.

## Setting up conda for the first time
*this comes from https://projects.ncsu.edu/hpc/Software/Apps.php?app=Conda*

Setting up conda for the first time takes a little bit, but once it's set then it's easy.

Steps
1. Log in to HPC. If you haven't done this before, see [the general HPC guide](https://github.com/ncsuSEAL/sealHPChelp/blob/main/generalGuide.md).
- `ssh -Y <unityID>@login.hpc.ncsu.edu`

2. Now load conda, then create a tcsh file. 
- Enter the commands below in the HPC terminal:
- `module load conda`
- `conda init tcsh`

3. After you do this, shut down the terminal, log back in, and load conda again.

4. Add the basics needed for conda
- `conda config --add channels bioconda`
- `conda config --add channels conda-forge`

5. Create file showing where to put packages using vim, a text editor program in Unix. I'll spell out the commands needed here, but for general VIM usage see [here](https://vim.rtorr.com/).
- Enter `vi .condarc` in the HPC terminal.
- Get into editing mode by entering `i` in terminal.
- Then add the following to the file.
``` r
pkgs_dirs: 
 - /share/$GROUP/$USER/conda/pkgs
```
- Get out of editing mode by entering `i` again in terminal.
- Save a quit by doing `ESC` and then `:wq:` (stands for "write" and "quit").

6. Create a conda environment in your installation folder.
- NOTE this folder is different from your normal HPC folder. This is because this is just where your environment will sit.
  - For example, your normal folder is `cd /rsstu/users/j/jmgray2/SEAL/<YourName>`
  - If you've never set up a conda env before, then you need to create your own installation folder first. To do so, enter the following script
    - `mkdir /usr/local/usrapps/jmgray2/<unityID>`

- There are two ways of creating an environment. You could do a simple create, for example, and load packages later. This can be accomplished by running the following code: `conda create --prefix /usr/local/usrapps/jmgray2/<unityID>/<chooseAnEnvironmentName>`. However, some packages may conflict with each other if you install them sequentially.
- More ideally, you can create an environment using a .yml file. By doing this, conda will install versions of R and your desired packages such that they won't conflict with each other. Here, we use rlibs.yml to install R along with basic spatial packages. Other examples of .yml files can be found at the website linked at the top of this section.
  - This file is saved in the same directory as the .bashrc file. You can create it using vim like above.

``` r
vi rlibs.yml #enter this in terminal
i #enter editing mode. Now copy and paste the stuff below

name: rlibs #whatever you choose to call this, update it in the line of code below this code section.
channels:
  - conda-forge
  - r
dependencies:
 - r-spatialeco
 - r-rgdal
 - r-tidyverse
 - r-usedist
 - r-igraph
 - r-gdistance
 - r-gdata
 - r-maptools
 - r-reshape2
 - r-data.table

# Now save the file and quit
Esc
:wq
```

  - Now you can create the environment using this code: `conda env create --prefix /usr/local/usrapps/jmgray2/<unityID>/<chooseAnEnvironmentName> -f rlibs.yml`

Sometimes you get errors about permissions. If you get these, then you need to fix your rc files.
- CD to home directory `cd ~` or `cd $HOME`
- look at the contents of the following files
  - `more .bashrc`
  - `more .tcshrc`
- If either of those files has content in between the >>>>>, then delete it using VIM.
```r
vi .bashrc # or vi .tcshrc
i

# >>> conda initialize >>>
(stuff) # <- delete this
# >>> conda initialize >>>

i
ESC
:wq
```
- Now try creating the environment again using either the .yml file or not using it.

7. Your conda environment is ready to use! To do so, you need to activate it with this code (this is what you'll do every time from here on out). Run the following code either directly in the terminal, or in your .csh scripts when submitting batch jobs.
- `conda activate /usr/local/usrapps/jmgray2/<unityID>/<yourEnvironmentName>`

8. To install something in conda, do `conda install <name>`.
- To view a list of everything you have installed in your conda environment, type `conda list`.

9. To set an environment variable, use `conda env config vars set my_var=value`. This may be of interest to you if you want to refer to specific values (numbers, directories, file paths, etc.) in your scripts without having to explicitly specify the information. This way, you can change the variable's value in your environment rather than searching through every instance of the value/path in your code.
- To get the current value of an environment variable: `echo $my_var`
- To unset the variable: `conda env config vars unset my_var`
- Use flags -n and -p to specify the name of the environment or the path to the environment (i.e., `conda env config vars unset my_var -p /path/to/env`).

10. When you're done using conda for a session, deactivate it using `conda deactivate`.

## Running conda normally after set-up
Once conda is set, things are super easy. Just log into HPC, and then activate your environment.
- `ssh -Y <unityID>@login.hpc.ncsu.edu`
- `conda activate /usr/local/usrapps/jmgray2/<unityID>/<envName>`

## Using R with conda in HPC
Note that if you used the rlibs.yml to create the env, then you don't need to install R.

### Install specific R version
Let's say I want to install an older version of R. If I tried to run R in HPC, then I can only use what it uses, namely the most recent version. Instead, I want to use 3.6.3, so I need to use conda to install it. Specifying "3.6" will return the last stable release of that generation, so here that means 3.6.3.
-  `conda install -c r r=3.6`

### WARNING
Make sure when you're in conda and using R that you DO NOT use "module load R". That command is for HPC only, not conda. If you do both commands, then you will be
default using the HPC R on the login node. HPC staff do not like this, so if you do want to use R with HPC only, create an interactive R session (see bottom).

To check if both are loaded, enter `module list` into terminal. If you see "R/4.0.2-gcc..." then you have the HPC R loaded. Get rid of it using `module unload R`. Now type `R` and you should see the version you specified.

### Install R packages
Because you're still in HPC, you're going to have to install R packages ahead of time for when you submit jobs (HPC does not have internet access). Instead of loading R to do this, you can do it directly from conda. For example,
- `conda install r-data.table`
- `conda install r-ggplot2`

Similarly, you can install gdal in conda first, and then install the package in R (if not already specified in the .yml file when you created the environment).
`conda install -c conda-forge gdal`
`conda install r-rgdal`

### Interactive R session
There are two main ways of using R in HPC - either create R script and officially submit a job, or work on it in an interactive R session. For the latter, this is what your steps should look like.
1. Log in to HPC
2. CD to any folder you need.
3. Request an interactive session.
4. Load R in HPC or via your conda environment.

For example, this is as if Ian was logging in.
1. `ssh -Y imcgreg@login.hpc.ncsu.edu`
2. `cd /rsstu/users/j/jmgray2/SEAL/IanMcGregor`
3. `bsub -Is -n 10 -W 60 tcsh` (this says give me 10 cores for 1 hour)
    - To specify memory, do something like `bsub -Is -n 10 -W 180 -R "rusage[mem=28GB]" tcsh` (max is 64GB).
5. Load R via HPC: `module load R` and then `R`
6. Load R via conda: `conda activate /usr/local/usrapps/jmgray2/imcgreg/env_dissPareto3` then `R`.

To quit an interactive session, type `exit`.

Additional info about conda and environment management can be found [here](https://conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#setting-environment-variables). 
