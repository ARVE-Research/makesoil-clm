#!/opt/local/bin/bash

# module load cURL

outdir=${1}

# create the file list for downloading

echo "# filelist" > filelist.txt

for var in sand silt clay cfvo soc
do
  for layer in 0-5cm 5-15cm 15-30cm 30-60cm 60-100cm 100-200cm
  do
  
    url="https://files.isric.org/soilgrids/latest/data_aggregated/1000m/$var/$var"_"$layer"_"mean_1000.tif"
    
    echo "url = $url" >> filelist.txt
    echo output = "$outdir/$var"_"$layer"_"mean_1000.tif"  >> filelist.txt
    
  done
done

# download the files using cURL in parallel

curl -Z -K filelist.txt

# cleanup

rm filelist.txt