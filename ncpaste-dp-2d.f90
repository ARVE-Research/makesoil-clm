program ncpaste

! gfortran -Wall -o ncpaste-dp-2d ncpaste-dp-2d.f90 -I/usr/local/include -L/usr/local/lib -lnetcdff

use iso_fortran_env
use netcdf

implicit none

integer, parameter :: sp = real32
integer, parameter :: dp = real64
integer, parameter :: i2 = int16

character(200) :: infile
character(200) :: outfile

character(50) :: ivarname
character(50) :: ovarname
! character(5)  :: cts

! integer :: t

integer :: status
integer :: ncid
integer :: dimid
integer :: varid
integer :: xlen
integer :: ylen
! integer :: tlen

! real(sp)    :: scale_factor
! integer(i2) :: imissing

! integer(i2) :: omissing
! real(sp)    :: add_offset

real(sp) :: varmin
real(sp) :: varmax

real(sp), dimension(2) :: actual_range  = [0., 0.]

real(dp), allocatable, dimension(:,:) :: var_in
real(sp), allocatable, dimension(:,:) :: var_out

!------------------------------------------------------------------------------------------------------------

call getarg(1,infile)
call getarg(2,outfile)
call getarg(3,ivarname)
call getarg(4,ovarname)

!-------------------------------------------------------
! read input file

! write(0,*)'reading'

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

allocate(var_in(xlen,ylen))
allocate(var_out(xlen,ylen))

status = nf90_inq_varid(ncid,ivarname,varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_var(ncid,varid,var_in)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_close(ncid)
if (status /= nf90_noerr) call handle_err(status)

!-------------------------------------------------------
! write to output file

var_out = real(var_in,sp)

! write(0,*)'writing'

status = nf90_open(outfile,nf90_write,ncid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_varid(ncid,ovarname,varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_var(ncid,varid,var_out)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_att(ncid,varid,'actual_range',actual_range)
if (status /= nf90_noerr) call handle_err(status)

varmin = minval(var_out)
varmax = maxval(var_out)

actual_range = [min(varmin,actual_range(1)),max(varmax,actual_range(2))]

status = nf90_put_att(ncid,varid,'actual_range',actual_range)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_close(ncid)
if (status /= nf90_noerr) call handle_err(status)

write(0,*)trim(ovarname),actual_range

!-------------------------------------------------------

contains

subroutine handle_err(status)

!   Internal subroutine - checks error status after each netcdf call,
!   prints out text message each time an error code is returned. 

integer, intent (in) :: status

if(status /= nf90_noerr) then 
  print *, trim(nf90_strerror(status))
  stop
end if

end subroutine handle_err

!-------------------------------------------------------

end program ncpaste
