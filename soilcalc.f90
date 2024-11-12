program soilcalc

! use Makefile

use simplesoilmod, only : i1,i2,sp,soildata,layerinfo,simplesoil
use pedotransfermod, only : omcf
use netcdf

implicit none

character(200) :: soilfile
! character(200) :: landfracfile

character(200) :: outfile

integer :: status
integer :: ncid
integer :: dimid
integer :: varid
integer :: xlen
integer :: ylen
integer :: nl

integer :: x
integer :: y
integer :: l

real(sp), allocatable, dimension(:,:,:) :: sand
real(sp), allocatable, dimension(:,:,:) :: silt
real(sp), allocatable, dimension(:,:,:) :: clay
real(sp), allocatable, dimension(:,:,:) :: cfvo
real(sp), allocatable, dimension(:,:,:) :: soc

real(sp), allocatable, dimension(:,:,:) :: Tsat
real(sp), allocatable, dimension(:,:,:) :: Ksat
real(sp), allocatable, dimension(:,:,:) :: whc

real(sp), allocatable, dimension(:) :: zpos
real(sp), allocatable, dimension(:) :: dz

type(soildata) :: soil

real(sp), parameter :: rmissing = -9999.

real(sp), dimension(2) :: actual_range

real(sp) :: scale

! -------------------------------------------------------

call getarg(1,soilfile)

status = nf90_open(soilfile,nf90_nowrite,ncid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_dimid(ncid,'lon',dimid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inquire_dimension(ncid,dimid,len=xlen)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_dimid(ncid,'lat',dimid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inquire_dimension(ncid,dimid,len=ylen)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inq_dimid(ncid,'depth',dimid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_inquire_dimension(ncid,dimid,len=nl)
if (status /= nf90_noerr) call handle_err(status)

allocate(zpos(nl))
allocate(dz(nl))

allocate(soil%layer(nl))

status = nf90_inq_varid(ncid,'depth',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_var(ncid,varid,zpos)
if (status /= nf90_noerr) call handle_err(status)

zpos = abs(zpos)

status = nf90_inq_varid(ncid,'dz',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_var(ncid,varid,dz)
if (status /= nf90_noerr) call handle_err(status)

soil%layer%zpos = zpos
soil%layer%dz   = dz

do l = 1,nl
  write(0,*)l,zpos(l),dz(l)
end do

allocate(sand(xlen,ylen,nl))
allocate(silt(xlen,ylen,nl))
allocate(clay(xlen,ylen,nl))
allocate(cfvo(xlen,ylen,nl))
allocate(soc(xlen,ylen,nl))

! ---------
! read input soil spatial data

call getvar('sand',sand)
call getvar('silt',silt)
call getvar('clay',clay)
call getvar('cfvo',cfvo)
call getvar('soc',soc)

status = nf90_close(ncid)
if (status /= nf90_noerr) call handle_err(status)

! ---------

allocate(Tsat(xlen,ylen,nl))
allocate(Ksat(xlen,ylen,nl))
allocate(whc(xlen,ylen,nl))

Tsat = rmissing
Ksat = rmissing
whc  = rmissing

write(0,*)'calculating'

where (sand < 0.) sand = rmissing

do y = 1,ylen
  do x = 1,xlen
  
    if (sand(x,y,1) /= rmissing) then
    
      soil%layer%sand = sand(x,y,:)
      soil%layer%silt = silt(x,y,:)
      soil%layer%clay = clay(x,y,:)
      soil%layer%cfvo = cfvo(x,y,:)
      soil%layer%orgm = soc(x,y,:) * omcf
      
      do l = 1,nl
        if (soil%layer(l)%sand + soil%layer(l)%silt + soil%layer(l)%clay > 1.) then
        
          scale = 1. / (soil%layer(l)%sand + soil%layer(l)%silt + soil%layer(l)%clay)
          
          soil%layer(l)%sand = soil%layer(l)%sand * scale
          soil%layer(l)%silt = soil%layer(l)%silt * scale
          soil%layer(l)%clay = soil%layer(l)%clay * scale
        end if
      end do
            
      call simplesoil(soil)
      
      Tsat(x,y,:) = soil%layer%Tsat
      Ksat(x,y,:) = soil%layer%Ksat
      whc(x,y,:)  = soil%layer%whc
      
      if (any(soil%layer%whc <= 0)) then

        write(0,*)x,y

        do l = 1,nl
          write(0,*)l,soil%layer(l)%sand,soil%layer(l)%clay,soil%layer(l)%whc
        end do

      end if

    end if
      
  end do
end do

! ---------

write(0,*)'writing'

call getarg(2,outfile)

status = nf90_open(outfile,nf90_write,ncid)
if (status /= nf90_noerr) call handle_err(status)

! --

status = nf90_inq_varid(ncid,'Tsat',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_var(ncid,varid,Tsat)
if (status /= nf90_noerr) call handle_err(status)

actual_range = [minval(Tsat,mask=Tsat/=rmissing),maxval(Tsat,mask=Tsat/=rmissing)]

status = nf90_put_att(ncid,varid,'actual_range',actual_range)
if (status /= nf90_noerr) call handle_err(status)

write(0,*)'Tsat range: ',actual_range

! --

status = nf90_inq_varid(ncid,'whc',varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_var(ncid,varid,whc)
if (status /= nf90_noerr) call handle_err(status)

actual_range = [minval(whc,mask=whc/=rmissing),maxval(whc,mask=whc/=rmissing)]

status = nf90_put_att(ncid,varid,'actual_range',actual_range)
if (status /= nf90_noerr) call handle_err(status)

write(0,*)'whc range: ',actual_range

! --

status = nf90_inq_varid(ncid,'Ksat',varid)
if (status /= nf90_noerr) call handle_err(status)

actual_range = [minval(Ksat,mask=Ksat/=rmissing),maxval(Ksat,mask=Ksat/=rmissing)]

write(0,*)'Ksat range: ',actual_range

status = nf90_put_att(ncid,varid,'actual_range',actual_range)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_put_var(ncid,varid,ksat)
if (status /= nf90_noerr) call handle_err(status)

! -------------------------------------------------------

contains

subroutine getvar(name,var)

implicit none

character(*), intent(in) :: name

real(sp), dimension(:,:,:), intent(out) :: var

real(sp)    :: scale_factor
integer(i2) :: missing_value

integer(i2), allocatable, dimension(:,:,:) :: ivar

integer :: xlen,ylen,nl

! ----

xlen = size(var,dim=1)
ylen = size(var,dim=2)
nl   = size(var,dim=3)

allocate(ivar(xlen,ylen,nl))

status = nf90_inq_varid(ncid,name,varid)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_var(ncid,varid,ivar)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_att(ncid,varid,'missing_value',missing_value)
if (status /= nf90_noerr) call handle_err(status)

status = nf90_get_att(ncid,varid,'scale_factor',scale_factor)
if (status /= nf90_noerr) call handle_err(status)

var = rmissing

where (ivar /= missing_value) var = real(ivar) * scale_factor

write(0,*)trim(name),': ',minval(var,mask=var/=rmissing),maxval(var,mask=var/=rmissing)

end subroutine getvar

! ---------

subroutine handle_err(status)

!   Internal subroutine - checks error status after each netcdf call,
!   prints out text message each time an error code is returned. 

integer, intent (in) :: status

if(status /= nf90_noerr) then 
  write(0,*)'NetCDF error: ',trim(nf90_strerror(status))
  stop
end if

end subroutine handle_err

end program soilcalc

