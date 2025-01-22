program initsoil

! gfortran -Wall -o initsoil initsoil.f90 -I/usr/local/include -L/usr/local/lib -lnetcdff

use iso_fortran_env
use netcdf

implicit none

integer, parameter :: sp = real32
integer, parameter :: dp = real64
integer, parameter :: i2 = int16
integer, parameter :: i1 = int8

character(200) :: infile

integer :: status
integer :: ncid
integer :: dimid
integer :: varid
integer :: xlen
integer :: ylen
integer :: zlen

real(sp)    :: scale_factor
integer(i2) :: imissing

integer :: x
integer :: y
integer :: z

integer(i1), allocatable, dimension(:,:)   :: soilclass
integer(i2), allocatable, dimension(:,:,:) :: sand
integer(i2), allocatable, dimension(:,:,:) :: silt
integer(i2), allocatable, dimension(:,:,:) :: clay
integer(i2), allocatable, dimension(:,:,:) :: soc
integer(i2), allocatable, dimension(:,:,:) :: cfvo

real(sp), allocatable, dimension(:) :: dz

real(sp) :: orgm

real(sp), parameter :: ps = 2650.  ! particle density of mineral soil (typical) (kg m-3)

real(sp) :: varmin
real(sp) :: varmax

real(sp), dimension(2) :: actual_range  = [0., 0.]

! ------------------------------------------------------------------------------------------------------------

call getarg(1,infile)

! -------------------------------------------------------
! read input file

! write(0,*)'reading'

status = nf90_open(infile,nf90_write,ncid)
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

status = nf90_inq_dimid(ncid,'depth',dimid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inquire_dimension(ncid,dimid,len=zlen)
if (status /= nf90_noerr) call handle_err(status)

allocate(dz(zlen))
allocate(soilclass(xlen,ylen))
allocate(sand(xlen,ylen,zlen))
allocate(silt(xlen,ylen,zlen))
allocate(clay(xlen,ylen,zlen))
allocate(soc(xlen,ylen,zlen))
allocate(cfvo(xlen,ylen,zlen))

status = nf90_inq_varid(ncid,'dz',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_var(ncid,varid,dz)
if (status /= nf90_noerr) call handle_err(status)

! -------------------------------------------------------
! convert orgm density to soc

status = nf90_inq_varid(ncid,'soc',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_var(ncid,varid,soc)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_att(ncid,varid,'_FillValue',imissing)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_att(ncid,varid,'scale_factor',scale_factor)
if (status /= nf90_noerr) call handle_err(status)

do z = 1,zlen
  do y = 1,ylen
    do x = 1,xlen
    
      if (soc(x,y,z) == imissing) cycle
    
      orgm = real(soc(x,y,z)) * scale_factor / ps
    
      soc(x,y,z) = nint(orgm / 0.001,i2)

    end do
  end do
end do

scale_factor = 0.001

varmin = real(minval(soc,mask=soc/=imissing)) * scale_factor
varmax = real(maxval(soc,mask=soc/=imissing)) * scale_factor

actual_range = [varmin,varmax]

status = nf90_put_att(ncid,varid,'scale_factor',scale_factor)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_att(ncid,varid,'actual_range',actual_range)
if (status /= nf90_noerr) call handle_err(status)

write(0,*)'soc',actual_range

status = nf90_put_var(ncid,varid,soc)
if (status /= nf90_noerr) call handle_err(status)

! -------------------------------------------------------
! set a value for cfvo (uniform everywhere)

cfvo = imissing

where (soc /= imissing) cfvo = 0.

status = nf90_inq_varid(ncid,'cfvo',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_var(ncid,varid,cfvo)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_att(ncid,varid,'actual_range',actual_range)
if (status /= nf90_noerr) call handle_err(status)

varmin = real(minval(cfvo,mask=cfvo/=imissing)) * scale_factor
varmax = real(maxval(cfvo,mask=cfvo/=imissing)) * scale_factor

actual_range = [min(varmin,actual_range(1)),max(varmax,actual_range(2))]

status = nf90_put_att(ncid,varid,'actual_range',actual_range)
if (status /= nf90_noerr) call handle_err(status)

write(0,*)'cfrag',actual_range

! -------------------------------------------------------
! calculate and add silt

silt = imissing

status = nf90_inq_varid(ncid,'sand',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_var(ncid,varid,sand)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_varid(ncid,'clay',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_var(ncid,varid,clay)
if (status /= nf90_noerr) call handle_err(status)

where (sand /= imissing) silt = 1000_i2 - (sand + clay)

status = nf90_inq_varid(ncid,'silt',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_att(ncid,varid,'scale_factor',scale_factor)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_var(ncid,varid,silt)
if (status /= nf90_noerr) call handle_err(status)

varmin = real(minval(silt,mask=silt/=imissing)) * scale_factor
varmax = real(maxval(silt,mask=silt/=imissing)) * scale_factor

actual_range = [min(varmin,actual_range(1)),max(varmax,actual_range(2))]

status = nf90_put_att(ncid,varid,'actual_range',actual_range)
if (status /= nf90_noerr) call handle_err(status)

write(0,*)'silt',actual_range

! -------------------------------------------------------
! write USDA codes

soilclass = -1_i1

where (soc(:,:,1) /= imissing) soilclass = 69  ! Typical Mollisols

status = nf90_inq_varid(ncid,'USDA',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_var(ncid,varid,soilclass)
if (status /= nf90_noerr) call handle_err(status)

! -------------------------------------------------------


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

end program initsoil
