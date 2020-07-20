module load gcc/6.4.0 cmake git openmpi cuda
module unload xalt
cd /tmp  #MUST be built in tmp - building in home or proj causes issues

git clone https://github.com/JuliaLang/julia
cd julia

git checkout v1.4.2

cat <<EOF > Make.user
USE_BINARYBUILDER=0
EOF

make	#ignore install directions - do not try to build in parallel

PREFIX=$1 	#do not use home directory; proj is OK

make prefix=${PREFIX} install

eval `make print-JULIA_VERSION`
mkdir -p ${HOME}/modulefiles/julia/

cat <<EOF > ${HOME}/modulefiles/julia/${JULIA_VERSION}.lua
whatis("Name : julia v${JULIA_VERSION}")
whatis("Short description : The Julia programming language.")
help([[The Julia programming language.]])
depends_on("gcc/6.4.0")
always_load("cmake")
add_property("state","experimental")
prepend_path("PATH","${PREFIX}/bin")
EOF

cd $1/bin

./julia -e 'using Pkg; Pkg.API.precompile(); Pkg.add("MPI"); Pkg.add("CUDA")'

#AFTER INSTALLATION
#add julia to path

#TO RUN
#module load gcc/6.4.0 cmake
#module unload xalt

#TO USE MPI/CUDA
#module load openmpi cuda
#put 'using mpi'/'using cuda' at the top of script
#enter interactive job or batch script
#use a jsrun command like: jsrun -n1 -g1 --smpiargs="-gpu" julia myprogram.jl


