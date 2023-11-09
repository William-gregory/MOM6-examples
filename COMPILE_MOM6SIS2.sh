#!/bin/bash

export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/lib64:/lustre/f2/dev/William.Gregory/miniconda_setup/miniconda/lib"

#if not already cloned...
#cd /lustre/f2/dev/$USER/
#git clone --recursive https://github.com/William-gregory/MOM6-examples.git MOM6-examples
#git branch forpy_dev
#git switch forpy_dev

#may need to link data sets:
#cd ../../ice_ocean_SIS2/OM4_025.JRA/INPUT
#ln -sf /autofs/ncrc-svm1_home1/Alistair.Adcroft/fre/FMS2023.01_mom6_20230630/MOM6_SIS2_compile/src/mom6/ice_ocean_SIS2/OM4_025.JRA/INPUT/woa13_decav_s_monthly_fulldepth_01.nc woa13_decav_s_monthly_fulldepth_01.nc
#ln -sf /autofs/ncrc-svm1_home1/Alistair.Adcroft/fre/FMS2023.01_mom6_20230630/MOM6_SIS2_compile/src/mom6/ice_ocean_SIS2/OM4_025.JRA/INPUT/woa13_decav_ptemp_monthly_fulldepth_01.nc woa13_decav_ptemp_monthly_fulldepth_01.nc

cd /lustre/f2/dev/$USER/MOM6-examples
rm -rf build
mkdir build
mkdir -p build/fms/
mkdir -p build/ice_ocean_SIS2

#BUILD FMS
cd build/fms
rm -f path_names
../../src/mkmf/bin/list_paths -l ../../src/FMS
../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/ncrc5-intel-classic.mk -p libfms.a -c "-Duse_libMPI -Duse_netCDF" path_names
make NETCDF=3 REPRO=1 libfms.a -j

#BUILD MOM6/SIS2
cd ../ice_ocean_SIS2
rm -f path_names
../../src/mkmf/bin/list_paths -l ./ ../../src/MOM6/config_src/{infra/FMS1,memory/dynamic_symmetric,drivers/FMS_cap,external} ../../src/SIS2/config_src/dynamic_symmetric ../../src/MOM6/src/{*,*/*}/ ../../src/{atmos_null,coupler,land_null,ice_param,icebergs/src,SIS2,FMS/coupler,FMS/include}/
../../src/mkmf/bin/mkmf -t ../../src/mkmf/templates/ncrc5-intel-classic.mk -o '-I../fms -I/opt/cray/pe/netcdf/default/intel/19.0/include -I/opt/cray/pe/hdf5/default/intel/19.0/include' -p MOM6 -l '-L../fms -lfms -L/opt/cray/pe/netcdf/default/intel/19.0/lib -lnetcdff -lnetcdf -L/opt/cray/pe/hdf5/default/intel/19.0/lib -lhdf5 `python3-config --ldflags --embed`' -c '-Duse_AM3_physics -D_USE_LEGACY_LAND_' path_names
make REPRO=1 MOM6 -j





