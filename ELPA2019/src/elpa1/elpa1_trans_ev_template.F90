#if 0
!    This file is part of ELPA.
!
!    The ELPA library was originally created by the ELPA consortium,
!    consisting of the following organizations:
!
!    - Max Planck Computing and Data Facility (MPCDF), formerly known as
!      Rechenzentrum Garching der Max-Planck-Gesellschaft (RZG),
!    - Bergische Universität Wuppertal, Lehrstuhl für angewandte
!      Informatik,
!    - Technische Universität München, Lehrstuhl für Informatik mit
!      Schwerpunkt Wissenschaftliches Rechnen ,
!    - Fritz-Haber-Institut, Berlin, Abt. Theorie,
!    - Max-Plack-Institut für Mathematik in den Naturwissenschaften,
!      Leipzig, Abt. Komplexe Strukutren in Biologie und Kognition,
!      and
!    - IBM Deutschland GmbH
!
!    This particular source code file contains additions, changes and
!    enhancements authored by Intel Corporation which is not part of
!    the ELPA consortium.
!
!    More information can be found here:
!    http://elpa.mpcdf.mpg.de/
!
!    ELPA is free software: you can redistribute it and/or modify
!    it under the terms of the version 3 of the license of the
!    GNU Lesser General Public License as published by the Free
!    Software Foundation.
!
!    ELPA is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU Lesser General Public License for more details.
!
!    You should have received a copy of the GNU Lesser General Public License
!    along with ELPA.  If not, see <http://www.gnu.org/licenses/>
!
!    ELPA reflects a substantial effort on the part of the original
!    ELPA consortium, and we ask you to respect the spirit of the
!    license that we chose: i.e., please contribute any changes you
!    may have back to the original ELPA library distribution, and keep
!    any derivatives of ELPA under the same license that we chose for
!    the original distribution, the GNU Lesser General Public License.
!
!
! ELPA1 -- Faster replacements for ScaLAPACK symmetric eigenvalue routines
!
! Copyright of the original code rests with the authors inside the ELPA
! consortium. The copyright of any additional modifications shall rest
! with their original authors, but shall adhere to the licensing terms
! distributed along with the original code in the file "COPYING".
#endif

#include "../general/sanity.F90"

!> \brief Transforms the eigenvectors of a tridiagonal matrix back
!>                     to the eigenvectors of the original matrix
!>                     (like Scalapack Routine PDORMTR)
!>
!  Parameters
!
!> \param na          Order of matrix a_mat, number of rows of matrix q_mat
!>
!> \param nqc         Number of columns of matrix q_mat
!>
!> \param a_mat(lda,matrixCols)  Matrix containing the Householder vectors (i.e. matrix a after tridiag_real)
!>                           Distribution is like in Scalapack.
!>
!> \param lda         Leading dimension of a_mat
!>
!> \param tau(na)     Factors of the Householder vectors
!>
!> \param q_mat           On input: Eigenvectors of tridiagonal matrix
!>                    On output: Transformed eigenvectors
!>                    Distribution is like in Scalapack.
!>
!> \param ldq         Leading dimension of q_mat
!>
!> \param nblk        blocksize of cyclic distribution, must be the same in both directions!
!>
!> \param matrixCols  local columns of matrix a_mat and q_mat
!>
!> \param mpi_comm_rows        MPI-Communicator for rows
!>
!> \param mpi_comm_cols        MPI-Communicator for columns
!>
!> \param useGPU      If true,  GPU version of the subroutine will be used
!>

    subroutine trans_ev_&
    &MATH_DATATYPE&
    &_&
    &PRECISION &
    (obj, na, nqc, a_mat, lda, tau, q_mat, ldq, nblk, matrixCols, mpi_comm_rows, mpi_comm_cols, useGPU)
      use cuda_functions
      use iso_c_binding
      use precision
      use elpa_abstract_impl
      use elpa_blas_interfaces

      implicit none
