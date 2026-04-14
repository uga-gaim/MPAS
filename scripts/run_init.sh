#!/bin/bash
#SBATCH --job-name=mpas_static_fields		# Job name (testBowtie2)
#SBATCH --partition=batch		# Partition name (batch, highmem_p, or gpu_p)
#SBATCH --nodes=1			# Number of compute nodes for resources to be spread out over (increase only if using MPI enabled software)
#SBATCH --ntasks=30			# 1 task (process) for below commands
#SBATCH --cpus-per-task=1	 	# CPU core count per task, by default 1 CPU core per task
#SBATCH --mem=250G			# Memory per node (4GB); by default using M as unit
#SBATCH --time=1:00:00              	# Time limit hrs:min:sec or days-hours:minutes:seconds
#SBATCH --output=%x_%j.out		# Standard output log, e.g., testBowtie2_12345.out
#SBATCH --mail-user=yourmail@uga.edu    # Where to send mail
#SBATCH --mail-type=END,FAIL          	# Mail events (BEGIN, END, FAIL, ALL)

ml netCDF/4.9.3-gompi-2025a
ml PnetCDF/1.12.3-gompi-2023b

cd /path/to/mpas_sim/

srun -n 30 ./init_atmosphere_model >& log.init_atmosphere.0000.out
