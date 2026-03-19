# MPAS-A Compilation and Basic Setup

## Preqs

You will need access to the following modules/compilers:

- mpif90

- mpicc 

- netCDF netCDF/4.9.3-gompi-2025a

- netCDF-Fortran

- PnetCDF PnetCDF/1.12.3-gompi-2023b

---
## Compilation!

The first step in compiling MPAS is to grab its source code, which is on Github:

`git clone https://github.com/MPAS-Dev/MPAS-Model.git`

Then, move into MPAS-Model: `cd MPAS-Model`. Provided we have the proper compilers, you just need to run:

`make -j# gnu CORE=init_atmosphere`

...where # is the number of jobs you wish to use to compile. 8 is a good number. Also, we're using `gnu` compilers here, but if your HPC uses different compilers i.e. `intel` then you'd swap it out.

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

Additionally, there should be new files in the directory: `init_atmosphere_model`, `namelist.init_atmosphere`, and `streams.init_atmosphere`! For WRF users, `init_atmosphere` is essentially MPAS's version of the WRF's WRF Preprocessing System (WPS), bundled into one neat executable. Next, we need to compile the actual model:

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

Open your `namelist.init_atmosphere` file and modify these lines:

```
&nhyd_model
    config_init_case = 7
    config_start_time = '2026-03-11_12:00:00'
    config_stop_time = '2026-03-11_12:00:00'
    config_theta_adv_order = 3
    config_coef_3rd_order = 0.25
/
&dimensions
    config_nvertlevels = 55
    config_nsoillevels = 4
    config_nfglevels = 38
    config_nfgsoillevels = 4
/
&data_sources
    config_geog_data_path = '/scratch/mbc18672/mpas/mpas_static'
    config_met_prefix = 'GFS'
    config_sfc_prefix = 'SST'
    config_fg_interval = 86400
    config_landuse_data = 'MODIFIED_IGBP_MODIS_NOAH'
    config_topo_data = 'GMTED2010'
    config_vegfrac_data = 'MODIS'
    config_albedo_data = 'MODIS'
    config_maxsnowalbedo_data = 'MODIS'
    config_supersample_factor = 3
    config_use_spechumd = false
    config_noahmp_static = false
/
&vertical_grid
    config_ztop = 30000.0
    config_nsmterrain = 1
    config_smooth_surfaces = true
    config_dzmin = 0.3
    config_nsm = 30
    config_tc_vertical_grid = true
    config_blend_bdy_terrain = true
/
&interpolation_control
    config_extrap_airtemp = 'lapse-rate'
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
&io
    config_pio_num_iotasks = 0
    config_pio_stride = 1
/
&decomposition
    config_block_decomp_file_prefix = 'pr.graph.info.part.'
/
```

MAKE SURE these are set from the defaults:

- `config_init_case = 7`

- `config_geog_data_path` should be YOUR own path to your geography dataset.

- `config_noahmp_static = false` should be ADDED underneath the data path

- Under `&preproc_stages`

    - `config_static_interp = true`

    - `config_native_gwd_static = true` 

    - `config_native_gwd_gsl_static = false`

    - `config_vertical_grid = false`

    - `config_met_interp = false`

    - `config_input_sst = false`

    - `config_frac_seaice = false`

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

By default, MPAS's 'clobber mode' is set to `never_modify`, which means that should you ever re-run the model, it will refuse to overwrite any files but it will *not* fail. If you wish to have the model automatically overwrite any file it's already made, add `clobber_mode="overwrite"`. It doesn't matter that much here, as you won't be recomputing your static fields a lot, but when you're doing repeated reprocessing and down the line, it may help!

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
## Forcing/initial and boundary conditions!

### Welcome Back ungrib!

**If you plan on JUST using ERA5/ungribbed data, this part can be skipped unless you'd like to be prepared for the instance you will need to use real model data.**

Now that we have our static fields set and ready to go, next we need to give our model its initial forcing data and (if running a regional sim) boundary conditions. MPAS can ingest datasets from a model like the GFS and reanalysis like ERA5, but as of now the main branch of MPAS CANNOT support datasets from models like HRRR and NAM due to issues with soil levels.[^1]

Now, above, while I said `init_atmosphere_model` is essentially the WRF WPS all in one executable, there still is one part of the WPS that we require: `ungrib`. Clone WPS to a location of your choosing (good practice: the parent folder of `mpas_sim`.)

