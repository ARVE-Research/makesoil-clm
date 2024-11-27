program pastesoilcode

use iso_fortran_env
use netcdf

implicit none

integer, parameter :: i1 = int8

character(100) :: infile
character(100) :: outfile

integer :: status
integer :: ncid
integer :: dimid
integer :: varid
integer :: xlen
integer :: ylen

integer(i1) :: imissing

integer(i1), dimension(2) :: actual_range

integer(i1), allocatable, dimension(:,:) :: var

character(40) :: varname

!------------------------------------------------------------------------------------------------------------

call getarg(1,infile)
call getarg(2,outfile)
call getarg(3,varname)

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

allocate(var(xlen,ylen))

status = nf90_inq_varid(ncid,'Band1',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_var(ncid,varid,var)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_att(ncid,varid,'_FillValue',imissing)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_close(ncid)
if (status /= nf90_noerr) call handle_err(status)

!-------------------------------------------------------
! write to output file

! write(0,*)'writing'

status = nf90_open(outfile,nf90_write,ncid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_varid(ncid,varname,varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_var(ncid,varid,var)
if (status /= nf90_noerr) call handle_err(status)

actual_range(1) = minval(var,mask=var/=imissing)
actual_range(2) = maxval(var,mask=var/=imissing)

status = nf90_put_att(ncid,varid,'actual_range',actual_range)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_close(ncid)
if (status /= nf90_noerr) call handle_err(status)

write(0,*)"soiltype range:",actual_range

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

end program pastesoilcode
