!> Module containing all of the statements written to the command line during
!! compilation
!! 
!! There are several levels of feedback, indicated by a variable stored in
!! settings%feedback  :
!!
!! | integer  | Feedback level  
!! |----------|--------------------
!! |    0     | Only output the final evidence and error
!! |    1     | Indicate when entering various major sections of the program

module feedback_module
    implicit none

    contains

    !> Called before running the program
    subroutine write_opening_statement(settings)
        use utils_module,    only: logzero,stdout_unit
        use settings_module, only: program_settings
        implicit none
        type(program_settings), intent(in) :: settings  ! The program settings 


        if(settings%feedback >=1) then
            write(stdout_unit,'("Nested Sampling Algorithm")')
            write(stdout_unit,'("  author: Will Handley")')
            write(stdout_unit,'("   email: wh260@cam.ac.uk")')
            write(stdout_unit,'("")')
        end if

        if(settings%feedback >=0) then
            write(stdout_unit,'("nlive      :",I8)')   settings%nlive
            write(stdout_unit,'("nDims      :",I8)')   settings%nDims
            write(stdout_unit,'("nDerived   :",I8)')   settings%nDerived
        end if
       



    end subroutine write_opening_statement



    !> Called before generating the live points
    subroutine write_started_generating(feedback)
        use utils_module,    only: stdout_unit
        implicit none
        !> The degree of feedback required
        integer, intent(in) :: feedback 


        if (feedback>=1) then
            write(stdout_unit,'("generating live points")')
        end if

    end subroutine write_started_generating

    !> Called during generation of the live points
    !!
    !! Prints a neat progress bar to show you how far its got
    subroutine write_generating_live_points(feedback,i_live,nlive)
        implicit none
        !> The degree of feedback required
        integer, intent(in) :: feedback 

        !> The current number of live points generate
        integer, intent(in) :: i_live
        !> The number of live points to be generated
        integer, intent(in) :: nlive

        if (feedback>=1) then
            call progress(dble(i_live)/dble(nlive))
        end if

    end subroutine write_generating_live_points

    !> Called at the end of generating the live points
    subroutine write_finished_generating(feedback)
        use utils_module,    only: stdout_unit
        implicit none
        !> The degree of feedback required
        integer, intent(in) :: feedback 


        if (feedback>=1) then
            write(stdout_unit,'("all live points generated")')
        end if

    end subroutine write_finished_generating


    !> Subroutine to produce a progress bar of (optional) length brz, with frac
    !! filled
    !!
    !! Note that you shouldn't put any write statements in between using this
    !! subroutine.
    subroutine progress(frac,brsz)
        use utils_module,    only: stdout_unit
        implicit none

        !> fraction completed
        double precision,intent(in) :: frac
        !> The size of the progress bar
        integer,intent(in),optional :: brsz

        
        integer :: percent                    ! the percentage completed
        character(:), allocatable ::bar       ! the bounds on the progress bar
        integer :: bar_size                   ! bar size
        integer :: i                          ! loop variable


        if(present(brsz))then
            ! If a specific bar size is requested set bar_size to brsz
            bar_size=brsz
        else
            ! Otherwise default to 100
            bar_size=100
        endif


        ! Convert the fraction to an integer percentage
        percent = 100 * frac

        ! Create the progress bar structure:
        ! e.g.  bar = "???% |                     |"
        ! The question marks indicate where the percentage completed will be
        ! written to.
        !
        ! Start:
        bar="???% |"
        do i= 1, bar_size
            ! Put in bar_size number of spaces
            bar = bar//' '
        end do
        ! Finish
        bar = bar//'|'

        ! Write the percentage to the bar variable, so it now reads
        ! e.g.  bar = " 70% |                     |"
        write(unit=bar(1:3),fmt="(i3)") percent

        ! Produce a number of *'s to indicade the progress, so it now reads
        ! e.g.  bar = " 70% |***************      |"
        do i=1, int(frac*bar_size)
            bar(6+i:6+i)="*"
        enddo

        ! print the progress bar to stdout (unit 6)
        write(stdout_unit,fmt="(a1,a<bar_size+7>)",advance="no") char(13), bar

        if (percent/=100) then
            ! If we're not at the end, then we should flush the command line so
            ! that we re-start from the beginning next time
            flush(stdout_unit)
        else
            ! Otherwise, we should just write a blank line 
            write(stdout_unit,fmt=*)
        endif
        return
    end subroutine progress

    !> Called before starting sampling
    subroutine write_started_sampling(feedback)
        use utils_module,    only: stdout_unit
        implicit none
        !> The degree of feedback required
        integer, intent(in) :: feedback 


        if (feedback>=1) then
            write(stdout_unit,'("started sampling")')
        end if

    end subroutine write_started_sampling

    !> Intermediate results
    subroutine write_intermediate_results(settings,info,ndead,nphantom,nposterior,mean_likelihood_calls)
        use evidence_module, only: run_time_info
        use settings_module, only: program_settings
        use utils_module,    only: stdout_unit,logzero
        implicit none
        type(program_settings), intent(in) :: settings
        type(run_time_info),intent(in)     :: info
        integer,intent(in)                 :: ndead
        integer,intent(in),dimension(settings%ncluster)    :: nphantom
        integer,intent(in),dimension(0:settings%ncluster)    :: nposterior
        double precision,intent(in)        :: mean_likelihood_calls

        integer :: i

        double precision, dimension(info%ncluster_A) :: mu
        double precision, dimension(info%ncluster_A) :: sigma


        if (settings%feedback>=1) then
            write(stdout_unit,'("ndead      =",  I8                   )') ndead
            if(settings%calculate_posterior) &
            write(stdout_unit,'("nposterior =",  I8                   )') nposterior(0)
            write(stdout_unit,'("ncluster   = ", I7                   )') info%ncluster_A
            write(stdout_unit,'("nclustertot= ", I7                   )') info%ncluster_A+info%ncluster_P
            write(stdout_unit,'("lives      =   ", <info%ncluster_A>I5)')  info%n(:info%ncluster_A)
            write(stdout_unit,'("phantoms   =   ", <info%ncluster_A>I5)')  nphantom(:info%ncluster_A)
            if(settings%calculate_posterior) &
            write(stdout_unit,'("posteriors =   ", <info%ncluster_A>I5)')  nposterior(1:info%ncluster_A)
            write(stdout_unit,'("efficiency = ", F7.2, "    (",F5.2," per slice)")') mean_likelihood_calls, mean_likelihood_calls/settings%num_babies
            

            mu(1)    = 2*info%logevidence - 0.5*info%logevidence2              
            sigma(1) = sqrt(info%logevidence2 - 2*info%logevidence)

            if(info%logevidence>logzero) then
                write(stdout_unit,'("log(Z)     = ", F10.5, " +/- ", F10.5)') mu(1),sigma(1)
            end if

            mu    = 2*info%logZ - 0.5*info%logZ2              
            sigma = sqrt(info%logZ2 - 2*info%logZ)

            if(info%ncluster_A>1) then
                do i=1,info%ncluster_A  
                    if(info%logZ(i)>logzero) then
                        write(stdout_unit,'("log(Z_",I2,")  = ", F10.5, " +/- ", F10.5)') i, mu(i),sigma(i)
                    else
                        write(stdout_unit,'("log(Z_",I2,")  = ?")') i
                    end if
                end do
            end if



            write(stdout_unit,'("")')
        end if


    end subroutine write_intermediate_results



    !> Nicely formatted final output statement
    subroutine write_final_results(output_info,feedback,priors)
        use utils_module,    only: stdout_unit
        use priors_module,   only: prior,prior_log_volume
        implicit none
        !> Output of the program.
        !! # log(evidence)
        !! # error(log(evidence))
        !! # ndead
        !! # number of likelihood calls
        double precision, dimension(4) :: output_info
        !> The degree of feedback required
        integer, intent(in) :: feedback 
        !> The prior information
        type(prior), dimension(:), intent(in) :: priors

        if (feedback>=0) then
            write(stdout_unit,'(A42)')                                        ' ________________________________________ '
            write(stdout_unit,'(A42)')                                        '|                                        |'
            write(stdout_unit,'("| ndead  = ", I12, "                  |"  )') nint(output_info(3))
            write(stdout_unit,'("| nlike  = ", I12, "                  |"  )') nint(output_info(4)) 
            write(stdout_unit,'("| log(Z) = ", F12.5, " +/- ", F12.5,  " |")') output_info(1:2)
            write(stdout_unit,'("| check  = ", F12.5, " +/- ", F12.5,  " |")') output_info(1)+prior_log_volume(priors),output_info(2)
            write(stdout_unit,'(A42)')                                        '|________________________________________|'
        endif
    end subroutine write_final_results

end module feedback_module
