METIS is used to split your mesh into multiple parts in a .graph file for parallel processing, which is required for MPAS to function with your mesh.

To install METIS:
```
export INSTALL_DIR=(dir)

git clone https://github.com/KarypisLab/GKlib.git
cd GKlib
make config prefix=${INSTALL_DIR}/GKlib
make
make install
cd ..

git clone https://github.com/KarypisLab/METIS.git
cd METIS/
make config prefix=${INSTALL_DIR}/METIS gklib_path=${INSTALL_DIR}/GKlib
make
make install
```
... where (dir) is the directory in which you want METIS to be installed.