#include "../general/precision_kinds.F90"
      class(elpa_abstract_impl_t), intent(inout)    :: obj
      integer(kind=ik), intent(in)                  :: na, nqc, lda, ldq, nblk, matrixCols, mpi_comm_rows, mpi_comm_cols
      MATH_DATATYPE(kind=rck), intent(in)           :: tau(na)

#ifdef USE_ASSUMED_SIZE
      MATH_DATATYPE(kind=rck), intent(inout)        :: a_mat(lda,*)
      MATH_DATATYPE(kind=rck), intent(inout)        :: q_mat(ldq,*)
#else
      MATH_DATATYPE(kind=rck), intent(inout)        :: a_mat(lda,matrixCols)
      MATH_DATATYPE(kind=rck), intent(inout)        :: q_mat(ldq,matrixCols)
#endif
      logical, intent(in)                           :: useGPU
      integer(kind=ik)                              :: max_stored_rows, max_stored_rows_fac

      integer(kind=ik)                              :: my_prow, my_pcol, np_rows, np_cols
      integer(kind=MPI_KIND)                        :: mpierr, my_prowMPI, my_pcolMPI, np_rowsMPI, np_colsMPI
      integer(kind=ik)                              :: totalblocks, max_blocks_row, max_blocks_col, max_local_rows, max_local_cols
      integer(kind=ik)                              :: l_cols, l_rows, l_colh, nstor
      integer(kind=ik)                              :: istep, n, nc, ic, ics, ice, nb, cur_pcol
      integer(kind=ik)                              :: hvn_ubnd, hvm_ubnd

      MATH_DATATYPE(kind=rck), allocatable          :: hvb(:), hvm(:,:)
      MATH_DATATYPE(kind=rck), allocatable          :: tmp1(:), tmp2(:)
      MATH_DATATYPE(kind=rck), allocatable          :: h1(:), h2(:)
      MATH_DATATYPE(kind=rck), allocatable          :: tmat(:,:), hvm1(:)

      integer(kind=ik)                              :: istat
      character(200)                                :: errorMessage
      character(20)                                 :: gpuString

      integer(kind=C_intptr_T)                      :: q_dev, tmp_dev, hvm_dev, tmat_dev
      logical                                       :: successCUDA
      integer(kind=c_intptr_t), parameter           :: size_of_datatype = size_of_&
                                                                          &PRECISION&
                                                                          &_&
                                                                          &MATH_DATATYPE
      integer(kind=ik)                              :: error
      if(useGPU) then
        gpuString = "_gpu"
      else
        gpuString = ""
      endif

      call obj%timer%start("trans_ev_&
      &MATH_DATATYPE&
      &" // &
      &PRECISION_SUFFIX //&
      gpuString)

      call obj%timer%start("mpi_communication")
      call mpi_comm_rank(int(mpi_comm_rows,kind=MPI_KIND) ,my_prowMPI, mpierr)
      call mpi_comm_size(int(mpi_comm_rows,kind=MPI_KIND) ,np_rowsMPI, mpierr)
      call mpi_comm_rank(int(mpi_comm_cols,kind=MPI_KIND) ,my_pcolMPI, mpierr)
      call mpi_comm_size(int(mpi_comm_cols,kind=MPI_KIND) ,np_colsMPI, mpierr)

      my_prow = int(my_prowMPI, kind=c_int)
      np_rows = int(np_rowsMPI, kind=c_int)
      my_pcol = int(my_pcolMPI, kind=c_int)
      np_cols = int(np_colsMPI, kind=c_int)
      call obj%timer%stop("mpi_communication")

      call obj%get("max_stored_rows",max_stored_rows_fac, error)

      totalblocks = (na-1)/nblk + 1
      max_blocks_row = (totalblocks-1)/np_rows + 1
      max_blocks_col = ((nqc-1)/nblk)/np_cols + 1  ! Columns of q_mat!

      max_local_rows = max_blocks_row*nblk
      max_local_cols = max_blocks_col*nblk

      max_stored_rows = (max_stored_rows_fac/nblk+1)*nblk

      allocate(tmat(max_stored_rows,max_stored_rows), stat=istat, errmsg=errorMessage)
      call check_alloc("trans_ev_&
      &MATH_DATATYPE&
      &", "tmat", istat, errorMessage)

      allocate(h1(max_stored_rows*max_stored_rows), stat=istat, errmsg=errorMessage)
      call check_alloc("trans_ev_&
      &MATH_DATATYPE&
      &", "h1", istat, errorMessage)

      allocate(h2(max_stored_rows*max_stored_rows), stat=istat, errmsg=errorMessage)
      call check_alloc("trans_ev_&
      &MATH_DATATYPE&
      &", "h2", istat, errorMessage)

      allocate(tmp1(max_local_cols*max_stored_rows), stat=istat, errmsg=errorMessage)
      call check_alloc("trans_ev_&
      &MATH_DATATYPE&
      &", "tmp1", istat, errorMessage)

      allocate(tmp2(max_local_cols*max_stored_rows), stat=istat, errmsg=errorMessage)
      call check_alloc("trans_ev_&
      &MATH_DATATYPE&
      &", "tmp2", istat, errorMessage)

      allocate(hvb(max_local_rows*nblk), stat=istat, errmsg=errorMessage)
      call check_alloc("trans_ev_&
      &MATH_DATATYPE&
      &", "hvn", istat, errorMessage)

      allocate(hvm(max_local_rows,max_stored_rows), stat=istat, errmsg=errorMessage)
      call check_alloc("trans_ev_&
      &MATH_DATATYPE&
      &", "hvm", istat, errorMessage)

      hvm = 0   ! Must be set to 0 !!!
      hvb = 0   ! Safety only

      l_cols = local_index(nqc, my_pcol, np_cols, nblk, -1) ! Local columns of q_mat

      nstor = 0
      if (useGPU) then
        hvn_ubnd = 0
      endif

#if COMPLEXCASE == 1
      ! In the complex case tau(2) /= 0
      if (my_prow == prow(1, nblk, np_rows)) then
        q_mat(1,1:l_cols) = q_mat(1,1:l_cols)*(ONE-tau(2))
      endif
#endif

      if (useGPU) then
        ! todo: this is used only for copying hmv to device.. it should be possible to go without it
        allocate(hvm1(max_local_rows*max_stored_rows), stat=istat, errmsg=errorMessage)
        call check_alloc("trans_ev_&
        &MATH_DATATYPE&
        &", "hvm1", istat, errorMessage)

        successCUDA = cuda_malloc(tmat_dev, max_stored_rows * max_stored_rows * size_of_datatype)
        check_alloc_cuda("trans_ev", successCUDA)

        successCUDA = cuda_malloc(hvm_dev, max_local_rows * max_stored_rows * size_of_datatype)
        check_alloc_cuda("trans_ev", successCUDA)

        successCUDA = cuda_malloc(tmp_dev, max_local_cols * max_stored_rows * size_of_datatype)
        check_alloc_cuda("trans_ev", successCUDA)

        successCUDA = cuda_malloc(q_dev, ldq * matrixCols * size_of_datatype)
        check_alloc_cuda("trans_ev", successCUDA)

!         q_dev = q_mat
        successCUDA = cuda_memcpy(q_dev, int(loc(q_mat(1,1)),kind=c_intptr_t), &
                      ldq * matrixCols * size_of_datatype, cudaMemcpyHostToDevice)
        check_memcpy_cuda("trans_ev", successCUDA)
      endif  ! useGPU

      do istep = 1, na, nblk
        ics = MAX(istep,3)
        ice = MIN(istep+nblk-1,na)
        if (ice<ics) cycle

        cur_pcol = pcol(istep, nblk, np_cols)

        nb = 0
        do ic = ics, ice

          l_colh = local_index(ic  , my_pcol, np_cols, nblk, -1) ! Column of Householder Vector
          l_rows = local_index(ic-1, my_prow, np_rows, nblk, -1) ! # rows of Householder Vector


          if (my_pcol == cur_pcol) then
            hvb(nb+1:nb+l_rows) = a_mat(1:l_rows,l_colh)
            if (my_prow == prow(ic-1, nblk, np_rows)) then
              hvb(nb+l_rows) = 1.
            endif
          endif

          nb = nb+l_rows
        enddo

#ifdef WITH_MPI
        call obj%timer%start("mpi_communication")
        if (nb>0) &
          call MPI_Bcast(hvb, int(nb,kind=MPI_KIND), MPI_MATH_DATATYPE_PRECISION , int(cur_pcol,kind=MPI_KIND), &
                         int(mpi_comm_cols,kind=MPI_KIND), mpierr)
        call obj%timer%stop("mpi_communication")
#endif /* WITH_MPI */

        nb = 0
        do ic = ics, ice
          l_rows = local_index(ic-1, my_prow, np_rows, nblk, -1) ! # rows of Householder Vector
          hvm(1:l_rows,nstor+1) = hvb(nb+1:nb+l_rows)
          if (useGPU) then
            hvm_ubnd = l_rows
          endif
          nstor = nstor+1
          nb = nb+l_rows
        enddo

        ! Please note: for smaller matix sizes (na/np_rows<=256), a value of 32 for nstor is enough!
        if (nstor+nblk > max_stored_rows .or. istep+nblk > na .or. (na/np_rows <= 256 .and. nstor >= 32)) then

          ! Calculate scalar products of stored vectors.
          ! This can be done in different ways, we use dsyrk or zherk

          tmat = 0
          call obj%timer%start("blas")
          if (l_rows>0) &
#if REALCASE == 1
            call PRECISION_SYRK('U', 'T',   &
#endif
#if COMPLEXCASE == 1
            call PRECISION_HERK('U', 'C',   &
#endif
                                 int(nstor,kind=BLAS_KIND), int(l_rows,kind=BLAS_KIND), ONE, &
                                 hvm, int(ubound(hvm,dim=1),kind=BLAS_KIND), ZERO, tmat, int(max_stored_rows,kind=BLAS_KIND))
          call obj%timer%stop("blas")
          nc = 0
          do n = 1, nstor-1
            h1(nc+1:nc+n) = tmat(1:n,n+1)
            nc = nc+n
          enddo
#ifdef WITH_MPI
          call obj%timer%start("mpi_communication")
          if (nc>0) call mpi_allreduce( h1, h2, int(nc,kind=MPI_KIND), MPI_MATH_DATATYPE_PRECISION, MPI_SUM, &
                                       int(mpi_comm_rows,kind=MPI_KIND), mpierr)
          call obj%timer%stop("mpi_communication")
#else /* WITH_MPI */

          if (nc > 0) h2 = h1

#endif /* WITH_MPI */
          ! Calculate triangular matrix T

          nc = 0
          tmat(1,1) = tau(ice-nstor+1)
          do n = 1, nstor-1
            call obj%timer%start("blas")
            call PRECISION_TRMV('L', BLAS_TRANS_OR_CONJ , 'N', int(n,kind=BLAS_KIND), tmat, &
                                int(max_stored_rows,kind=BLAS_KIND), h2(nc+1), 1_BLAS_KIND)
            call obj%timer%stop("blas")

            tmat(n+1,1:n) = &
#if REALCASE == 1
            -h2(nc+1:nc+n)  &
#endif
#if COMPLEXCASE == 1
            -conjg(h2(nc+1:nc+n)) &
#endif
            *tau(ice-nstor+n+1)

            tmat(n+1,n+1) = tau(ice-nstor+n+1)
            nc = nc+n
          enddo

          if (useGPU) then
            ! todo: is this reshape really neccessary?
            hvm1(1:hvm_ubnd*nstor) = reshape(hvm(1:hvm_ubnd,1:nstor), (/ hvm_ubnd*nstor /))

            !hvm_dev(1:hvm_ubnd*nstor) = hvm1(1:hvm_ubnd*nstor)
            successCUDA = cuda_memcpy(hvm_dev, int(loc(hvm1(1)),kind=c_intptr_t),   &
                          hvm_ubnd * nstor * size_of_datatype, cudaMemcpyHostToDevice)

            check_memcpy_cuda("trans_ev", successCUDA)

            !tmat_dev = tmat
            successCUDA = cuda_memcpy(tmat_dev, int(loc(tmat(1,1)),kind=c_intptr_t),   &
                          max_stored_rows * max_stored_rows * size_of_datatype, cudaMemcpyHostToDevice)
            check_memcpy_cuda("trans_ev", successCUDA)
          endif

          ! Q = Q - V * T * V**T * Q

          if (l_rows>0) then
            if (useGPU) then
              call obj%timer%start("cublas")
              call cublas_PRECISION_GEMM(BLAS_TRANS_OR_CONJ, 'N',   &
                                         nstor, l_cols, l_rows, ONE, hvm_dev, hvm_ubnd,  &
                                         q_dev, ldq, ZERO, tmp_dev, nstor)
              call obj%timer%stop("cublas")

            else ! useGPU

              call obj%timer%start("blas")
              call PRECISION_GEMM(BLAS_TRANS_OR_CONJ, 'N',  &
                                  int(nstor,kind=BLAS_KIND), int(l_cols,kind=BLAS_KIND), &
                                  int(l_rows,kind=BLAS_KIND), ONE, hvm, int(ubound(hvm,dim=1),kind=BLAS_KIND), &
                                  q_mat, int(ldq,kind=BLAS_KIND), ZERO, tmp1, int(nstor,kind=BLAS_KIND))
              call obj%timer%stop("blas")
            endif ! useGPU

          else !l_rows>0

            if (useGPU) then
              successCUDA = cuda_memset(tmp_dev, 0, l_cols * nstor * size_of_datatype)
              check_memcpy_cuda("trans_ev", successCUDA)
            else
              tmp1(1:l_cols*nstor) = 0
            endif
          endif  !l_rows>0

#ifdef WITH_MPI
          ! In the legacy GPU version, this allreduce was ommited. But probably it has to be done for GPU + MPI
          ! todo: does it need to be copied whole? Wouldn't be a part sufficient?
          if (useGPU) then
            successCUDA = cuda_memcpy(int(loc(tmp1(1)),kind=c_intptr_t), tmp_dev,  &
                          max_local_cols * max_stored_rows * size_of_datatype, cudaMemcpyDeviceToHost)
            check_memcpy_cuda("trans_ev", successCUDA)
          endif
          call obj%timer%start("mpi_communication")
          call mpi_allreduce(tmp1, tmp2, int(nstor*l_cols,kind=MPI_KIND), MPI_MATH_DATATYPE_PRECISION, MPI_SUM, &
                             int(mpi_comm_rows,kind=MPI_KIND), mpierr)
          call obj%timer%stop("mpi_communication")
          ! copy back tmp2 - after reduction...
          if (useGPU) then
            successCUDA = cuda_memcpy(tmp_dev, int(loc(tmp2(1)),kind=c_intptr_t),  &
                          max_local_cols * max_stored_rows * size_of_datatype, cudaMemcpyHostToDevice)
            check_memcpy_cuda("trans_ev", successCUDA)
          endif ! useGPU


#else /* WITH_MPI */
!          tmp2 = tmp1
#endif /* WITH_MPI */

          if (l_rows>0) then
            if (useGPU) then
              call obj%timer%start("cublas")
              call cublas_PRECISION_TRMM('L', 'L', 'N', 'N',     &
                                         nstor, l_cols, ONE, tmat_dev, max_stored_rows,  &
                                         tmp_dev, nstor)

              call cublas_PRECISION_GEMM('N', 'N' ,l_rows ,l_cols ,nstor,  &
                                         -ONE, hvm_dev, hvm_ubnd, tmp_dev, nstor,   &
                                         ONE, q_dev, ldq)
              call obj%timer%stop("cublas")
            else !useGPU
#ifdef WITH_MPI
              ! tmp2 = tmat * tmp2
              call obj%timer%start("blas")
              call PRECISION_TRMM('L', 'L', 'N', 'N', int(nstor,kind=BLAS_KIND), int(l_cols,kind=BLAS_KIND),   &
                                  ONE, tmat, int(max_stored_rows,kind=BLAS_KIND), tmp2, int(nstor,kind=BLAS_KIND))
              !q_mat = q_mat - hvm*tmp2
              call PRECISION_GEMM('N', 'N', int(l_rows,kind=BLAS_KIND), int(l_cols,kind=BLAS_KIND), int(nstor,kind=BLAS_KIND),   &
                                  -ONE, hvm, int(ubound(hvm,dim=1),kind=BLAS_KIND), tmp2, int(nstor,kind=BLAS_KIND), &
                                  ONE, q_mat, int(ldq,kind=BLAS_KIND))
              call obj%timer%stop("blas")
#else /* WITH_MPI */
              call obj%timer%start("blas")

              call PRECISION_TRMM('L', 'L', 'N', 'N', int(nstor,kind=BLAS_KIND), int(l_cols,kind=BLAS_KIND),   &
                                  ONE, tmat, int(max_stored_rows,kind=BLAS_KIND), tmp1, int(nstor,kind=BLAS_KIND))
              call PRECISION_GEMM('N', 'N', int(l_rows,kind=BLAS_KIND), int(l_cols,kind=BLAS_KIND), &
                                  int(nstor,kind=BLAS_KIND), -ONE, hvm, int(ubound(hvm,dim=1),kind=BLAS_KIND), &
                                  tmp1, int(nstor,kind=BLAS_KIND), ONE, q_mat, int(ldq,kind=BLAS_KIND))
              call obj%timer%stop("blas")
#endif /* WITH_MPI */
            endif ! useGPU
          endif  ! l_rows>0
          nstor = 0
        endif  ! (nstor+nblk>max_stored_rows .or. istep+nblk>na .or. (na/np_rows<=256 .and. nstor>=32))

      enddo ! istep=1,na,nblk

      deallocate(tmat, h1, h2, tmp1, tmp2, hvb, hvm, stat=istat, errmsg=errorMessage)
      if (istat .ne. 0) then
        print *,"trans_ev_&
        &MATH_DATATYPE&
        &: error when deallocating hvm "//errorMessage
        stop 1
      endif

      if (useGPU) then
        !q_mat = q_dev
        successCUDA = cuda_memcpy(int(loc(q_mat(1,1)),kind=c_intptr_t), &
                      q_dev, ldq * matrixCols * size_of_datatype, cudaMemcpyDeviceToHost)
        check_memcpy_cuda("trans_ev", successCUDA)

        deallocate(hvm1, stat=istat, errmsg=errorMessage)
        if (istat .ne. 0) then
          print *,"trans_ev_&
          &MATH_DATATYPE&
          &: error when deallocating hvm1 "//errorMessage
          stop 1
        endif

        !deallocate(q_dev, tmp_dev, hvm_dev, tmat_dev)
        successCUDA = cuda_free(q_dev)
        check_dealloc_cuda("trans_ev", successCUDA)

        successCUDA = cuda_free(tmp_dev)
        check_dealloc_cuda("trans_ev", successCUDA)

        successCUDA = cuda_free(hvm_dev)
        check_dealloc_cuda("trans_ev", successCUDA)

        successCUDA = cuda_free(tmat_dev)
        check_dealloc_cuda("trans_ev", successCUDA)

      endif

      call obj%timer%stop("trans_ev_&
      &MATH_DATATYPE&
      &" // &
      &PRECISION_SUFFIX // &
      gpuString )

    end subroutine trans_ev_&
    &MATH_DATATYPE&
    &_&
    &PRECISION