```sh
cd ..
git clone https://github.com/wrf-model/WPS.git
cd WPS
```

Now that we're in the `WPS` folder, we will need to configure it! We'll run this:

`./configure --nowrf --build-grib2-libs`

... which tells WPS not to look for an already compiled WRF model and compiles libraries for ungrib to work. You will be given a screen to select the platform you will be compiling for. Choose the one that corresponds to the compiler on your HPC with the serial option! Once you've done that, all thats left to do is to compile ungrib:

`./compile ungrib`

We don't need to compile the entirety of the WPS, so we just specify only to compile ungrib. This may take a minute or two to finish, and it doesn't really give a pretty "finished!" message, so you should go confirm if it actually compiled before moving on. Run this afterwards while inside the WPS folder, and if you get a similar message and file-size you should be good to go:

```sh
mbc18672@c4-16 WPS$ ls -lh ./ungrib/src/ungrib.exe
-rwxr-xr-x 1 mbc18672 whlab 2414408 Mar 11 15:52 ./ungrib/src/ungrib.exe
```

The next part of this guide splits into two paths depending on the type of dataset you're using: gribbed model data (in this guide, GFS) or netCDF reanalysis data (in this guide, ERA5). For a quick sanity check, let's look at what your parent directory should contain. Here's the results of me running `tree -Ld 1`, which lists out the folders in the current directory and then the folders INSIDE those folders:

```sh
mbc18672@c4-16 mpas$ tree -Ld 2
.
├── MPAS-Model
│   ├── cmake
│   ├── default_inputs
│   ├── docs
│   ├── src
│   └── testing_and_setup
├── WPS
│   ├── arch
│   ├── cmake
│   ├── external
│   ├── geogrid
│   ├── grib2
│   ├── metgrid
│   ├── ungrib
│   └── util
├── mpas_sim
│   └── templates
└── mpas_static
    ├── albedo_modis
    ├── albedo_ncep
    ├── greenfrac
    ├── greenfrac_fpar_modis
    ├── landuse_30s
    ├── maxsnowalb
    ├── maxsnowalb_modis
    ├── modis_landuse_20class_30s
    ├── soilgrids
    ├── soiltemp_1deg
    ├── soiltype_top_30s
    ├── topo_30s
    └── topo_gmted2010_30s

35 directories
```

It doesn't have to look exact (especially if you use different folder names or a different organization structure), but if it's similar, you're so far so good!

### Using GFS Data

(If you understand how to use ungrib, this part of the guide may just be review!)

If you are using another dataset than GFS, remember to update configurations as needed (namelists, Vtables, directory naming, etc.) and also know the provided download script will ONLY automate GFS downloads.

We'll first need to collect the GFS datasets we'll be using. Let's lay the groundwork and set up a structure to store our files in. You can do this your own way, but I'm going to go back up to the parent folder and create a new `DATA` folder which will then have subfolders of `GFS`, `ERA5`, and `METDATA`.

```sh
cd ..
mkdir DATA
cd DATA
mkdir GFS
mkdir ERA5
mkdir METDATA
```

While you could manually go to NOAA NOMADS and manually download hourly GFS gribbed data, I've provided the script our UGA-MPAS model uses to automatically fetch these files inside `/scripts/gfs_pre01_download.sh`. Go into that script and change `DATA_DIR="/path/to/download/DATA/GFS"` to whatever path you've decided you want your GFS data to be downloaded to. Now, when we run this script we will download hours 0-##, where ## is whatever you decide (up to 384) as the script's argument. This guide will prepare our model for a simple 24-hour run, but these instructions should work for runs of any length. Let's run our script:

```sh
chmod +x gfs_pre01_download.sh
./gfs_pre01_download.sh 24
```

`chmod +x` marks our file as executable, if not already marked. Now we must wait for all the files to finish downloading, which depends heavily on the amount of hours you chose and internet speed of your HPC. When it finishes, you should get a similar message to:

`All GFS files downloaded successfully to /scratch/mbc18672/mpas/DATA/GFS`

... using your own data path. Head to your data directory where your GFS data is stored and run `ls -l`.

