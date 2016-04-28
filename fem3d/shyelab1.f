!
! $Id: noselab.f,v 1.8 2008-11-20 10:51:34 georg Exp $
!
! revision log :
!
! 18.11.1998    ggu     check dimensions with dimnos
! 06.04.1999    ggu     some cosmetic changes
! 03.12.2001    ggu     some extra output -> place of min/max
! 09.12.2003    ggu     check for NaN introduced
! 07.03.2007    ggu     easier call
! 08.11.2008    ggu     do not compute min/max in non-existing layers
! 07.12.2010    ggu     write statistics on depth distribution (depth_stats)
! 06.05.2015    ggu     noselab started
! 05.06.2015    ggu     many more features added
! 10.09.2015    ggu     std and rms for averaging implemented
! 11.09.2015    ggu     write in gis format
! 23.09.2015    ggu     handle more than one file (look for itstart)
! 16.10.2015    ggu     started shyelab
!
!**************************************************************

	subroutine shyelab1

	use clo
	use elabutil
	use shyfile
	use shyutil

        use basin
        use mod_depth
        use evgeom
        use levels

	implicit none

	include 'param.h'

	integer, parameter :: ndim = 1000
	integer iusplit(ndim)

	real, allocatable :: cv2(:)
	real, allocatable :: cv3(:,:)
	real, allocatable :: cv3all(:,:,:)

	integer, allocatable :: ivars(:,:)
	integer, allocatable :: il(:)

	real, allocatable :: hl(:)

	logical bnextfile
	integer nwrite,nread,nelab,nrec,nin,nold
	integer nvers
	integer nknnos,nelnos,nvar,npr
	integer ierr
	!integer it,itvar,itnew,itold,itstart
	integer it
	integer ivar,iaux
	integer iv,j,l,k,lmax,node
	integer ip,nb
	integer ifile,ftype
	integer id,idout,idold
	integer n,m,nndim,nn
	integer naccum
	character*80 title,name,file
	character*80 basnam,simnam
	real rnull
	real cmin,cmax,cmed,vtot
	double precision dtime,dtstart,dtnew,dtvar
	double precision atime,atstart,atold,atnew

	integer iapini
	integer ifem_open_file

!--------------------------------------------------------------
! initialize everything
!--------------------------------------------------------------

	nread=0
	nwrite=0
	nelab=0
	nrec=0
	rnull=0.
	rnull=-1.
	bopen = .false.
	bzeta = .false.		!file has zeta information

	!--------------------------------------------------------------
	! set command line parameters
	!--------------------------------------------------------------

	call elabutil_init('SHY')

	!--------------------------------------------------------------
	! open input files
	!--------------------------------------------------------------

	ifile = 1
	idold = 0
	call open_next_file(ifile,idold,id)
	call get_start_of_next_file(ifile+1,atstart,bnextfile)

	!--------------------------------------------------------------
	! set up params and arrays
	!--------------------------------------------------------------

	call shy_get_params(id,nkn,nel,npr,nlv,nvar)
	call shy_get_ftype(id,ftype)
	!write(6,*) id,nkn,nel,npr,nlv,nvar,ftype

	call shy_info(id)

        call basin_init(nkn,nel)
        call levels_init(nkn,nel,nlv)
        call mod_depth_init(nkn,nel)
	call shy_copy_basin_from_shy(id)
	call shy_copy_levels_from_shy(id)
        call ev_init(nel)
	call set_ev

	if( ftype == 1 ) then		!OUS
	  if( nvar /= 4 ) goto 71
	  nndim = 3*nel
	  allocate(il(nel))
	  il = ilhv
	else if( ftype == 2 ) then	!NOS
	  nndim = nkn
	  allocate(il(nkn))
	  il = ilhkv
	else
	  goto 76	!relax later
	end if

	allocate(cv2(nndim))
	allocate(cv3(nlv,nndim))
	allocate(cv3all(nlv,nndim,0:nvar))

        allocate(hl(nlv))
	allocate(ivars(4,nvar))

	call shyutil_init(nkn,nel,nlv)

	call init_sigma_info(nlv,hlv)

	call shy_make_area
	call outfile_make_depth(nkn,nel,nen3v,hm3v,hev,hkv)

	if( bverb ) call depth_stats(nkn,nlvdi,ilhkv)

	call handle_nodes	!single node output

	!--------------------------------------------------------------
	! time management
	!--------------------------------------------------------------

	call shy_get_date(id,date,time)
	call elabutil_date_and_time	!this also sets datetime

	!--------------------------------------------------------------
	! averaging
	!--------------------------------------------------------------

	call elabutil_set_averaging(nvar)	!sets btrans

	if( btrans ) then
	  call shyutil_init_accum(nlvdi,nndim,nvar,istep)
	else
	  call shyutil_init_accum(1,1,1,1)
	end if

	!write(6,*) 'mode: ',mode,ifreq,istep

	!--------------------------------------------------------------
	! open output file
	!--------------------------------------------------------------

	iusplit = 0

	boutput = boutput .or. btrans
	bopen = boutput .and. .not. bsplit

	if( bopen ) then
	  idout = shy_init('out.shy')
          call shy_clone(id,idout)
	  if( b2d ) then
	    call shy_convert_2d(idout)
	  end if
          call shy_write_header(idout,ierr)
	  if( ierr /= 0 ) goto 75
	end if

	if( outformat == 'gis' ) call gis_write_connect

