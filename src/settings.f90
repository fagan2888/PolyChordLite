!> This module encodes the type 'program_settings' which contains all of the
!! details required to perform a nested sampling run.
module settings_module
    use priors_module,   only: prior
    use utils_module,   only: STR_LENGTH
    implicit none

    !> Type to contain all of the parameters involved in a nested sampling run
    Type :: program_settings

        !> The file root for outputs
        character(STR_LENGTH) :: file_root='chains/test'

        !> The number of live points
        integer :: nlive =500

        !> The number of live points
        integer :: nstack =500*10

        !> The degree of feedback to provide
        integer :: feedback = 1

        !> The degree of precision in the final answer
        double precision :: precision_criterion = 1d-5

        !> The maximum number of dead points/samples
        !!
        !! Set equal to -1 for no maximum number
        integer :: max_ndead = -1

        !> The maximum number of posterior points
        !!
        !! This is for memory allocation purposes, it won't necessarily have
        !! this many points if they're not 'good enough'
        integer :: nmax_posterior = 100000

        !> The minimum weight of the posterior points
        double precision :: minimum_weight = 1d-15

        !> Whether or not to calculate the posterior
        logical :: calculate_posterior = .true.

        !> Whether or not to write resume files
        logical :: write_resume = .true.

        !> How often to update the resume file
        integer :: update_resume = 10000

        !> The number of chords to draw
        integer :: num_chords

        !> The number of chords to draw if we're doing a fast-slow algorithm
        integer, dimension(:), allocatable :: nums_chords

        !> Whether or not to resume from file
        logical :: read_resume = .true.

        !> The number of reflection step in between randomisation steps
        integer :: num_reflections = 4

        !> Dimensionality of the space
        integer :: nDims = 1
        !> Number of derived parameters
        integer :: nDerived = 0   
        !> 2*ndims + nDerived + 1
        integer :: nTotal      

        ! Indices for the sections of a live_points array

        !> hypercube indices
        !!
        !! These are the coordinates in the unit hypercube.
        !! h0 indicates the starting index, h1 the finishing index.
        integer :: h0,h1       

        !> physical indices
        !!
        !! These are the coordinates in the physical space 
        !! These are linked to the hypercube coordinates via the prior.
        !! p0 indicates the starting index, p1 the finishing index
        integer :: p0,p1       

        !> derived indices
        !!
        !! These are the indices of the derived parameters to be calculated
        !! during the run.
        !! d0 indicates the starting index, d1 the finishing index
        integer :: d0,d1       

        ! Algorithm indices
        !> The number of likelihood evaluations required to calculate this point
        integer :: nlike
        !> The last chord length used in calculating this point
        integer :: last_chord
#ifdef MPI
        !> Pointer to any daughter points
        integer :: daughter
