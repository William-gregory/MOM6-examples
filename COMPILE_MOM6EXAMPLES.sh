#!/bin/bash

#export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/lib64:/ncrc/home2/William.Gregory/miniconda3/envs/ML/lib"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/lib64"
#module use /gpfs/f5/gfdl_o/scratch/William.Gregory/MOM6-examples/modulefiles
#module load miniconda
#module load cray-python

cd /gpfs/f5/gfdl_o/scratch/$USER/

if [ ! -d MOM6-examples ]; then
    git clone --recursive https://github.com/William-gregory/MOM6-examples.git MOM6-examples
    cd /gpfs/f5/gfdl_o/scratch/$USER/MOM6-examples/src/SIS2/src
    git checkout MLcorrections
    cd /gpfs/f5/gfdl_o/scratch/$USER/MOM6-examples/src/FMS1
    git checkout forpy_dev
    cd /gpfs/f5/gfdl_o/scratch/$USER/MOM6-examples/
    ln -sf /gpfs/f5/gfdl_o/world-shared/datasets .datasets
    #git branch forpy_dev #git branch was run already, so don't need to remake
    #git switch forpy_dev
fi

cd /gpfs/f5/gfdl_o/scratch/$USER/MOM6-examples/
#may need to link data sets:
if [ ! -e ice_ocean_SIS2/OM4_025.JRA/INPUT/woa13_decav_s_monthly_fulldepth_01.nc ]; then
    cd ice_ocean_SIS2/OM4_025.JRA/INPUT/
    ln -sf .datasets/obs/NOAA-NODC/WOA13/v2a/woa13_decav_s_monthly_fulldepth_01.nc woa13_decav_s_monthly_fulldepth_01.nc
    cd /gpfs/f5/gfdl_o/scratch/$USER/MOM6-examples/
fi

if [ ! -e ice_ocean_SIS2/OM4_025.JRA/INPUT/woa13_decav_ptemp_monthly_fulldepth_01.nc ]; then
    cd ice_ocean_SIS2/OM4_025.JRA/INPUT/
    ln -sf .datasets/obs/NOAA-NODC/WOA13/v2a/woa13_decav_ptemp_monthly_fulldepth_01.nc woa13_decav_ptemp_monthly_fulldepth_01.nc
    cd /gpfs/f5/gfdl_o/scratch/$USER/MOM6-examples/
fi

### CREATE BUILD DIRECTORY WHERE COMPILE WILL HAPPEN ###
if [ ! -d build ]; then
    mkdir build
    cd build
else
    cd build
fi

### BUILD FMS ###
if [ ! -d fms ]; then
    mkdir -p fms
    cd fms
    rm -f path_names
    ../../src/mkmf/bin/list_paths -l ../../src/FMS
    ../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/ncrc5-intel-classic.mk -p libfms.a -c "-Duse_libMPI -Duse_netCDF" path_names
    make NETCDF=3 REPRO=1 libfms.a -j
else
    echo "FMS already exists. Rebuild? (y/n)"
    read fmsbuild
    if [ "$fmsbuild" == "y" ]; then
       rm -rf fms
       mkdir -p fms
       cd fms
       rm -f path_names
       ../../src/mkmf/bin/list_paths -l ../../src/FMS
       ../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/ncrc5-intel-classic.mk -p libfms.a -c "-Duse_libMPI -Duse_netCDF" path_names
       make NETCDF=3 REPRO=1 libfms.a -j
    fi
fi
cd /gpfs/f5/gfdl_o/scratch/$USER/MOM6-examples/build

#BUILD MOM6/SIS2
echo "Provide name for MOM6/SIS2 compile"
read COMPILENAME
if [ ! -d ice_ocean_SIS2/$COMPILENAME ]; then
    mkdir -p ice_ocean_SIS2/$COMPILENAME
fi
cd ice_ocean_SIS2/$COMPILENAME
if [ ! -f $COMPILENAME ]; then
    rm -f path_names
    ../../../src/mkmf/bin/list_paths -l ./ ../../../src/MOM6/config_src/{infra/FMS1,memory/dynamic_nonsymmetric,drivers/FMS_cap,external} ../../../src/SIS2/config_src/dynamic ../../../src/MOM6/src/{*,*/*}/ ../../../src/{atmos_null,coupler,land_null,ice_param,icebergs/src,SIS2,FMS/coupler,FMS/include}/
    ../../../src/mkmf/bin/mkmf -t ../../../src/mkmf/templates/ncrc5-intel-classic.mk -o '-I../../fms' -p $COMPILENAME -c '-Duse_AM3_physics -D_USE_LEGACY_LAND_' path_names
    #make REPRO=1 LDFLAGS="-L/lib64 -lgcc_s -lgfortran -liomp5 -L../../fms -lfms -L/opt/cray/pe/netcdf/4.9.0.9/intel/2023.2/lib -lnetcdff -lnetcdf -L/opt/cray/pe/hdf5/1.12.2.11/intel/2023.2/lib -lhdf5 `python3-config --ldflags --embed`" $COMPILENAME -j
    make REPRO=1 LDFLAGS="-L../../fms -lfms" $COMPILENAME -j
else
    echo "$COMPILENAME already exists. Rebuild? (y/n)"
    read SISbuild
    if [ "$SISbuild" == "y" ]; then
	rm -f path_names
	rm -f *
	../../../src/mkmf/bin/list_paths -l ./ ../../../src/MOM6/config_src/{infra/FMS1,memory/dynamic_nonsymmetric,drivers/FMS_cap,external} ../../../src/SIS2/config_src/dynamic ../../../src/MOM6/src/{*,*/*}/ ../../../src/{atmos_null,coupler,land_null,ice_param,icebergs/src,SIS2,FMS/coupler,FMS/include}/
    ../../../src/mkmf/bin/mkmf -t ../../../src/mkmf/templates/ncrc5-intel-classic.mk -o '-I../../fms' -p $COMPILENAME -c '-Duse_AM3_physics -D_USE_LEGACY_LAND_' path_names
    #make REPRO=1 LDFLAGS="-L/lib64 -lgcc_s -lgfortran -liomp5 -L../../fms -lfms -L/opt/cray/pe/netcdf/4.9.0.9/intel/2023.2/lib -lnetcdff -lnetcdf -L/opt/cray/pe/hdf5/1.12.2.11/intel/2023.2/lib -lhdf5 `python3-config --ldflags --embed`" $COMPILENAME -j
    make REPRO=1 LDFLAGS="-L../../fms -lfms" $COMPILENAME -j
    fi
fi