```sh
mbc18672@c4-16 GFS$ ls -l
total 11105773
-rw-r--r-- 1 mbc18672 whlab 510710733 Mar 11 11:32 gfs.t12z.pgrb2.0p25.f000
-rw-r--r-- 1 mbc18672 whlab 542346908 Mar 11 11:32 gfs.t12z.pgrb2.0p25.f001
-rw-r--r-- 1 mbc18672 whlab 544136015 Mar 11 11:32 gfs.t12z.pgrb2.0p25.f002
-rw-r--r-- 1 mbc18672 whlab 545561658 Mar 11 11:33 gfs.t12z.pgrb2.0p25.f003
-rw-r--r-- 1 mbc18672 whlab 543540371 Mar 11 11:33 gfs.t12z.pgrb2.0p25.f004
-rw-r--r-- 1 mbc18672 whlab 545450213 Mar 11 11:33 gfs.t12z.pgrb2.0p25.f005
-rw-r--r-- 1 mbc18672 whlab 547246385 Mar 11 11:34 gfs.t12z.pgrb2.0p25.f006
-rw-r--r-- 1 mbc18672 whlab 545255414 Mar 11 11:34 gfs.t12z.pgrb2.0p25.f007
-rw-r--r-- 1 mbc18672 whlab 545966342 Mar 11 11:34 gfs.t12z.pgrb2.0p25.f008
-rw-r--r-- 1 mbc18672 whlab 548019963 Mar 11 11:34 gfs.t12z.pgrb2.0p25.f009
-rw-r--r-- 1 mbc18672 whlab 547616955 Mar 11 11:34 gfs.t12z.pgrb2.0p25.f010
-rw-r--r-- 1 mbc18672 whlab 547770205 Mar 11 11:35 gfs.t12z.pgrb2.0p25.f011
-rw-r--r-- 1 mbc18672 whlab 549861686 Mar 11 11:35 gfs.t12z.pgrb2.0p25.f012
-rw-r--r-- 1 mbc18672 whlab 545379320 Mar 11 11:35 gfs.t12z.pgrb2.0p25.f013
-rw-r--r-- 1 mbc18672 whlab 548745114 Mar 11 11:35 gfs.t12z.pgrb2.0p25.f014
-rw-r--r-- 1 mbc18672 whlab 547414283 Mar 11 11:36 gfs.t12z.pgrb2.0p25.f015
-rw-r--r-- 1 mbc18672 whlab 547789611 Mar 11 11:36 gfs.t12z.pgrb2.0p25.f016
-rw-r--r-- 1 mbc18672 whlab 549778021 Mar 11 11:36 gfs.t12z.pgrb2.0p25.f017
-rw-r--r-- 1 mbc18672 whlab 549684424 Mar 11 11:37 gfs.t12z.pgrb2.0p25.f018
-rw-r--r-- 1 mbc18672 whlab 548082784 Mar 11 11:37 gfs.t12z.pgrb2.0p25.f019
-rw-r--r-- 1 mbc18672 whlab 550309999 Mar 11 11:37 gfs.t12z.pgrb2.0p25.f020
-rw-r--r-- 1 mbc18672 whlab 550641063 Mar 11 11:38 gfs.t12z.pgrb2.0p25.f021
-rw-r--r-- 1 mbc18672 whlab 550672780 Mar 11 11:38 gfs.t12z.pgrb2.0p25.f022
-rw-r--r-- 1 mbc18672 whlab 551411968 Mar 11 11:38 gfs.t12z.pgrb2.0p25.f023
-rw-r--r-- 1 mbc18672 whlab 552035742 Mar 11 11:38 gfs.t12z.pgrb2.0p25.f024
```

Take note of the model run time (in this case, the 11th @ 12z)[^2] and how many hours you downloaded (F0-F24). Head back to your WPS folder and modify the following lines in `namelist.wps`:

```
&share
...
 start_date = '2026-03-11_12:00:00',
 end_date   = '2026-03-12_12:00:00',
 interval_seconds = 3600
/

&ungrib
 out_format = 'WPS',
 prefix = 'GFS',
/
```

Now, we'll need to symlink a variable table to the base of the WPS directory for ungrib to understand how to unpack our GFS files. These are located in `./ungrib/Variable_Tables`.

`ln -s ./ungrib/Variable_Tables/Vtable.GFS Vtable`

The name of the symlinked variable table **must** just be `Vtable`! Now we'll need to symlink our GFS datasets to this folder, for which a script is given to us to automatically do it within WPS.

`./link_grib.csh /scratch/mbc18672/mpas/DATA/GFS/gfs.*.f*`

