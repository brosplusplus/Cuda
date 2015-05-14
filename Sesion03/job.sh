#!/bin/bash
### Directivas para el gestor de colas
# Asegurar que el job se ejecuta en el directorio actual
#$ -cwd
# Asegurar que el job mantiene las variables de entorno del shell lamador
#$ -V
# Cambiar el nombre del job
#$ -N sesio3
# Cambiar el shell
#$ -S /bin/bash


#nvprof ./kernel00.exe 640 Y
#nvprof ./kernel00.exe 641 Y
#nvprof ./kernel01.exe 640 Y
#nvprof ./kernel01.exe 641 Y
#nvprof ./kernel02.exe 100 800 50
nvprof ./kernel10.exe 6400 Y
#./kernel10.exe 641 Y
#./kernel11.exe 640 Y
#./kernel11.exe 641 Y
#./kernel12.exe 128 2048 48
