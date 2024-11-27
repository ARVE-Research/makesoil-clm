#!/opt/local/bin/bash

# This script generates a netCDF map of derived soil properties file at resolutions of 30" (1km) and coarser.
# 
# The script uses the 1km SoilGrids rasters of the following soil physical properties:
#   sand (mass fractions)
#   silt
#   clay
#   organic matter
#   coarse fragments (volume fraction)
# it also uses a 250m raster of WRB soil name that informs the pedotransfer functions.
# 
# The following software is REQUIRED to run the script's programs: 
#    cURL GDAL GMT NCO netCDF netCDF-Fortran
# 
# The raw soil data could be downloaded in advance, otherwise a data download script is also provided

# ------------------------
# USER SETTINGS

# specify a directory for the output file NB this directory has to exist before specifying, 
# example:

# outdir=../global30minute
outdir=NA5km

# specify a target directory where the raw data is stored (or should be downloaded), 
# example:

datadir=/Volumes/Amalanchier/datasets/soils

# set to true if the raw data should be downloaded

getdata=false

# ------------------------
# 0) download the raw data (only if necessary)

if [ "$getdata" = true ]
then
  
  echo "Downloading raw data files from ISRIC"
  
  # 250m WRB code (575 MB):
  
  curl --output-dir $datadir -O https://files.isric.org/soilgrids/former/2017-03-10/data/TAXNWRB_250m_ll.tif
  
  # All other soil physical properties (1km Homolosine rasters about 190 MB each, need about 6 GB for all data)
  
  ./download_from_isric.sh $datadir
  
fi

# make sure the helper programs are up-to-date

make

# -----
# 1) specify the output projection, extent, and resolution 

# specify a map projection using an EPSG code, proj4 string, or external file

# proj="EPSG:4326"  # example: unprojected lon-lat

proj="NAlaea.prj"

# specify the map extent and resolution

# extent="-180. -90.  180. 90."      #  <xmin> <ymin> <xmax> <ymax>

extent="-4350000. -3885000.  3345000. 3780000."      #  <xmin> <ymin> <xmax> <ymax>

res=5000.

min=30.                           # target resolution in MINUTES for lat-lon or METERS for projected grids

if [ $proj == "EPSG:4326" ]
then
  res=`echo "$min / 60" | bc -l`    # convert to degrees
fi

# -----
# 2) extract the WRB code from the source file and resample/reproject as required

infile=$datadir/TAXNWRB_250m_ll.tif

gdalwarp --quiet -overwrite -t_srs $proj -te $extent -wm 8192 -multi -wo NUM_THREADS=16 -tr $res $res -tap -r mode -of netCDF $infile tmp.nc

# get the dimensions of the WRB file

fileinfo=( $(gmt grdinfo -C tmp.nc?Band1) )

xlen=${fileinfo[9]}
ylen=${fileinfo[10]}

echo $xlen $ylen $res

# -----
# 3) create output file based on the dimensions of the input

outfile=$outdir/soils.nc

echo creating $outfile

sed -e "s/xlen/$xlen/g" -e "s/ylen/$ylen/g" soildata.cdl | ncgen -4 -o $outfile

# -----
# 4) paste WRB code into output

./pastewrb tmp.nc $outfile

# -----
# 5) paste soil properties into file

for var in sand silt clay cfvo soc bdod
do

  l=1

  for level in 0-5 5-15 15-30 30-60 60-100 100-200
  do
    
    infile=$datadir/$var"_"$level"cm_mean_1000.tif"
    
    gdalwarp --quiet -overwrite -t_srs $proj -te $extent -wm 8192 -multi -wo NUM_THREADS=16 -tr $res $res -tap -r mode -of netCDF $infile tmp.nc
    
    ncatted -a scale_factor,Band1,c,d,0.1 tmp.nc

    ./ncpaste tmp.nc $outfile $var $l
  
    let l++    

  done
done

# -----
# 6) add coordinates

./pastecoords tmp.nc $outfile

exit

# -----
# 7) calculate derived soil properties

./soilcalc $outfile $outfile

# -----
# 8) finish

rm tmp.nc

echo "finished!"

