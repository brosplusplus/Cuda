#!/bin/bash
#@ jobname = CUDA
#@ initialdir = .
#@ output=%j_cuda.out
#@ error=%j_cuda.err
#@ total_tasks = 1
#@ cpus_per_tasks = 1
#@ gpu_per_node = 1
#@ wall_clock_limit = 01:00:00


im=`ls -Sr img/`
mkdir outputs

for i in $im
do
	./exe -g 3 -i "img/$i" -o "outputs/gaussCUDA3-$i.png"
	./test -g 3 -i "img/$i" -o "outputs/gaussCPU3-$i"
	#~ ./exe -l -i "img/$i" -o "outputs/laplaCUDA3-$i"
	#~ ./test -l -i "img/$i" -o "outputs/laplaCPU3-$i"	
done

#~ for i in 3 13 23 33 45 55 75 85 95 105
#~ do
	#~ echo "tamany $i"
	#~ ./exe -g "$i" -i img/world.png -o "outputs/guassCUDAworld-$i.png"
	#~ ./test -g "$i" -i img/world.png -o "outputs/gaussCPUworld-$i.png"
#~ done

tar -zxf outputs-`date +"%D-%H-%M"`.tar.gz outputs
rm -rf outputs

