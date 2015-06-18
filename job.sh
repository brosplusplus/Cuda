#!/bin/bash
### Directivas para el gestor de colas
# Asegurar que el job se ejecuta en el directorio actual
#$ -cwd
# Asegurar que el job mantiene las variables de entorno del shell lamador
#$ -V
# Cambiar el nombre del job
#$ -N ProvaWORLD
# Cambiar el shell
#$ -S /bin/bash

#~ im=`ls -Sr img/`
mkdir -p outputs
#~ 
#~ for i in $im
#~ do
	#~ echo "$i CUDA 3x3"
	#~ ./kernelGPU.exe -g 3 -i img/$i -o outputs/gaussCUDA3-$i.png
	#~ echo "$i CPU 3x3"
	#~ ./kernelCPU.exe -g 3 -i img/$i -o outputs/gaussCPU3-$i
	##~ ./exe -l -i "img/$i" -o "outputs/laplaCUDA3-$i"
	##~ ./test -l -i "img/$i" -o "outputs/laplaCPU3-$i"	
#~ done

#~ for i in 3 13 23 33 45 55 75 85 95 105
#~ do
	#~ echo "tamany $i"
	#~ ./kernelGPU.exe -g "$i" -i img/world.png -o outputs/guassCUDAworld-$i.png
	#~ ./kernelCPU.exe -g "$i" -i img/world.png -o outputs/gaussCPUworld-$i.png
#~ done

./kernelCPU.exe -g 3 -i img/world.png -o outputs/gaussCPUworld-003.png
./kernelCPU.exe -g 13 -i img/world.png -o outputs/gaussCPUworld-013.png
./kernelCPU.exe -g 25 -i img/world.png -o outputs/gaussCPUworld-025.png
./kernelCPU.exe -g 39 -i img/world.png -o outputs/gaussCPUworld-039.png
./kernelCPU.exe -g 55 -i img/world.png -o outputs/gaussCPUworld-055.png
./kernelCPU.exe -g 73 -i img/world.png -o outputs/gaussCPUworld-073.png
./kernelCPU.exe -g 93 -i img/world.png -o outputs/gaussCPUworld-093.png
./kernelCPU.exe -g 115 -i img/world.png -o outputs/gaussCPUworld-115.png

tar -zcf outputs-`date +"%d_%H-%M"`.tar.gz outputs && rm -rf outputs/*

#~ ./exe -g 3 -i img/cuda.png -o cuda3GPU.png
# ./exe -g 5 -i img/Windows_icon.svg.png -o Windows5GPU.png
# ./exe -g 7 -i img/VRB.PNG -o VRB7GPU.png
# ./exe -g 11 -i img/julk.png -o julk11GPU.png
# ./exe -g 33 -i img/world.png -o worldGPU.png
#
# ./test -g 3 -i img/cuda.png -o cuda3CPU.png
# ./test -g 5 -i img/Windows_icon.svg.png -o Windows5CPU.png
# ./test -g 7 -i img/VRB.PNG -o VRB7CPU.png
# ./test -g 11 -i img/julk.png -o julk11CPU.png
# ./test -g 33 -i img/world.png -o worldCPU.png
#
# ./exe -l -i img/cuda.png -o cudaLapGPU.png
# nvprof ./exe -l -i img/Windows_icon.svg.png -o WindowsLapGPU.png
# ./exe -l -i img/VRB.PNG -o VRBLapGPU.png
# ./exe -l -i img/julk.png -o julkLapCPU.png
# ./exe -l -i img/world.png -o worldLapGPU.png
#
# ./test -l -i img/cuda.png -o cudaLapCPU.png
# ./test -l -i img/cuda.png -o cudaLapCPU.png
# ./test -l -i img/Windows_icon.svg.png -o WindowsLapCPU.png
#  ./test -l -i img/VRB.PNG -o VRBLapCPU.png
# ./test -l -i img/julk.png -o julkLapCPU.png
# ./test -l -i img/world.png -o worldLapCPU.png

