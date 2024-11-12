# Makesoil
This script generates a netCDF map of derived soil properties file at resolutions of 30" (1km) and coarser.

The script uses the 1km [SoilGrids](https://www.isric.org/explore/soilgrids) rasters of the following soil physical properties:
* sand (mass fraction)
* silt (mass fraction)
* clay (mass fraction)
* organic matter (mass fraction)
* coarse fragments (volume fraction)
 
The script also uses a 250m raster of WRB soil name from the [2017 SoilGrids data](https://www.isric.org/explore/soilgrids/faq-soilgrids-2017) that informs the pedotransfer functions.
 
The following software is **REQUIRED** to run the script's programs: 
`cURL GDAL GMT NCO netCDF netCDF-Fortran`
 
The raw soil data could be downloaded in advance, otherwise a data download script is also provided.

## Building

Compile the helper programs using `make` before executing the script.

## User settings

specify a directory for the output file NB this directory has to exist before specifying

`outdir=../global30minute`

specify a target directory where the raw data is stored (or should be downloaded)

`datadir=/Volumes/Amalanchier/datasets/soils`

set to true if the raw data should be downloaded

`getdata=false`
