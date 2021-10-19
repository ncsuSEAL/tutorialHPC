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
# PS: sometimes, use `-x` to run the job exclusively may avoid some werid errors, but use it with caution!
# --------------------------------------------------------------------------------------
#!/bin/tcsh
#BSUB -n 64
#BSUB -W 20
#BSUB -x
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



# The output file will look like this:
# --------------------------------------------------------------------------------------
# --------------------------------------------------------------------------
# [[62099,1],0]: A high-performance Open MPI point-to-point messaging module
# was unable to find any relevant network interfaces:

# Module: OpenFabrics (openib)
#   Host: n2k5-6

# Another transport will be used instead, although this may result in
# lower performance.
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# WARNING: a request was made to bind a process. While the system
# supports binding the process itself, at least one node does NOT
# support binding memory to the process location.

#   Node:  n2k5-3

# This usually is due to not having the required NUMA support installed
# on the node. In some Linux distributions, the required support is
# contained in the libnumactl and libnumactl-devel packages.
# This is a warning only; your job will continue, though performance may be degraded.
# --------------------------------------------------------------------------
# --------------------------------------------------------------------------
# WARNING: Open MPI will create a shared memory backing file in a
# directory that appears to be mounted on a network filesystem.
# Creating the shared memory backup file on a network file system, such
# as NFS or Lustre is not recommended -- it may cause excessive network
# traffic to your file servers and/or cause shared memory traffic in
# Open MPI to be much slower than expected.

# You may want to check what the typical temporary directory is on your
# node.  Possible sources of the location of this temporary directory
# include the $TEMPDIR, $TEMP, and $TMP environment variables.

# Note, too, that system administrators can set a list of filesystems
# where Open MPI is disallowed from creating temporary files by setting
# the MCA parameter "orte_no_session_dir".

#   Local host: n2k5-6
#   Filename:   /share/jmgray2/xgao26/tmp/openmpi-sessions-xgao26@n2k5-6_0/62099/2/2/vader_segment.n2k5-6.2

# You can set the MCA paramter shmem_mmap_enable_nfs_warning to 0 to
# disable this message.
# --------------------------------------------------------------------------
#         63 slaves are spawned successfully. 0 failed.
# Hello from loop iteration 1 running on rank 1 on node n2k5-6 which has 16 cores
# Hello from loop iteration 2 running on rank 2 on node n2k5-6 which has 16 cores
# Hello from loop iteration 3 running on rank 3 on node n2k5-6 which has 16 cores
# Hello from loop iteration 4 running on rank 4 on node n2k5-6 which has 16 cores
# Hello from loop iteration 5 running on rank 5 on node n2k5-6 which has 16 cores
# ...
# Hello from loop iteration 499 running on rank 58 on node n2k5-7 which has 16 cores
# Hello from loop iteration 500 running on rank 59 on node n2k5-7 which has 16 cores
# [1] 1
# [1] "Detaching Rmpi. Rmpi cannot be used unless relaunching R."

#                             <16*n2k5-3>
#                             <16*n2k5-1>
#                             <16*n2k5-7>
# </home/xgao26> was used as the home directory.
# </home/xgao26/hello> was used as the working directory.
# Started at Tue Oct 19 12:09:59 2021
# Terminated at Tue Oct 19 12:10:27 2021
# Results reported at Tue Oct 19 12:10:27 2021

# Your job looked like:

# ------------------------------------------------------------
# # LSBATCH: User input
# #!/bin/tcsh
# #BSUB -n 64
# #BSUB -W 20
# #BSUB -J hello
# #BSUB -q cnr
# #BSUB -x
# #BSUB -oo out.%J
# #BSUB -eo err.%J

# module load openmpi-gcc/openmpi1.8.4-gcc4.8.2
# conda activate /usr/local/usrapps/jmgray2/jgao/my_env
# mpirun -n 1 Rscript ./hello.R
# conda deactivate

# ------------------------------------------------------------

# Successfully completed.

# Resource usage summary:

#     CPU time :                                   882.36 sec.
#     Max Memory :                                 405.40 MB
#     Average Memory :                             405.40 MB
#     Total Requested Memory :                     -
#     Delta Memory :                               -
#     Max Swap :                                   -
#     Max Processes :                              20
#     Max Threads :                                28
#     Run time :                                   36 sec.
#     Turnaround time :                            30 sec.

# The output (if any) is above this job summary.



# PS:

# Read file <err.192621> for stderr output of this job.
# --------------------------------------------------------------------------------------



