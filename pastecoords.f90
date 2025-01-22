program pastecoords

! gfortran -Wall -o pastecoords pastecoords.f90 -I/usr/local/include -L/usr/local/lib -lnetcdff

use iso_fortran_env
use netcdf

implicit none

integer, parameter :: sp = real32
integer, parameter :: dp = real64
integer, parameter :: i2 = int16

character(200) :: infile
character(200) :: outfile

integer :: status
integer :: ncid
integer :: dimid
integer :: varid
integer :: xlen
integer :: ylen

real(dp), dimension(2) :: lonrange
real(dp), dimension(2) :: latrange

real(dp) :: dx2
real(dp) :: dy2

real(dp), allocatable, dimension(:) :: lon
real(dp), allocatable, dimension(:) :: lat

integer, parameter :: nl = 10

real(sp), dimension(nl) :: zpos
real(sp), dimension(nl) :: dz

integer :: l

real(sp), dimension(2,nl) :: layer_bnds

! ------------------------------------------------------------------------------------------------------------

zpos = [ 0.007100635, 0.027925, 0.06225858, 0.1188651, 0.2121934, 0.3660658, 0.6197585, 1.038027, 1.727635, 2.864607 ]

zpos = zpos * 100.

dz(1) = 2. * zpos(1)

do l = 2,nl
  dz(l) = 2. * (zpos(l) - sum(dz(1:l-1)))
end do

do l = 1,nl
  layer_bnds(1,l) = zpos(l) - dz(l) / 2.
  layer_bnds(2,l) = zpos(l) + dz(l) / 2.
  
  write(0,'(i5,4f8.1)')l,dz(l),layer_bnds(1,l),zpos(l),layer_bnds(2,l)
  
end do

call getarg(1,infile)
call getarg(2,outfile)

! -------------------------------------------------------
!  read input file

write(0,*)'reading'

status = nf90_open(infile,nf90_nowrite,ncid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_dimid(ncid,'lon',dimid)
if (status == nf90_ebaddim) status = nf90_inq_dimid(ncid,'x',dimid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inquire_dimension(ncid,dimid,len=xlen)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_dimid(ncid,'lat',dimid)
if (status == nf90_ebaddim) status = nf90_inq_dimid(ncid,'y',dimid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inquire_dimension(ncid,dimid,len=ylen)
if (status /= nf90_noerr) call handle_err(status)

allocate(lon(xlen))
allocate(lat(ylen))

write(0,*)xlen,ylen

status = nf90_inq_varid(ncid,'lon',varid)
if (status == nf90_enotvar) status = nf90_inq_varid(ncid,'x',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_var(ncid,varid,lon)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_varid(ncid,'lat',varid)
if (status == nf90_enotvar) status = nf90_inq_varid(ncid,'y',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_var(ncid,varid,lat)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_close(ncid)
if (status /= nf90_noerr) call handle_err(status)

! -------------------------------------------------------

dx2 = (lon(2) - lon(1)) / 2._dp

lonrange(1) = lon(1) - dx2
lonrange(2) = lon(xlen) + dx2

dy2 = (lat(2) - lat(1)) / 2._dp

latrange(1) = lat(1) - dy2
latrange(2) = lat(ylen) + dy2

! -------------------------------------------------------

!  write to output file

write(0,*)'writing coords'

status = nf90_open(outfile,nf90_write,ncid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_varid(ncid,'lon',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_var(ncid,varid,lon)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_att(ncid,varid,'actual_range',lonrange)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_varid(ncid,'lat',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_var(ncid,varid,lat)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_att(ncid,varid,'actual_range',latrange)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_varid(ncid,'depth',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_var(ncid,varid,zpos)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_varid(ncid,'dz',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_var(ncid,varid,dz)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_varid(ncid,'layer_bnds',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_var(ncid,varid,layer_bnds)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_close(ncid)
if (status /= nf90_noerr) call handle_err(status)

! -------------------------------------------------------

contains

subroutine handle_err(status)

!    Internal subroutine - checks error status after each netcdf call,
!    prints out text message each time an error code is returned. 

integer, intent (in) :: status

if(status /= nf90_noerr) then 
  print *, trim(nf90_strerror(status))
  stop
end if

end subroutine handle_err

! -------------------------------------------------------

end program pastecoords
