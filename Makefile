all: test

test: 
	cp projecte.cu projecte.cpp
	g++ -o test project.cpp -lpng -I.

prod:
	scp {project.cpp,readpng.cpp, job.sh} cuda:/scratch/nas/1/cuda07/project/
	ssh cuda 'cd /scratch/nas/1/cuda07/project/; qsub -l cuda job.sh; qstat'