... making sure to swap the path to where **your** GFS gribbed files are. Now we're ready to run ungrib!

`./ungrib.exe`

This may take some time. When finished, you should see this:

```
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!  Successful completion of ungrib.   !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
```

and your WPS directory should be full of file starting with `GFS:*`:

```sh
mbc18672@c4-16 WPS$ ls -l GFS*
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:13 GFS:2026-03-11_12
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:14 GFS:2026-03-11_13
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:14 GFS:2026-03-11_14
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:14 GFS:2026-03-11_15
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:14 GFS:2026-03-11_16
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:15 GFS:2026-03-11_17
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:15 GFS:2026-03-11_18
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:15 GFS:2026-03-11_19
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:15 GFS:2026-03-11_20
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:15 GFS:2026-03-11_21
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:16 GFS:2026-03-11_22
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:16 GFS:2026-03-11_23
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:16 GFS:2026-03-12_00
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:16 GFS:2026-03-12_01
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:17 GFS:2026-03-12_02
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:17 GFS:2026-03-12_03
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:17 GFS:2026-03-12_04
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:17 GFS:2026-03-12_05
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:18 GFS:2026-03-12_06
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:18 GFS:2026-03-12_07
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:18 GFS:2026-03-12_08
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:18 GFS:2026-03-12_09
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:18 GFS:2026-03-12_10
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:19 GFS:2026-03-12_11
-rw-r--r-- 1 mbc18672 whlab 818178824 Mar 11 17:19 GFS:2026-03-12_12
```

These files can now be moved into our `METDATA` (or equivalent) folder to prepare them to be used with `init_atmosphere_model`. We can then go ahead and symlink this to our `mpas_sim` folder (or, you can skip the `METDATA` copy and directly put in into your sim folder. Up to you!).

```sh
mv GFS:* ../DATA/METDATA/
ln -s ../DATA/METDATA/GFS* ../mpas_sim
```

Now that our forcing data is in the folder, lets interpolate them to our grid. Check out the section after the next one! 

### Using ERA5 Data

coming soon :-)

### Interpolating ICs to grid

We'll need to edit our `namelist.init_atmosphere` and `streams.init_atmosphere` again...

Here's what your namelist.init_atmosphere should look like:

```
&nhyd_model
    config_init_case = 7
    config_start_time = '2026-03-11_12:00:00'
    config_stop_time = '2026-03-11_12:00:00'
    config_theta_adv_order = 3
    config_coef_3rd_order = 0.25
/
&dimensions
    config_nvertlevels = 55
    config_nsoillevels = 4
    config_nfglevels = 38
    config_nfgsoillevels = 4
/
&data_sources
    config_geog_data_path = '/scratch/mbc18672/mpas/mpas_static'
    config_met_prefix = 'GFS'
    config_sfc_prefix = 'SST'
    config_fg_interval = 86400
    config_landuse_data = 'MODIFIED_IGBP_MODIS_NOAH'
    config_topo_data = 'GMTED2010'
    config_vegfrac_data = 'MODIS'
    config_albedo_data = 'MODIS'
    config_maxsnowalbedo_data = 'MODIS'
    config_supersample_factor = 3
    config_use_spechumd = false
    config_noahmp_static = false
/
&vertical_grid
    config_ztop = 30000.0
    config_nsmterrain = 1
    config_smooth_surfaces = true
    config_dzmin = 0.3
    config_nsm = 30
    config_tc_vertical_grid = true
    config_blend_bdy_terrain = true
/
&interpolation_control
    config_extrap_airtemp = 'lapse-rate'
/
&preproc_stages
    config_static_interp = false
    config_native_gwd_static = false
    config_native_gwd_gsl_static = false
    config_vertical_grid = true
    config_met_interp = true
    config_input_sst = false
    config_frac_seaice = true
/
&io
    config_pio_num_iotasks = 0
    config_pio_stride = 1
/
&decomposition
    config_block_decomp_file_prefix = 'pr.graph.info.part.'
/
```

... ensuring:

- `config_start_time` and `config_stop_time` is the time of the FIRST forcing file you have (`config_stop_time` can remain untouched here.). Format is `YYYY-MM-DD_hh:mm:ss`

