all: test

test: 
	cp projecte.cu projecte.cpp
	g++ -o test project.cpp -lpng -I.

prod:
	scp projecte.cu cuda:/scratch/nas/1/cuda07/project/
	scp readpng.cpp cuda:/scratch/nas/1/cuda07/project/
	scp job.sh 			cuda:/scratch/nas/1/cuda07/project/
	ssh cuda 'cd /scratch/nas/1/cuda07/project/; make ; qsub -l cuda job.sh; qstat'

get:
	scp cuda:/scratch/nas/1/cuda07/project/salida.png .
