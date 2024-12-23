# Makesoil
The `makefile.sh` script in this archive generates a netCDF map of derived soil properties file at resolutions of 30" (1km) and coarser.

The script uses the 1km [SoilGrids v2.0](https://www.isric.org/explore/soilgrids) (Poggio et al., 2021) rasters of the following soil physical properties:
* sand (mass fraction)
* silt (mass fraction)
* clay (mass fraction)
* organic carbon content (mass fraction)
* coarse fragments (volume fraction)
* bulk density (cg cm-3)
 
The script also uses the following 250m soil type rasters from the [2017 SoilGrids data](https://www.isric.org/explore/soilgrids/faq-soilgrids-2017) (Hengl et al, 2017):
* WRB (2006) soil subgroup class
* USDA (2014) soil suborder class

The USDA class is used to inform the pedotransfer function for bulk density following Balland et al. (2008). Other pedotransfer functions are based on Sandoval et al. (2024) and references therein.

Finally, the script adds a field of soil/regolith thickness to the output netCDF file that comes from the Pelletier et al. (2016) "gridded global data set of soil, intact regolith, and sedimentary deposit thicknesses".
 
The following software is **REQUIRED** to run the script's programs: 
`cURL GDAL GMT NCO netCDF netCDF-Fortran`
 
The raw soil data could be downloaded in advance, otherwise a data download script is also provided.

## Building

Compile the helper programs using `make` before executing the script.

## User settings

specify a directory for the output file, NB this directory has to exist before running the script

example: `outdir=../global30minute`

specify a target directory where the raw data is stored (or should be downloaded)

example: `datadir=/Volumes/Amalanchier/datasets/soils`

set the following flag to `true` if the raw data should be downloaded

`getdata=false`

## References:

Balland, V., Pollacco, J. A. P., & Arp, P. A. (2008). Modeling soil hydraulic properties for a wide range of soil conditions. Ecological Modelling, 219(3-4), 300-316. doi:10.1016/j.ecolmodel.2008.07.009

Hengl, T., Mendes de Jesus, J., Heuvelink, G. B., Ruiperez Gonzalez, M., Kilibarda, M., Blagotic, A., Shangguan, W., Wright, M. N., Geng, X., Bauer-Marschallinger, B., Guevara, M. A., Vargas, R., MacMillan, R. A., Batjes, N. H., Leenaars, J. G., Ribeiro, E., Wheeler, I., Mantel, S., & Kempen, B. (2017). SoilGrids250m: Global gridded soil information based on machine learning. PLoS One, 12(2), e0169748. doi:10.1371/journal.pone.0169748

Pelletier, J. D., Broxton, P. D., Hazenberg, P., Zeng, X., Troch, P. A., Niu, G. Y., Williams, Z., Brunke, M. A., & Gochis, D. (2016). A gridded global data set of soil, intact regolith, and sedimentary deposit thicknesses for regional and global land surface modeling. Journal of Advances in Modeling Earth Systems, 8(1), 41-65. doi:10.1002/2015ms000526

Poggio, L., de Sousa, L. M., Batjes, N. H., Heuvelink, G. B. M., Kempen, B., Ribeiro, E., & Rossiter, D. (2021). SoilGrids 2.0: producing soil information for the globe with quantified spatial uncertainty. Soil, 7(1), 217-240. doi:10.5194/soil-7-217-2021

Sandoval, D., Prentice, I. C., & Nóbrega, R. L. B. (2024). Simple process-led algorithms for simulating habitats (SPLASH v.2.0): robust calculations of water and energy fluxes. Geoscientific Model Development, 17(10), 4229-4309. doi:10.5194/gmd-17-4229-2024
