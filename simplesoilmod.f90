module simplesoilmod

use parametersmod

implicit none

public :: simplesoil

type layerinfo
  real(sp) :: zpos    ! depth of layer midpoint from soil surface (cm)
  real(sp) :: dz      ! soil layer thickness (cm)
  real(sp) :: sand    ! mass fraction
  real(sp) :: silt    ! mass fraction
  real(sp) :: clay    ! mass fraction
  real(sp) :: cfvo    ! coarse fragment content (volume fraction)
  real(sp) :: orgm    ! organic matter content (mass fraction)
  real(sp) :: bulk    ! bulk density (g m-3)
  real(sp) :: Tsat    ! porosity (fraction)
  real(sp) :: T33     ! water content at -33 KPa tension (fraction)
  real(sp) :: T1500   ! water content at -1500 KPa tension (fraction)
  real(sp) :: whc     ! water holding capacity defined as -33 - -1500 KPa tension (fraction)
  real(sp) :: Ksat    ! saturated hydraulic conductivity (mm h-1)
end type layerinfo

type soildata
  integer(i1) :: WRB     ! WRB 2006 subgroup (code)
  integer(i1) :: USDA    ! WRB 2006 subgroup (code)
  type(layerinfo), allocatable, dimension(:) :: layer
end type soildata

contains

! ---------------------------------------------------------------------------

subroutine simplesoil(soil)

use parametersmod
use pedotransfermod, only : fbulk,calctheta,fKsat,ombd,omcf

implicit none

! argument

type(soildata), intent(inout) :: soil

! input variables

integer  :: soiltype
real(sp) :: zpos
real(sp) :: sand
real(sp) :: silt
real(sp) :: clay
real(sp) :: cfvo
real(sp) :: orgm

! calculated variables

real(sp) :: soc
real(sp) :: blk0
real(sp) :: bulk
real(sp) :: Tsat
real(sp) :: T33
real(sp) :: T1500

! counters

integer :: nl
integer :: l
integer :: it

! ----------

soiltype = soil%soiltype

select case(soil%soiltype)
case default                                 ! typical
  soiltype = 1  
case(1:3,5:6,10:11,43:47,73:75,85:86,95:96)  ! tropical (but not humic or vitric)
  soiltype = 2  
case(4,32)                                   ! humic
  soiltype = 3
case(14,41)                                  ! vitric
  soiltype = 4
end select

nl = size(soil%layer)

do l = 1,nl

  zpos = soil%layer(l)%zpos
  sand = soil%layer(l)%sand
  silt = soil%layer(l)%silt
  clay = soil%layer(l)%clay
  cfvo = soil%layer(l)%cfvo
  orgm = soil%layer(l)%orgm 

  soc = soil%layer(l)%orgm / omcf
  
  ! because bulk density depends strongly on organic matter content and weakly on 
  ! wilting point water content, we guess an initial value and iterate to a stable solution
  ! the bulk density function requires particle size distributions and organic carbon content in mass %
  
  T1500 = 0.1
  
  blk0 = fbulk(soc*100.,T1500*100.,clay*100.,zpos,silt*100.)
  
  it = 1

  do

    ! calculate wilting point, field capacity, and saturation, needs input in fractions

    call calctheta(sand,clay,orgm,blk0,Tsat,T33,T1500,soiltype)

    ! recalculate bulk

    bulk = fbulk(soc*100.,T1500*100.,clay*100.,zpos,silt*100.)

    if (abs(bulk - blk0) < 0.001 .or. it > 50) exit

    blk0 = bulk
    
    it = it + 1
    
  end do

  soil%layer(l)%bulk = bulk

  ! with the final value for bulk density, recalculate porosity

  call calctheta(sand,clay,orgm,bulk,Tsat,T33,T1500,soiltype)

  soil%layer(l)%Tsat = Tsat
  
  ! update layer-integrated WHC, reduced by the fraction of coarse fragments
  ! output units are in mm per cm (of layer thickness)
      
  soil%layer(l)%whc = 10. * (T33 - T1500) * (1. - cfvo)

  ! calculate saturated conductivity

  soil%layer(l)%Ksat = fKsat(Tsat,T33,T1500)
  
end do  ! layers

end subroutine simplesoil 

! ---------------------------------------------------------------------------

end module simplesoilmod
