#!/opt/local/bin/bash

# generate BIOME4 soil files from CLM boundary conditions data

infile=${1}

tmp=${infile##*/}

output=../${tmp%%.*}_BIOME4soils.nc

echo $infile
echo $output

# ----
# 1) create output file 

echo $infile
echo "output file: $output"

bounds=(`gmt grdinfo -C $infile?PFTDATA_MASK`)

xlen=${bounds[9]}
ylen=${bounds[10]}

xmin=${bounds[1]}
xmax=${bounds[2]}

ymin=${bounds[3]}
ymax=${bounds[4]}

sed -e \
's/xlen/'$xlen'/g 
 s/ylen/'$ylen'/g
 s/xmin/'$xmin'/g
 s/xmax/'$xmax'/g 
 s/ymin/'$ymin'/g
 s/ymax/'$ymax'/g 
 s/SoilGrids 2020/CLM input file/g' \
soildata_template.cdl > soildata.cdl

ncgen -o $output soildata.cdl

# -----
# 2) paste coordinates

./pastecoords $infile $output

# -----
# 3) paste land fraction into output

./ncpaste-landfrac $infile $output landfrac

# -----
# 4) paste sand, clay, and orgm into output

./ncpaste-dp-3d $infile $output PCT_SAND sand

./ncpaste-dp-3d $infile $output PCT_CLAY clay

./ncpaste-dp-3d $infile $output ORGANIC soc

# -----
# 5) calculate silt, convert orgm to soc, and initialize all other required variables

./initsoil $output

# -----
# 6) calculate derived soil properties

./soilcalc $output $output
