# MPAS-A Regional Variable Resolution Mesh Setup

## Preqs

In order to setup a regional simulation (or even a global sim!) you will need to grab a mesh from here:

https://www2.mmm.ucar.edu/projects/mpas/site/downloads/meshes.html

This contains both quasi-uniform meshses that are a consistent resolution across the entire mesh and variable resolution meshes, which dynamically refine in. While this tutorial should work for a quasi-uniform mesh, it will be primarily focused on running a variable resolution regional simulation.

These archives will contain a .grid.nc file (your actual mesh) and a multitude of graph files (used to parallelize MPAS). Grab the mesh file and, if running a global sim, the graph file that corresponds to the exact number of MPI tasks you plan to use for your simulation (if your number is not on there, we'll make a new one later on anyways for regional sims!)

Additionally, for running a regional simulation, you will need these three tools:

- [MPAS-Tools](https://github.com/MPAS-Dev/MPAS-Tools)

- [MPAS-Limited-Area](https://github.com/MPAS-Dev/MPAS-Limited-Area)

- gpmetis. See instructions:

METIS is used to split your mesh into multiple parts in a .graph file for parallel processing, which is required for MPAS to function with your mesh.

To install METIS:
```sh
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


For some more finer control over resolution, you may also like to grab:

- [scale-region](https://github.com/mgduda/scale_region)

You will also need a Conda (or otherwise) environment that has:

- netcdf4

- netcdf-fortran

- numpy

- A Fortran compiler (conda install -c conda-forge fortran-compiler should suffice)

(for supplemental `mesh_resolution.py`)

- xarray

- cartopy

These instructions do not necessarily have to be run on your HPC cluster, as I ran them all on my home desktop running Arch Linux. These instructions should also work for Windows and Mac systems, but I haven't tested those out properly.

## Setup!

Firstly, grab a lat, lon of where you intend the *center* of your mesh to be. You can use Google Maps or OpenStreetMap to find coordinates. In this example, I roughly eyeballed the center of Puerto Rico on Google Maps to be 18.22660024342388, -66.4777993164418. I'm also deciding to use the 15-3km (Circular Refinement) Mesh.

---

Now, lets first move the center of this mesh to wherever you have `grid_rotate`, an MPAS-Tools utility. This should be within `MPAS-Tools/mesh_tools/grid_rotate`. Run `make` to build the utility. Once it's made, grab your `.grid.nc` file from the archive and move it into the directory. 

Before we start, we need to modify the `namelist.input`! These NCAR provided meshes are already centered at (0,0), so you can ignore the original settings. Modify the new lat, lon to your liking. As hinted by the utility name, you can also rotate your mesh here too, if needed! 

All that's left is to run the file: `./grid_rotate (input grid name) (output grid name)`. I named my grid `x5.6488066.rotated.grid.nc`, but you can do whatever you wish. It's good practice to leave it ending in `*.grid.nc`. This might take a minute or two with a high resolution mesh. 

If you just want to rotate where your global variable resolution grid refines into, then you're done! You should be able to use the same .graph.info.part. file in your MPAS simulations.

---

(Optional) If you'd like more control over the resolution of your final mesh, then we can use the `scale-region` tool! Bring your new rotated mesh into the folder and run: `python ./scale_region.py (input grid name) (output grid name) (scale factor) (lat) (lon)`, where:

- (input grid name) is the name of your input grid

- (output grid name) is the name of the resultant scaled grid. Following a similar structure as the rotation, i went with `x5.6488066.scaled.grid.nc`.

- (scale factor) is the factor you wish to scale your resolution by (i.e. 3.0 will triple resolution, sharpening a 15-3km grid down to 5-1km.)

- (lat) & (lon) are the lat, lon of the center point of your grid.

This can take a good bit of time, depending on resolution and scale factor. It is quite memory intensive! Scaling my 15-3km with a scale factor of 2.0 took just around 1hr15min and ~8gb of mem! If you haven't yet already, this would be a great time to look at `compile.md` and begin setting up and compiling MPAS on your HPC cluster.

In case you want a view of what your mesh looks like after this process, I've provided a `mesh_resolution.py` script from NCAR's MPAS-A tutorial in this repo's scripts (/scripts) that will output an image with approx. mesh resolutions contoured. You can run it with `python ./mesh_resolution.py (grid file)`. This'll output a plot of the mesh resolution to your pwd under `mesh_resolution.png`.

---

Next, we're going to take this modified (either rotated OR rotated + scaled) mesh and make it so that it only contains a regional area vs the entire world. Move your new `.grid.nc` file to wherever you have MPAS-Limited-Area. Within that folder, go into /docs/points-example, and grab a points file that appropriate for your mesh. Because I'm trying to do a regional sim around PR, the india.circle.pts should do just fine. Copy that up back into the parent `MPAS-Limited-Area` folder.

Open that pts file and modify it to your liking. Because I'm using the circle, all I need to specify is the center in lat, lon. The name may be whatever you wish, and it will dictate the name of the resultant new `.grid.nc` file (i.e. if name is `pr`, then you will get `pr.grid.nc`). If you are using something other than Circle, see the documentation [here](https://github.com/MPAS-Dev/MPAS-Limited-Area?tab=readme-ov-file#points-pts-syntax) for more specific info. When you've modified to whatever degree you like, copy that points file into the parent repo folder. 

Once ready, run `python ./create_region (pts file) (grid file)`. This may take a some time, especially depending on your mesh resolution and size of your region. You can also preview what your region would look like with `python ./create_region --plots (pts file)`, which creates a plot under `region.png`.

This may take some iterating to find the perfect mesh, but in this repo's scripts (/scripts) directory I've included a `mesh_resolution.py` script provided from NCAR MPAS-A tutorials to output an image to give you a rough idea of what your regional mesh may look like with approx resolution contoured. If you followed the optional part, this is the same script. You can run it with `python ./mesh_resolution.py (grid file)`. This'll output a plot of the mesh resolution to your pwd under `mesh_resolution.png`.

(?) Now, for reasons that are not really well documented, putting a variable resolution mesh in here will *not* proprotionally scale down your mesh but will instead simply cut out everything outside of it. So, if you have a 5-1km mesh and only set the area below 1.5km inside your limited area, you will end up with a 1.5km-1km limited area mesh.

All that's left to do is to section the new graph file into however many MPI tasks we plan to run our model with. With gpmetis (located in ./METIS/bin/), run: `./gpmetis /path/to/(.graph.info) #`, where # is the number of MPI tasks you plan to run with. This should output a file with the format of `(name).grid.info.part.#` in the same directory as the `.graph.info` file.

We now have everything we'll need to do a regional sim! Simply copy the new `grid.nc` and `.graph.info.part.` files into where you're prepping your MPAS simulation and continue on the guide!

---
## Sample files
In this repo's /files/, my test PR mesh that I created alongside this document can be found should you wish to poke at the finished products yourself.

---
## Credit where credit's due:

While most of this is from my own workflow, this is essentially combining parts #4 and #5 from [NCAR's Sept. 2025 MPAS-A Boulder Tutorial](https://www2.mmm.ucar.edu/projects/mpas/tutorial/Boulder2025/)