#endif

        !> likelihood index
        !!
        !! This is the likelihood evaluated at the position of the live point
        integer :: l0          
        !> This is the likelihood contour which generated the live point
        integer :: l1          

        !> Pointer to any additional files that need to be stored in between
        !! evaluations (only really important for C likelihoods)
        integer :: context

        !> Grades of parameters
        !!
        !! In the case of 'fast-slow' parameters, these indicate the 'grade' of
        !! parameter. grade=1 is slowest, 
        integer, dimension(:), allocatable :: grade

        !> Save all dead points (can be very expensive in high dimensions)
        logical :: save_all = .false.


        !> Pointer to the sampling procedure.
        !!
        !! e.g: MultiNest, Galilean Sampling, Hamiltonian sampling ...
        !! 
        !! If you wish to write a new sampling procedure, the best way is to
        !! create a new module 'my_sampling_procedure_module' and program it in
        !! there with the interface specified in samp. Once this is done you can
        !! point to in it the main program by writing
        !!
        !! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        !! settings%sampler => my_sampling_procedure
        !! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        !!
        !! where settings is of type program_settings: 
        !!
        !! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        !! type(program settings) :: settings
        !! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        !!
        !! and should be passed to the NestedSampling algorithm 
        !!
        procedure(samp), pass(settings),       pointer :: sampler


        !> Pointer to the evidence calculator
        !!
        !! e.g: KeetonEvidence, SkillingEvidence
        !!
        !! @todo write a skilling evidence algorithm
        !!
        !! If you wish to write a evidence calculator, the best way is to
        !! write a new subroutine 'my_evidence_calculator' with the interface
        !! specified in ev. Once this is done you can point to in it the main
        !! program by writing
        !!
        !! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        !! settings%evidence_calculator => my_evidence_calculator
        !! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        !!
        !! where settings is of type program_settings: 
        !!
        !! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        !! type(program settings) :: settings
        !! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        !!
        !! and should be passed to the NestedSampling algorithm 
        !!
        procedure(ev),   pass(settings), pointer :: evidence_calculator

        !> Pointer to the generator of nhats for the chordal sampling procedure
        procedure(dir),   pass(settings), pointer :: generate_directions

    end type program_settings

    interface
        !> Interface to the sampling procedure
        !!
        !! The sampling procedure takes the details of the model (M) and the current
        !! set of live points (live_data) in order to generate a baby_point
        !! uniformly sampled from within the loglikelihood contour specifed by
        !! loglikelihood bound contained at the settings%l1 index of seed_point
        function samp(loglikelihood,priors,settings,nhats,seed_point) result(baby_point)

            import :: program_settings   
            import :: prior
            implicit none
            interface
                function loglikelihood(theta,phi,context)
                    double precision, intent(in),  dimension(:) :: theta
                    double precision, intent(out),  dimension(:) :: phi
                    integer,          intent(in)                 :: context
                    double precision :: loglikelihood
                end function
            end interface

            ! ------- Inputs -------
            !> The prior information
            type(prior), dimension(:), intent(in) :: priors

            !> program settings (mostly useful to pass on the number of live points)
            class(program_settings), intent(in) :: settings

            !> The seed point
            double precision, intent(in), dimension(:)   :: seed_point

            !> The directions of the chords
            double precision, intent(in), dimension(:,:) :: nhats

            ! ------- Outputs -------
            !> The newly generated point
            double precision,    dimension(size(seed_point))     :: baby_point


        end function samp
    end interface

    interface
        !> Interface to an evidence calculator
        !!
        !! The evidence calculator recieves the relevent information, namely 
        !! * the loglikelihood of the newly created point ( new_loglikelihood )
        !! * the loglikelihood of the dying point  ( old_loglikelihood )
        !! * number of iterations/dead points ( ndead )
        !!
        !! It ouputs 
        !! * a length 2 vector ( evidence_vec ) with the [evidence, evidence error] in the value of the function
        !! * whether more samples are needed in the logical variable more_samples_needed
        !!
        subroutine ev(settings,new_loglikelihood,old_loglikelihood,ndead,more_samples_needed,evidence_vec)

            import :: program_settings

            implicit none

            ! ------- Inputs ------- 
            !> program settings (mostly useful to pass on the number of live points)
            class(program_settings), intent(in) :: settings
            
            !> loglikelihood of the newest created point
            double precision,       intent(in) :: new_loglikelihood

            !> loglikelihood of the most recently dead point
            double precision,       intent(in) :: old_loglikelihood

            !> number of dead points/ number of iterations
            integer,                intent(in) :: ndead

            ! vector containing [evidence, evidence error]
            double precision, dimension(6) :: evidence_vec

            ! ------- Outputs ------- 
            !> Whether we have obtained enough samples for an accurate evidence
            logical,intent(out) :: more_samples_needed


        end subroutine ev
    end interface


    interface
        subroutine dir(settings,live_data,nhats)
            import :: program_settings
            implicit none

            ! ------- Inputs -------
            !> program settings (mostly useful to pass on the number of live points)
            class(program_settings), intent(in) :: settings

            !> The live points
            double precision, intent(in), dimension(:,:) :: live_data

            !> The set of nhats to be generated
            double precision, intent(out) , dimension(:,:) :: nhats

        end subroutine dir
    end interface


    contains



    subroutine allocate_indices(settings)
        implicit none
        type(program_settings), intent(inout) :: settings


        ! Hypercube parameter indices
        settings%h0=1
        settings%h1=settings%h0+settings%nDims-1

        ! Physical parameter indices
        settings%p0=settings%h1+1
        settings%p1=settings%p0+settings%nDims-1 

        ! Derived parameter indices
        settings%d0=settings%p1+1
        settings%d1=settings%d0+settings%nDerived-1  

        ! Algorithm indices
        settings%nlike=settings%d1+1
        settings%last_chord=settings%nlike+1
#ifdef MPI
        settings%daughter=settings%last_chord+1
        ! Loglikelihood indices
        settings%l0=settings%daughter+1
#else
        settings%l0=settings%last_chord+1
#endif

        settings%l1=settings%l0+1

        ! Total number of parameters
        settings%nTotal = settings%l1

        ! grades
        if(.not. allocated(settings%grade)) allocate(settings%grade(settings%nDims))

    end subroutine allocate_indices


end module settings_module 