!--------------------------------------------------------------
! loop on data
!--------------------------------------------------------------

	dtvar = 0.
	dtime = 0.
	call shy_peek_record(id,dtime,iaux,iaux,iaux,iaux,ierr)
	call fem_file_convert_time(datetime,dtime,atime)

	cv3 = 0.
	cv3all = 0.

	do

	 atold = atime

	 call read_records(id,dtime,nvar,nndim,nlvdi,ivars
     +				,cv3,cv3all,ierr)

         if(ierr.ne.0) then	!EOF - see if we have to read another file
	   if( ierr > 0 ) exit
	   if( .not. bnextfile ) exit
	   idold = id
	   ifile = ifile + 1
	   call open_next_file(ifile,idold,id)
	   call shy_close(idold)
	   call get_start_of_next_file(ifile+1,atstart,bnextfile)
	   call nos_get_date(nin,date,time)
	   call elabutil_date_and_time
	   atime = atold	!reset time of last successfully read record
	   cycle
	 end if

	 nread = nread + nvar
	 nrec = nrec + 1
	 call fem_file_convert_time(datetime,dtime,atime)

	 call shy_peek_record(id,dtnew,iaux,iaux,iaux,iaux,ierr)
	 call fem_file_convert_time(datetime,dtnew,atnew)
	 if( ierr .ne. 0 ) atnew = atime

	 if( elabutil_over_time_a(atime,atnew,atold) ) exit
	 if( .not. elabutil_check_time_a(atime,atnew,atold) ) cycle

	 call shy_make_zeta(ftype)
	 call shy_make_volume

	 do iv=1,nvar

	  n = ivars(1,iv)
	  m = ivars(2,iv)
	  lmax = ivars(3,iv)
	  ivar = ivars(4,iv)
	  nn = n * m

	  cv3(:,:) = cv3all(:,:,iv)

	  nelab=nelab+1

	  if( .not. bquiet ) then
	    call shy_write_time(.true.,dtime,atime,ivar)
	  end if

	  if( bwrite ) then
	    !write(6,*) ivar,ivars(1,iv),ivars(2,iv),lmax,nn
	    call shy_write_min_max(nlvdi,nn,lmax,cv3)
	  end if

	  if( btrans ) then
	    call shy_time_aver(mode,iv,nrec,ifreq,istep,nndim
     +			,ivars,threshold,cv3,boutput)
	  end if

	  if( baverbas ) then
	    call shy_make_basin_aver(ivars(:,iv),nndim,cv3
     +                          ,cmin,cmax,cmed,vtot)
	    !call write_aver(it,ivar,cmin,cmax,cmed,vtot)
	  end if

	  if( b2d ) then
	    call shy_make_vert_aver(ivars(:,iv),nndim,cv3,cv2)
	  end if

	  if( bsplit ) then
            call get_split_iu(ndim,iusplit,ivar,nin,ilhkv,hlv,hev,nb)
	  end if

	  if( boutput ) then
	    nwrite = nwrite + 1
	    if( bverb ) write(6,*) 'writing to output: ',ivar
	    if( bsumvar ) ivar = 30
	    if( b2d ) then
	      !call shy_write_scalar_record2d(idout,dtime,ivar,cv2)
	      call shy_write_output_record(idout,dtime,ivar,n,m
     +						,1,1,cv2)
	    else
	      !call shy_write_scalar_record(idout,dtime,ivar,nlvdi,cv3)
	      call shy_write_output_record(idout,dtime,ivar,n,m
     +						,nlv,nlv,cv3)
	    end if
            if( ierr .ne. 0 ) goto 99
	  end if

	  if( bnodes ) then
	    call write_nodes(dtime,ivar,cv3)
	  end if

	 end do		!loop on ivar
	end do		!time do loop

