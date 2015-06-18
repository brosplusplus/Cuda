SRC=projecte.cpp projecte.cu readpng.cpp job.sh job.mt


all: test

test: projecte.cpp readpng.cpp
	g++ --std=c++11 -o test projecte.cpp -lpng -I.

prod:
	scp -r $(SRC) cuda:/scratch/nas/1/cuda07/project/
	ssh cuda 'cd /scratch/nas/1/cuda07/project/; make && qsub -l cuda job.sh && qstat'
	
prodCPU:
	scp -r $(SRC) cuda:/scratch/nas/1/cuda07/project/
	ssh cuda 'cd /scratch/nas/1/cuda07/project/; make && qsub -l cuda job.sh && qstat'
	
prodMT:
	scp -r $(SRC) bsc99871@mt1.bsc.es:TGA/project
	ssh bsc99871@mt1.bsc.es 'cd TGA/project; make; mnsubmit job.mt; mnq | grep bsc99'

img:
	scp -r img cuda:/scratch/nas/1/cuda07/project/img
	
imgMT:
	scp -r img bsc99871@mt1.bsc.es:TGA/project/img

get:
	scp cuda:/scratch/nas/1/cuda07/project/salida.png .
	
getMT:
	scp bsc99871@mt1.bsc.es:TGA/project/salida.png .
