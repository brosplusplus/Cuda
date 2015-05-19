#!/bin/bash
#@ jobname = CUDA
#@ initialdir = .
#@ output=%j_cuda.out
#@ error=%j_cuda.err
#@ total_tasks = 1
#@ cpus_per_tasks = 1
#@ gpu_per_node = 1
#@ wall_clock_limit = 00:05:00


time ./exe -i img/PNG_transparency_demonstration_2.png