- `config_met_prefix` should be `GFS` or `ERA5` (unless you use a different IC source, in which case it'll be whatever is before the : in the file name.)

- Under `&preproc_stages`:

    - `config_static_interp = false`

    - `config_native_gwd_static = false`

    - `config_native_gwd_gsl_static = false`

    - `config_vertical_grid = true`

    - `config_met_interp = true`

    - `config_input_sst = false`

    - `config_frac_seaice = true`

- `config_block_decomp_file_prefix` remains the prefix of your graph file.

And in the `streams.init_atmosphere`, change these fields:

```
<immutable_stream name="input"
                  type="input"
                  filename_template="pr.static.nc"
                  input_interval="initial_only" />

<immutable_stream name="output"
                  type="output"
                  filename_template="pr.init.nc"
                  packages="initial_conds"
                  output_interval="initial_only" />
```

... we're simply changing the input to our new static field and the output to a new interpolated IC file!

After that, simply rerun the model!

`mpiexec -np # ./init_atmosphere_model >& log.init_atmosphere.0000.out`

or, if on a SLURM HPC:

`srun -n # ./init_atmosphere_model`

Again, # is number of MPI jobs, equal to the number at the end of the graph file you will be using. You should tail your log file again to watch its status, but you can go hands off while it runs. It shouldn't take that long, and you should get a similar success message.

We should now have an IC-interpolated grid under the name `*.init.nc`! We're almost ready for an actual simulation, but first we need LBCs if running a regional sim! If you're not running a regional sim, then you can proceed directly to running the `atmosphere` core.

### Creating LBCs

Lateral boundary conditions (LBC) let our regional model know whats happening outside its bounds. We'll simply use the GFS forcing data we already have for this! Again, the namelist.init_atmosphere file will need to be edited:

```
&nhyd_model
    config_init_case = 9
    config_start_time = '2026-03-11_12:00:00'
    config_stop_time = '2026-03-12_12:00:00'
    config_theta_adv_order = 3
    config_coef_3rd_order = 0.25
/
&dimensions
    config_nvertlevels = 55
    config_nsoillevels = 4
    config_nfglevels = 38
    config_nfgsoillevels = 4
/
&data_sources
    config_geog_data_path = '/scratch/mbc18672/mpas/mpas_static'
    config_met_prefix = 'GFS'
    config_sfc_prefix = 'SST'
    config_fg_interval = 10800
    config_landuse_data = 'MODIFIED_IGBP_MODIS_NOAH'
    config_topo_data = 'GMTED2010'
    config_vegfrac_data = 'MODIS'
    config_albedo_data = 'MODIS'
    config_maxsnowalbedo_data = 'MODIS'
    config_supersample_factor = 3
    config_use_spechumd = false
    config_noahmp_static = false
/
&vertical_grid
    config_ztop = 30000.0
    config_nsmterrain = 1
    config_smooth_surfaces = true
    config_dzmin = 0.3
    config_nsm = 30
    config_tc_vertical_grid = true
    config_blend_bdy_terrain = true
/
&interpolation_control
    config_extrap_airtemp = 'lapse-rate'
/
&preproc_stages
    config_static_interp = false
    config_native_gwd_static = false
    config_native_gwd_gsl_static = false
    config_vertical_grid = true
    config_met_interp = true
    config_input_sst = false
    config_frac_seaice = true
/
&io
    config_pio_num_iotasks = 0
    config_pio_stride = 1
/
&decomposition
    config_block_decomp_file_prefix = 'pr.graph.info.part.'
/
```

Make sure:

- `config_init_case = 9`, letting `init_atmosphere` know we're wanting to do LBCs.

- `config_start_time` and `config_stop_time` should be equal to the dates of your first AND last forcing files. Format is `YYYY-MM-DD_hh:mm:ss`

- `config_fg_interval` should be set to how often you wish to create new LBCs, in seconds. 3 hours should work fine, but you may go lower or higher (just ensure you actually have data available for those times! i.e. if you do hourly LBCs make sure you have *hourly* forcing data).

- `config_met_prefix = 'GFS'`, or `ERA5`, or whatever prefix your forcing data uses.

In `streams.init_atmosphere`:

```
<streams>
<immutable_stream name="input"
                  type="input"
                  filename_template="pr.init.nc"
                  input_interval="initial_only" />

<immutable_stream name="output"
                  type="output"
                  filename_template="null"
                  packages="initial_conds"
                  output_interval="initial_only" />

<immutable_stream name="lbc"
                  type="output"
                  filename_template="lbc.$Y-$M-$D_$h.$m.$s.nc"
                  filename_interval="output_interval"
                  packages="lbcs"
                  output_interval="3:00:00" />
</streams>
```

- Make sure your input `filename_template` is now your `init` grid.

- Set your output `filename_template` to `null`. This output stream will not be used in LBC generation, but MPAS will fail without a proper output.

- Set your lbc `output_interval` equal to whatever your `config_fg_interval` is, in hours. I used 10800, which is 3 hours.

Now for the final time, lets run `init_atmosphere`!

`mpiexec -np # ./init_atmosphere_model >& log.init_atmosphere.0000.out`

or, if on a SLURM HPC:

`srun -n # ./init_atmosphere_model`

Upon completion, you should have files starting with `lbc.*` in your `mpas_sim` directory!

```sh
mbc18672@ss-sub1 mpas_sim$ ls -l lbc*
-rw-r--r-- 1 mbc18672 whlab 3145692216 Mar 18 18:18 lbc.2026-03-11_12.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3145692216 Mar 18 18:18 lbc.2026-03-11_15.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3145692216 Mar 18 18:18 lbc.2026-03-11_18.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3145692216 Mar 18 18:19 lbc.2026-03-11_21.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3145692216 Mar 18 18:19 lbc.2026-03-12_00.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3145692216 Mar 18 18:20 lbc.2026-03-12_03.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3145692216 Mar 18 18:20 lbc.2026-03-12_06.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3145692216 Mar 18 18:21 lbc.2026-03-12_09.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3145692216 Mar 18 18:21 lbc.2026-03-12_12.00.00.nc
```

We are FINALLY ready to run the `atmosphere` model and do our actual simulations! Let's quickly do a sanity check of what should be in our `mpas_sim` directory:

```sh
mbc18672@ss-sub1 mpas_sim$ ls -lh
total 43G
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-11_12 -> ../DATA/METDATA/GFS:2026-03-11_12
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-11_13 -> ../DATA/METDATA/GFS:2026-03-11_13
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-11_14 -> ../DATA/METDATA/GFS:2026-03-11_14
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-11_15 -> ../DATA/METDATA/GFS:2026-03-11_15
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-11_16 -> ../DATA/METDATA/GFS:2026-03-11_16
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-11_17 -> ../DATA/METDATA/GFS:2026-03-11_17
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-11_18 -> ../DATA/METDATA/GFS:2026-03-11_18
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-11_19 -> ../DATA/METDATA/GFS:2026-03-11_19
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-11_20 -> ../DATA/METDATA/GFS:2026-03-11_20
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-11_21 -> ../DATA/METDATA/GFS:2026-03-11_21
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-11_22 -> ../DATA/METDATA/GFS:2026-03-11_22
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-11_23 -> ../DATA/METDATA/GFS:2026-03-11_23
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-12_00 -> ../DATA/METDATA/GFS:2026-03-12_00
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-12_01 -> ../DATA/METDATA/GFS:2026-03-12_01
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-12_02 -> ../DATA/METDATA/GFS:2026-03-12_02
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-12_03 -> ../DATA/METDATA/GFS:2026-03-12_03
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-12_04 -> ../DATA/METDATA/GFS:2026-03-12_04
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-12_05 -> ../DATA/METDATA/GFS:2026-03-12_05
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-12_06 -> ../DATA/METDATA/GFS:2026-03-12_06
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-12_07 -> ../DATA/METDATA/GFS:2026-03-12_07
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-12_08 -> ../DATA/METDATA/GFS:2026-03-12_08
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-12_09 -> ../DATA/METDATA/GFS:2026-03-12_09
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-12_10 -> ../DATA/METDATA/GFS:2026-03-12_10
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-12_11 -> ../DATA/METDATA/GFS:2026-03-12_11
lrwxrwxrwx 1 mbc18672 whlab   33 Mar 18 16:27 GFS:2026-03-12_12 -> ../DATA/METDATA/GFS:2026-03-12_12
lrwxrwxrwx 1 mbc18672 whlab   30 Mar  9 18:09 atmosphere_model -> ../MPAS-Model/atmosphere_model
lrwxrwxrwx 1 mbc18672 whlab   35 Mar  9 18:09 init_atmosphere_model -> ../MPAS-Model/init_atmosphere_model
-rw-r--r-- 1 mbc18672 whlab 3.0G Mar 18 18:18 lbc.2026-03-11_12.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3.0G Mar 18 18:18 lbc.2026-03-11_15.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3.0G Mar 18 18:18 lbc.2026-03-11_18.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3.0G Mar 18 18:19 lbc.2026-03-11_21.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3.0G Mar 18 18:19 lbc.2026-03-12_00.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3.0G Mar 18 18:20 lbc.2026-03-12_03.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3.0G Mar 18 18:20 lbc.2026-03-12_06.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3.0G Mar 18 18:21 lbc.2026-03-12_09.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 3.0G Mar 18 18:21 lbc.2026-03-12_12.00.00.nc
-rw-r--r-- 1 mbc18672 whlab 2.0K Mar  9 18:10 namelist.atmosphere
-rw-r--r-- 1 mbc18672 whlab 1.5K Mar 18 18:16 namelist.init_atmosphere
-rwxr-xr-x 1 mbc18672 whlab 4.1M Mar  9 19:37 pr.graph.info.part.30
-rwxr-xr-x 1 mbc18672 whlab 1.7G Mar 18 17:59 pr.grid.nc
-rw-r--r-- 1 mbc18672 whlab  13G Mar 18 18:14 pr.init.nc
-rw-r--r-- 1 mbc18672 whlab 2.4G Mar 18 18:08 pr.static.nc
-rw-r--r-- 1 mbc18672 whlab 2.5K Mar  9 18:10 streams.atmosphere
-rw-r--r-- 1 mbc18672 whlab 1.2K Mar 18 18:16 streams.init_atmosphere
```

Like before, this doesn't need to be exactly equal, but if it looks similar after following this guide, you're on the right path!

---
## Running MPAS-A

We have the `atmosphere_model` symlinked to our `mpas_sim` directory and the namelist/streams files, but we'll also need to bring over lookup tables for our physics scheme before we start! These are located in the compiled MPAS-Model directory. We'll also need the `stream_list.atmosphere.*` files.

```sh
ln -s ../MPAS-Model/src/core_atmosphere/physics/physics_wrf/files/* .
cp ../MPAS-Model/stream_list.atmosphere.* .
```

Checking your directory, there should now be handful of files ending in `.TBL`, `.DATA`, and `.DATA.DBL`. Now, let's open our `namelist.atmosphere` and make these changes:

```
&nhyd_model
    config_time_integration_order = 2
    config_dt = 6.6
    config_start_time = '2026-03-11_12:00:00'
    config_run_duration = '1_00:00:00'
    config_split_dynamics_transport = true
    config_number_of_sub_steps = 2
    config_dynamics_split_steps = 3
    config_horiz_mixing = '2d_smagorinsky'
    config_visc4_2dsmag = 0.05
    config_scalar_advection = true
    config_monotonic = true
    config_coef_3rd_order = 0.25
    config_epssm = 0.1
    config_smdiv = 0.1
/
&damping
    config_zd = 22000.0
    config_xnutr = 0.2
/
&limited_area
    config_apply_lbcs = true
/
&io
    config_pio_num_iotasks = 0
    config_pio_stride = 1
/
&decomposition
    config_block_decomp_file_prefix = 'pr.graph.info.part.'
/
&restart
    config_do_restart = false
/
&printout
    config_print_global_minmax_vel = true
    config_print_detailed_minmax_vel = false
/
&IAU
    config_IAU_option = 'off'
    config_IAU_window_length_s = 21600.
/
&physics
    config_sst_update = false
    config_sstdiurn_update = false
    config_deepsoiltemp_update = false
    config_radtlw_interval = '00:30:00'
    config_radtsw_interval = '00:30:00'
    config_bucket_update = 'none'
    config_physics_suite = 'convection_permitting'
/
&soundings
    config_sounding_interval = 'none'
/
&physics_lsm_noahmp
    config_noahmp_iopt_dveg = 4
    config_noahmp_iopt_crs = 1
    config_noahmp_iopt_btr = 1
    config_noahmp_iopt_runsrf = 3
    config_noahmp_iopt_runsub = 3
    config_noahmp_iopt_sfc = 1
    config_noahmp_iopt_frz = 1
    config_noahmp_iopt_inf = 1
    config_noahmp_iopt_rad = 3
    config_noahmp_iopt_alb = 1
    config_noahmp_iopt_snf = 1
    config_noahmp_iopt_tksno = 1
    config_noahmp_iopt_tbot = 2
    config_noahmp_iopt_stc = 1
    config_noahmp_iopt_gla = 1
    config_noahmp_iopt_rsf = 4
    config_noahmp_iopt_soil = 1
    config_noahmp_iopt_pedo = 1
    config_noahmp_iopt_crop = 0
    config_noahmp_iopt_irr = 0
    config_noahmp_iopt_irrm = 0
    config_noahmp_iopt_infdv = 1
    config_noahmp_iopt_tdrn = 0
/
```

Specifically, modify these lines:

- `config_dt` is your timestep in seconds; a rough rule of thumb to start with is to set this to 6x your minimum resolution in km (so, a variable mesh with 1km as its most fine area should be 6sec).

- `config_start_time` should the date you wish to start your sim; this should line up with your IC and first LBC (if applicable) time!

- `config_run_duration` is how long you wish to run the model out to. If you're doing a regional sim with LBCs, you will need LBCs for the amount of time you're running out to! Format is `D_HH:MM:SS`.

- `config_apply_lbcs = true` if you're running a regional sim!

- `config_physics_suite` is the physics suite you wish to use. MPAS has two built in physics suites: `mesoscale_reference` and `convection_permitting`[^3]. Read more on them [here](https://www2.mmm.ucar.edu/projects/mpas/site/documentation/users_guide/phys_suites.html).

Everything else can remain the same. Let's modify our streams.atmosphere, now:

```
<immutable_stream name="input"
                  type="input"
                  filename_template="pr.init.nc"
                  input_interval="initial_only" />

<stream name="output"
        type="output"
        filename_template="history.$Y-$M-$D_$h.$m.$s.nc"
        output_interval="24:00:00" >

        <file name="stream_list.atmosphere.output"/>
</stream>

<stream name="diagnostics"
        type="output"
        filename_template="diag.$Y-$M-$D_$h.$m.$s.nc"
        output_interval="24:00:00" >

        <file name="stream_list.atmosphere.diagnostics"/>
</stream>
```

- Change the input `filename_template` to your `init` grid.

- For the `output` and `diagnostics` fields, change your output_interval to however your often you want files outputted; personally, I just want my entire model run bundled into two files, so I set it to the same run time. I'll dive more into the difference between the `diag.` and `history.` files later.

Now we can run our model! Instead of queueing `init_atmosphere_model` we're just going to queue `atmosphere_model`:

`mpiexec -np # ./atmosphere_model >& log.atmosphere.0000.out`

or, if on a SLURM HPC:

`srun -n # ./atmosphere_model`

This will be the longest step, and it will be important to check the output of your log file to see how long each timestep is taking or if you encounter any errors. A segfault here usually means you're using an inappropriate timestep or you've run out of memory. Make sure to look out for this line:

`Timing for integration step:`

If this number is crazy high (ideally for real-time forecasting it should be LESS than your timestep (so you run faster than real time)) then you may need to go back and reconfigure your mesh to be rougher or more limited in scope.

---
## Sample files

I've included my .sh files to schedule both init_atmosphere and atmosphere models to SLURM under /scripts.

I've also included full templates for namelists and streams files at each step under /configs.

---
## Credit where credit's due

While most of this is from my own workflow, this is kind of an adaptation of part 1 [NCAR's Sept. 2025 MPAS-A Boulder Tutorial](https://www2.mmm.ucar.edu/projects/mpas/tutorial/Boulder2025/) that I attended.

[^1]: If you'd like to use these datasets, NOAA/OAR/GSL has their own fork of MPAS that should have support for them. Setup should be almost 1:1 with these instructions, but I have not tested it yet so I cannot confirm it for sure. If you're interested, check it out here with their own documentation: https://github.com/ufs-community/MPAS-Model

[^2]: This HPC has its timezone set to follow EDT, which means the 'day' the model runs may not line up with what the output of `ls` tells you! If you need more clarity on what day, the download script outputs the UTC date it is pulling from right after it starts running, in format `Selected GFS run: ${run_hour}Z for date $utc_date`.

[^3]: If you will be using `convection_permitting`, there is an additional step! In the root of your `MPAS-Model` folder you must run `./build_tables`, which provides the files for the suite to function. This may take some time to run! Afterwards, symlink all the new `.DBL` files to your `mpas_sim` directory. This should only have to be done once.