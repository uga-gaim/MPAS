# MPAS-A Compilation and Basic Setup

## Preqs

You will need access to the following modules/compilers:

- mpif90

- mpicc 

- netCDF

- netCDF-Fortran

- PnetCDF

---
## Compilation!

The first step in compiling MPAS is to grab it's source code, which is on Github:

`git clone https://github.com/MPAS-Dev/MPAS-Model.git`

Then, move into MPAS-Model: `cd MPAS-Model`. Provided we have the proper compilers, you just need to run:

`make -j# gnu CORE=init_atmosphere`

...where # is the number of jobs you wish to use to compile. 8 is a good number.

You should see a message like this, if successful:

```
*******************************************************************************
MPAS was built with default single-precision reals.
Debugging is off.
Parallel version is on.
Using the mpi_f08 module.
Papi libraries are off.
TAU Hooks are off.
MPAS was built without OpenMP support.
MPAS was built without OpenMP-offload GPU support.
MPAS was built without OpenACC accelerator support.
Position-dependent code was generated.
MPAS was built with .F files.
The native timer interface is being used
Using the SMIOL library.
*******************************************************************************
```

Additionally, there should be new files in the directory: `init_atmosphere_model`, `namelist.init_atmosphere`, and `streams.init_atmosphere`! For WRF users, `init_atmosphere` is essentially MPAS's version of the WRF's WPS, bundled into one neat executable. Next, we need to compile the actual model:

`make -j# gnu CORE=atmosphere`

You might see some warnings while it compiles. You can ignore them if it doesn't crash the compilation. You should see a message like this, if successful:

```
*******************************************************************************
MPAS was built with default single-precision reals.
Debugging is off.
Parallel version is on.
Using the mpi_f08 module.
Papi libraries are off.
TAU Hooks are off.
MPAS was built without OpenMP support.
MPAS was built without OpenMP-offload GPU support.
MPAS was built without OpenACC accelerator support.
Position-dependent code was generated.
MPAS was built with .F files.
The native timer interface is being used
Using the SMIOL library.
*******************************************************************************
```

Now, you should have new files: `atmosphere_model`, `namelist.atmosphere`, `streams.atmosphere`, and a whole bunch of `stream_list.atmosphere.*` files.

It's good practice not to run your simulations directly in this folder, but to instead symlink the executables to a different folder and then copy (not move!) the namelist files into that same folder. I went one folder up and made a new folder named `mpas_sim`, you can name it whatever you like. In this documentation, this is now the MPAS directory.

```sh
cd ../
mkdir mpas_sim
cd mpas_sim
ln -s ../MPAS-Model/init_atmosphere_model .
ln -s ../MPAS-Model/atmosphere_model .
cp ../MPAS-Model/namelist.* .
cp ../MPAS-Model/streams.* .
```

The directory is almost fully setup, but we still need a mesh! You can download your favorite from [here](https://www2.mmm.ucar.edu/projects/mpas/site/downloads/meshes.html), and unpack it. You'll need the .grid.nc and a .graph.part. file. The number at the end of the graph file should correspond to the number of MPI tasks you plan to run MPAS with. You'll also notice these meshes are global and (for variable resolution) centered on 0, 0. If you'd like to change either of those, see `regional_setup.md`.

Bring your mesh `.grid.nc` file and your `.graph.info.part.` file into your MPAS directory. Your directory now has almost all the files it needs to start running MPAS simulations!

---
## Static fields!

Let's setup static fields (aka, geography and land types) for our model. We have to download the geography dataset first... I personally don't like putting the geography dataset into my model directory, so I will go one folder up. We'll use the standard NCAR provided dataset, which extracts into `mpas_static`.

```sh
cd ..
wget https://www2.mmm.ucar.edu/projects/mpas/mpas_static.tar.bz2
tar -xvf mpas_static.tar.bz2
rm mpas_static.tar.bz2
```

Remember to clean up the archive once you're done!

Now, we'll need to start modifying our `namelist.init_atmosphere` and `streams.init_atmosphere`. Because this is essentially every step of the WPS packed in one, we'll have to run it multiple times with different configurations. You can go about this however you want, but I find that making a `templates` folder inside our `mpas_sim` directory and having each step's config saved in a different spot makes things easier, especially when trying to automate a model. In this setup doc, though, I'll assume we're just overwriting the same namelist and streams file each time.

Open your `namelist.init_atmosphere` file and replace **everything** with:

```
&nhyd_model
    config_init_case = 7
/
&data_sources
    config_geog_data_path = '/scratch/mbc18672/mpas/mpas_static'
    config_noahmp_static = false
/
&preproc_stages
    config_static_interp = true
    config_native_gwd_static = true
    config_native_gwd_gsl_static = false
    config_vertical_grid = false
    config_met_interp = false
    config_input_sst = false
    config_frac_seaice = false
/
&decomposition
    config_block_decomp_file_prefix = 'pr.graph.info.part.'
/
```

- `config_geog_data_path` should be YOUR own path to your geography dataset.

- `config_block_decomp_file_prefix` should be the part of YOUR own graph file all the way up to the number.

Open your `streams.init_atmosphere` file and change **these lines** to the following:

```
<immutable_stream name="input"
                  type="input"
                  filename_template="pr.grid.nc"
                  input_interval="initial_only" />

<immutable_stream name="output"
                  type="output"
                  filename_template="pr.static.nc"
                  packages="initial_conds"
                  output_interval="initial_only" />
```

- `input`'s `filename_template` should be the name of your .grid.nc file.

- `output`'s `filename_template` should be the name you want your static fields file to be. Good practice is simply swapping out `grid` for `static`.

- Everything else not specified can remain the same.

Now its time to actually interpolate the static fields! Using your HPC's scheduler (or on the login node if you're a SICKO (just kidding, please schedule it)) run:

`mpiexec -np # ./init_atmosphere_model >& log.init_atmosphere.0000.out`

or, if on a SLURM HPC:

`srun -n # ./init_atmosphere_model`

... where # is the number of MPI jobs to run, EQUAL to the number at the end of your graph file. Ensure you have all the modules required enabled (netCDF and PnetCDF)! Once it starts, you can `tail -f` that log file to watch it.

If all is works just fine, you should see a success message

```
 ********************************************************
    Finished running the init_atmosphere core
 ********************************************************
```

and have a brand new `*.static.nc` file in your MPAS directory! Unless you change meshes or geography datasets (for whatever reason), you won't need to rerun this part again! Hooray!

---
## Forcing/initial and boundary conditions

to come

---
## Sample files

I've included my .sh files to schedule both init_atmosphere and atmosphere models to SLURM under /scripts.

---
## Credit where credit's due

While most of this is from my own workflow, this is kind of an adaptation of part 1 [NCAR's Sept. 2025 MPAS-A Boulder Tutorial](https://www2.mmm.ucar.edu/projects/mpas/tutorial/Boulder2025/) that I attended.
