
!--------------------------------------------------------------------------
!
!    Copyright (C) 1985-2018  Georg Umgiesser
!
!    This file is part of SHYFEM.
!
!    SHYFEM is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation, either version 3 of the License, or
!    (at your option) any later version.
!
!    SHYFEM is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
!    GNU General Public License for more details.
!
!    You should have received a copy of the GNU General Public License
!    along with SHYFEM. Please see the file COPYING in the main directory.
!    If not, see <http://www.gnu.org/licenses/>.
!
!    Contributions to this file can be found below in the revision log.
!
!--------------------------------------------------------------------------

c sort routines
c
c contents :
c
c subroutine sortir(ipoint,value,ndim)	indirect sort of real array
c subroutine sortii(ipoint,ivalue,ndim)	indirect sort of interger array
c
c subroutine sort(n,ra)			heapsort, real, direct
c subroutine sort_int(n,ra)		heapsort, integer, direct
c subroutine isort(n,ra,index)		heapsort, integer, indirect
c
c function locate(n,ixx,index,ix)	locates index for ix in array ixx
c
c revision log :
c
c 15.03.1999    ggu     routines written from scratch (Numerical receipes)
c 09.11.2018    ggu     test routines introduced
c
c***********************************************************

	subroutine sortir(ipoint,value,ndim)

c indirect sort of real array (direct comparison)
c
c ipoint	pointer to values (must be already defined)
c value		values to be sorted
c ndim		total number of values to be sorted

	implicit none

	integer ndim
	integer ipoint(ndim)
	real value(ndim)

	integer i,k,n,n1

	do i=1,ndim-1
	  do k=ndim,i+1,-1
	    n=ipoint(k)
	    n1=ipoint(k-1)
	    if(value(n).lt.value(n1)) then
		ipoint(k)=n1
		ipoint(k-1)=n
	    end if
	  end do
	end do

	end

c***********************************************************

	subroutine sortii(ipoint,ivalue,ndim)
c
c indirect sort of interger array (direct comparison)
c
c ipoint	pointer to values (must be already defined)
c ivalue	values to be sorted
c ndim		total number of values to be sorted
c
	implicit none

	integer ndim
	integer ipoint(ndim),ivalue(ndim)

	integer i,k,n,n1

	do i=1,ndim-1
	  do k=ndim,i+1,-1
	    n=ipoint(k)
	    n1=ipoint(k-1)
	    if(ivalue(n).lt.ivalue(n1)) then
		ipoint(k)=n1
		ipoint(k-1)=n
	    end if
	  end do
	end do

	end

c***********************************************************

      subroutine sort(n,ra)

c heapsort (real, direct)

      implicit none

      integer n
      real ra(n)
c      integer ra(n)

      integer i,ir,j,l
      real rra
c      integer rra

      if(n.lt.2) return

      l=n/2+1
      ir=n
      do
        if(l.gt.1)then
          l=l-1
          rra=ra(l)
        else
          rra=ra(ir)
          ra(ir)=ra(1)
          ir=ir-1
          if(ir.eq.1)then
            ra(1)=rra
            return
          endif
        endif
        i=l
        j=l+l
	do while(j.le.ir)
          if(j.lt.ir)then
            if(ra(j).lt.ra(j+1))j=j+1
          endif
          if(rra.lt.ra(j))then
            ra(i)=ra(j)
            i=j
            j=j+j
          else
            j=ir+1
          endif
	end do
        ra(i)=rra
      end do

      end

c***********************************************************

      subroutine sort_int(n,ra)

c heapsort (integer, direct)

      implicit none

      integer n
c      real ra(n)
      integer ra(n)

      integer i,ir,j,l
c      real rra
      integer rra

      if(n.lt.2) return

      l=n/2+1
      ir=n
      do
        if(l.gt.1)then
          l=l-1
          rra=ra(l)
        else
          rra=ra(ir)
          ra(ir)=ra(1)
          ir=ir-1
          if(ir.eq.1)then
            ra(1)=rra
            return
          endif
        endif
        i=l
        j=l+l
	do while(j.le.ir)
          if(j.lt.ir)then
            if(ra(j).lt.ra(j+1))j=j+1
          endif
          if(rra.lt.ra(j))then
            ra(i)=ra(j)
            i=j
            j=j+j
          else
            j=ir+1
          endif
	end do
        ra(i)=rra
      end do

      end

c******************************************************************

      subroutine isort(n,ra,index)