!--------------------------------------------------------------
! end of loop on data
!--------------------------------------------------------------

!--------------------------------------------------------------
! final write of variables
!--------------------------------------------------------------

! next not working for b2d ... FIXME

	if( btrans ) then
	  !write(6,*) 'istep,naccu: ',istep,naccu
	  do ip=1,istep
	    naccum = naccu(iv,ip)
	    !write(6,*) 'naccum: ',naccum
	    if( naccum > 0 ) then
	      nwrite = nwrite + 1
	      write(6,*) 'final aver: ',ip,naccum
	      call nos_time_aver(-mode,ip,ifreq,istep,nkn,nlvdi
     +				,naccu,accum,std,threshold,cv3,boutput)
	      if( bsumvar ) ivar = 30
	      call shy_write_scalar_record(idout,dtime,ivar,nlvdi,cv3)
	    end if
	  end do
	end if

!--------------------------------------------------------------
! write final message
!--------------------------------------------------------------

	write(6,*)
	write(6,*) nread, ' records read'
	write(6,*) nrec , ' unique time records read'
	write(6,*) nelab, ' records elaborated'
	write(6,*) ifile, ' files read'
	write(6,*) nwrite,' records written'
	write(6,*)

	if( bsplit ) then
	  write(6,*) 'output written to following files: '
	  do ivar=1,ndim
	    nb = iusplit(ivar)
	    if( nb .gt. 0 ) then
              write(name,'(i4)') ivar
	      write(6,*) trim(adjustl(name))//'.nos'
	      close(nb)
	    end if
	  end do
	else if( boutput ) then
	  write(6,*) 'output written to file out.shy'
	  close(nb)
	end if

	!call ap_get_names(basnam,simnam)
	!write(6,*) 'names used: '
	!write(6,*) 'basin: ',trim(basnam)
	!write(6,*) 'simul: ',trim(simnam)

!--------------------------------------------------------------
! end of routine
!--------------------------------------------------------------

	stop
   71	continue
	write(6,*) 'ftype = ',ftype,'  nvar = ',nvar
	write(6,*) 'nvar should be 4'
	stop 'error stop shyelab: ftype,nvar'
   74	continue
	stop 'error stop shyelab: general error...'
   75	continue
	write(6,*) 'error writing header, ierr = ',ierr
	write(6,*) 'file = ',trim(file)
	stop 'error stop shyelab: writing header'
   76	continue
	write(6,*) 'ftype = ',ftype,'  expecting 1 or 2'
	stop 'error stop shyelab: ftype'
   77	continue
	write(6,*) 'error reading header, ierr = ',ierr
	write(6,*) 'file = ',trim(file)
	stop 'error stop shyelab: reading header'
   85	continue
	write(6,*) 'dtime,dtvar,iv,ivar,nvar: ',dtime,dtvar,iv,ivar,nvar
	stop 'error stop shyelab: time mismatch'
   92	continue
	write(6,*) 'incompatible basin: '
	write(6,*) 'nkn,nknnos: ',nkn,nknnos
	write(6,*) 'nel,nelnos: ',nel,nelnos
	stop 'error stop shyelab: parameter mismatch'
   99	continue
	write(6,*) 'error writing to file unit: ',nb
	stop 'error stop shyelab: write error'
	end

!***************************************************************
!***************************************************************
!***************************************************************

