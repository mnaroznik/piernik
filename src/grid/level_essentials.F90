!
! PIERNIK Code Copyright (C) 2006 Michal Hanasz
!
!    This file is part of PIERNIK code.
!
!    PIERNIK is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation, either version 3 of the License, or
!    (at your option) any later version.
!
!    PIERNIK is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU General Public License for more details.
!
!    You should have received a copy of the GNU General Public License
!    along with PIERNIK.  If not, see <http://www.gnu.org/licenses/>.
!
!    Initial implementation of PIERNIK code was based on TVD split MHD code by
!    Ue-Li Pen
!        see: Pen, Arras & Wong (2003) for algorithm and
!             http://www.cita.utoronto.ca/~pen/MHD
!             for original source code "mhd.f90"
!
!    For full list of developers see $PIERNIK_HOME/license/pdt.txt
!
#include "piernik.h"

!> \brief Module containing most basic properties ofgrid levels. Created to avoid circular dependencies between grid_container and cg_level_T

module level_essentials

   use constants, only: ndims, LONG, INT4

   implicit none
   private
   public :: level_T

   !> \brief the type that contains the most basic data to be linked, where appropriate

   type :: level_T
      integer(kind=8), dimension(ndims) :: off  !< offset of the level
      integer(kind=8), dimension(ndims) :: n_d  !< maximum number of grid cells in each direction (size of fully occupied level)
      integer(kind=4)                   :: id   !< level number (relative to base level). No arithmetic should depend on it.
      !type(level_T), pointer :: coarser
      !type(level_T), pointer :: finer

      ! Shadows of the values set by level_T%write.
      ! I would like to protect them from being modified by mistake, but can't find any convenient way other than making all of them private and accessible through functions (which is not convenient).
      integer(kind=8), dimension(ndims), private :: off_ = huge(1_LONG)
      integer(kind=8), dimension(ndims), private :: n_d_ = huge(1_LONG)
      integer(kind=4),                   private :: id_  = huge(1_INT4)
   contains
      procedure          :: init   !< simple initialization
      procedure          :: update !< update data (e.g. after resizing the domain)
      procedure, private :: write  !< do the actual saving of the data
      procedure          :: check  !< check against shadows if nothing has changed
   end type level_T

contains

   !> \brief simple initialization

   subroutine init(this, id, n_d, off)

      use constants,  only: ndims, LONG, INT4
      use dataio_pub, only: msg, printinfo, die
      use mpisetup,   only: master

      implicit none

      class(level_T),                    intent(inout) :: this
      integer(kind=4),                   intent(in)    :: id
      integer(kind=8), dimension(ndims), intent(in)    :: n_d
      integer(kind=8), dimension(ndims), intent(in)    :: off

      if (any([this%off_(:), this%n_d_(:)] /= huge(1_LONG)) .or. this%id_ /= huge(1_INT4)) call die("[level_essentials:init] Level essentials already initialized")

      call this%write(id, n_d, off)

      write(msg, '(a,i4,2(a,3i8),a)')"[level_essentials] Initializing level", this%id, ", size=[", this%n_d, "], offset=[", this%off, "]"
      if (master) call printinfo(msg)

   end subroutine init

   !> \brief update data (e.g. after resizing the domain)

   subroutine update(this, id, n_d, off)

      use constants,  only: ndims
      use dataio_pub, only: msg, printinfo, die
      use mpisetup,   only: master

      implicit none

      class(level_T),                    intent(inout) :: this
      integer(kind=4),                   intent(in)    :: id
      integer(kind=8), dimension(ndims), intent(in)    :: n_d
      integer(kind=8), dimension(ndims), intent(in)    :: off

      if (any([int(this%off_(:), 4), int(this%n_d_(:), 4), this%id_] == huge(1))) call die("[level_essentials:update] Level essentials not initialized yet")
      if (this%id_ /= id) call die("[level_essentials:update] level id don't match")

      call this%write(id, n_d, off)

      write(msg, '(a,i4,2(a,3i8),a)')"[level_essentials] Updating level", this%id, ", new size=[", this%n_d, "], new offset=[", this%off, "]"
      if (master) call printinfo(msg)

   end subroutine update

   !> \brief do the actual saving of the data

   subroutine write(this, id, n_d, off)

      use constants,  only: ndims
      use domain,     only: dom

      implicit none

      class(level_T),                    intent(inout) :: this
      integer(kind=4),                   intent(in)    :: id
      integer(kind=8), dimension(ndims), intent(in)    :: n_d
      integer(kind=8), dimension(ndims), intent(in)    :: off

      this%id = id
      where (dom%has_dir(:))
         this%n_d(:) = n_d(:)
         this%off(:) = off(:)
      elsewhere
         this%n_d(:) = 1
         this%off(:) = 0
      endwhere

      this%off_ = this%off
      this%n_d_ = this%n_d
      this%id_  = this%id

   end subroutine write

   !> \brief check against shadows if nothing has changed

   subroutine check(this)

      use dataio_pub, only: msg, warn
      use mpisetup,   only: proc

      implicit none

      class(level_T), intent(in) :: this

      if (this%id /= this%id_) then
         write(msg, '(a,i6,2(a,i4))')"[level_essentials:check] @", proc, " shadow id has changed: ", this%id, " /=", this%id_
         call warn(msg)
      endif

      if (any(this%off /= this%off_)) then
         write(msg, '(a,i6,2(a,3i8),a,i4)')"[level_essentials:check] @", proc, " shadow off has changed: [ ", this%off, " ] /= [ ", this%off_, " ], id = ", this%id_
         call warn(msg)
      endif

      if (any(this%n_d /= this%n_d_)) then
         write(msg, '(a,i6,2(a,3i8),a,i4)')"[level_essentials:check] @", proc, " shadow n_d has changed: [ ", this%n_d, " ] /= [ ", this%n_d_, " ], id = ", this%id_
         call warn(msg)
      endif

   end subroutine check

end module level_essentials