c heapsort (integer, indirect)

      implicit none

      integer n
      integer ra(n),index(n)

      integer i,ir,j,l,irra
      integer rra

      do i=1,n
	index(i)=i
      end do

      if(n.lt.2) return

      l=n/2+1
      ir=n
      do
        if(l.gt.1)then
          l=l-1
	  irra=index(l)
          rra=ra(irra)
        else
	  irra=index(ir)
          rra=ra(irra)
          index(ir)=index(1)
          ir=ir-1
          if(ir.eq.1)then
            index(1)=irra
            return
          endif
        endif
        i=l
        j=l+l
	do while(j.le.ir)
          if(j.lt.ir)then
            if(ra(index(j)).lt.ra(index(j+1)))j=j+1
          endif
          if(rra.lt.ra(index(j)))then
            index(i)=index(j)
            i=j
            j=j+j
          else
            j=ir+1
          endif
	end do
        index(i)=irra
      end do

      end

c******************************************************************

      function locate(n,ixx,index,ix)

c locates index for ix in array ixx ( ixx(index(i)) is sorted )

      implicit none

      integer locate
      integer n
      integer ixx(n)
      integer index(n)
      integer ix

      integer jl,ju,jm

      jl=1
      ju=n

      do while(ju.gt.jl)
        jm=(ju+jl)/2
        if(ix.gt.ixx(index(jm)))then
          jl=jm+1
        else
          ju=jm
        endif
      end do

      if(ju.le.0) then                    !empty list
        locate=0
      else if(ix.eq.ixx(index(ju))) then  !found
        locate=index(ju)
      else                                !not found
        locate=0
      end if

      return
      end

c**********************************************************
c**********************************************************
c**********************************************************
c testing
c**********************************************************
c**********************************************************
c**********************************************************

	subroutine test_sort_int_indirect(n)

	implicit none

	integer n

	integer i,n1,n2
	integer ra(n)
	integer index(n)
	real r
	logical, parameter :: bwrite = .false.

	do i=1,n
	  call random_number(r)
	  ra(i) = 100 * n * r
	  if( bwrite ) write(6,*) i,ra(i)
	end do

        call isort(n,ra,index)

	if( bwrite ) write(6,*) 1,ra(index(1))
	do i=2,n
	  n1 = index(i-1)
	  n2 = index(i)
	  if( ra(n2) < ra(n1) ) then
	    write(6,*) i,ra(n1),ra(n2)
	    stop 'error stop test_int_direct: not sorted'
	  end if
	  if( bwrite ) write(6,*) i,ra(n2)
	end do

	write(6,*) 'ok test_sort_int_indirect ',n

	end

c**********************************************************

	subroutine test_sort_int_direct(n)

	implicit none

	integer n

	integer i
	integer ra(n)
	real r
	logical, parameter :: bwrite = .false.

	do i=1,n
	  call random_number(r)
	  ra(i) = 100 * n * r
	  if( bwrite ) write(6,*) i,ra(i)
	end do

        call sort_int(n,ra)

	if( bwrite ) write(6,*) 1,ra(1)
	do i=2,n
	  if( ra(i) < ra(i-1) ) then
	    write(6,*) i,ra(i-1),ra(i)
	    stop 'error stop test_int_direct: not sorted'
	  end if
	  if( bwrite ) write(6,*) i,ra(i)
	end do

	write(6,*) 'ok test_sort_int_direct ',n

	end

c**********************************************************

	subroutine test_sort_real_direct(n)

	implicit none

	integer n

	integer i
	real ra(n)
	real r
	logical, parameter :: bwrite = .false.

	do i=1,n
	  call random_number(r)
	  ra(i) = r
	  if( bwrite ) write(6,*) i,ra(i)
	end do

        call sort(n,ra)

	if( bwrite ) write(6,*) 1,ra(1)
	do i=2,n
	  if( ra(i) < ra(i-1) ) then
	    write(6,*) i,ra(i-1),ra(i)
	    stop 'error stop test_int_direct: not sorted'
	  end if
	  if( bwrite ) write(6,*) i,ra(i)
	end do

	write(6,*) 'ok test_sort_real_direct ',n

	end

c**********************************************************

	subroutine test_sort_all

	call test_sort_int_direct(100)
	call test_sort_real_direct(100)
	call test_sort_int_indirect(100)
	call test_sort_int_direct(10000)
	call test_sort_real_direct(10000)
	call test_sort_int_indirect(10000)

	end

c**********************************************************
c	program test_sort_main
c	call test_sort_all
c	end
c**********************************************************

