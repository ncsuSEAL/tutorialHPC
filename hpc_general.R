# ~ Login to HPC ####
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Use `ssh` command in your terminal. 
# Format: ssh -Y [unityID]@login.hpc.ncsu.edu
ssh -Y xgao26@login.hpc.ncsu.edu

# It's a Linux environment, so all Linux commands work
# For exmaple:
#   `ls` - list files and folders in current directory
#   `cd [directory]` - change directory to the specified directory path. 
#                      `cd $HOME` will take you to your home directory.
#                      `cd ..` to move to the parent directory.
#   `vi [filename]` - open and edit a file. If the file doesn't exist, it'll create a new one.
#   `less [filename]` - preview a file's content.
#   `rm [filename]` - remove the specified file.
#   `mkdir [directory name]` - create a directory under current folder.
#   `du -h --max-depth=1` - calculate size of a directory. `--max-depth=1` hides the subdirectories when printing the output
#   `exit` - disconnet with HPC.
# Goolge for more information.
ls
ls -l
ls | wc -l
cd $HOME
cd ..
mkdir hello
vi testnew.txt
less testnew.yml
rm testnew.txt
du -h --max-depth=1



# ~ Using R in HPC ####
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Once login, you're on the login node. Do not run huge computational tasks on the login node.
#   But, the login node is the only node that allows internet access. So, R packages should be 
#   installed on the login node.

# There're 2 ways to use R in HPC: HPC's R version or conda R.

# Load HPC's R
module load R
R
module unload R

# Use conda R:
#   activate conda: `conda activate /usr/local/usrapps/jmgray2/<unityID>/<yourEnvironmentName>`
#   and then, type `R` in the terminal



# ~ Interactive session ####
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Request interactive session
#   `-n`: number of cores
#   `-W`: usage time (unit: min)
#   `-R`: resources. Max memory you can request is 46 GB, default is 16 GB
#   `-x`: request the entire node
bsub -Is -n 1 -W 180 -R "rusage[mem=46GB]" tcsh
bsub -Is -n 10 -W 60 tcsh
bsub -Is -n 24 -W 60 -x tcsh

# To quit an interactive session
exit

# Note: `exit` will quit the interactive session, but does not terminate it, which means
#   the session is still running. You can use `bjobs` to see it.
bjobs

# To have more details:
bjobs -r -X -o "jobid queue cpu_used run_time avg_mem max_mem slots delimiter=','"

# To terminate an interative session, you should kill the job using `bkill [jobID]` 
#   or `bkill 0` to kill all jobs.
bkill 0



# ~ A simple example to show the power of HPC ####
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Let's make a simple loop.

iter <- 1:1e4

# A seriel work
system.time(
    for (i in iter) {
        sort(runif(1e5))
    }
)

# I know we can use `apply` functions
system.time(
    sapply(iter, FUN = function(x) { sort(runif(1e5)) })
)

# Make it parallel
library(parallel)
# Number of cores on your local machine
detectCores()

# Note: always reserve a node for the main thread, 
#   otherwise the machine would be super slow until the job finishes
system.time(
    mclapply(iter, function(x) { sort(runif(1e5)) }, mc.cores = detectCores() - 1)
)


# ~ Another example to illustrate parallel computing in HPC ####
## Note you must have installed Rmpi to do this section. Please See the Rmpi section of the general guide: https://github.com/ncsuSEAL/tutorialHPC/blob/main/generalGuide.md
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# For a quick intro to parallel processing in R, 
#   go to: https://nceas.github.io/oss-lessons/parallel-computing-in-r/parallel-computing-in-r.html

# After login, create a folder named `hello`
mkdir hello

# Go to the newly created folder
cd hello

# Create a script file named `hello.R`
vi hello.R

# Type `i` to edit the file.
# Copy and paste code below into `hello.R`:
# -------------------------------------------------------------------------------------- 
# R code that demonstrates the use of Rmpi
# Define a function that takes the loop iteration number and outputs a message containing
# the iteration number, the MPI rank, the hostname, and the number of cores on the host
hello.world <- function(i) {
    library(parallel)
    sprintf(
        "Hello from loop iteration %d running on rank %d on node %s which has %d cores",
        i, mpi.comm.rank(), Sys.info()[c("nodename")], detectCores()
    )
}

# Use the parallel libraries
library(Rmpi)
library(parallel)
library(snow)
# R is called with mpirun -n 1 which defines the master processes
# and then R master process spans worker processes up to the amount of cores
cl <- makeCluster((mpi.universe.size() - 1), type = "MPI")

output.lines <- clusterApply(cl = cl, x = (1:500), fun = hello.world)
cat(unlist(output.lines), sep = "\n")
stopCluster(cl)
mpi.exit()
# --------------------------------------------------------------------------------------

# Type `esc`, then `:wq` to save the file and return to terminal.

# Create a job description file
vi job_hello.csh

# Again, type `i` to edit the file, then copy and paste the code below into the file.
#   Make sure to change the conda path to yours!
# --------------------------------------------------------------------------------------
#!/bin/tcsh
#BSUB -n 64
#BSUB -W 20
#BSUB -J hello
#BSUB -oo out
#BSUB -eo err

module load openmpi-gcc/openmpi1.8.4-gcc4.8.2
conda activate /usr/local/usrapps/jmgray2/jgao/my_env
mpirun -n 1 Rscript ./hello.R
conda deactivate
# --------------------------------------------------------------------------------------

# Again, type `esc`, then `:wq` to save the file and return to terminal.

# Now, you can submit the job
bsub < job_hello.csh

# Use `bjobs` to check the job status
bjobs

# Once the job is done, check the output file
vi out

# And, check the error file if the code didn't run correctly
vi err
