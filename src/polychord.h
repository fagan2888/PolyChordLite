#ifndef __INTEL_COMPILER 			// if the MultiNest library was compiled with ifort
       #define POLYCHORD __interfaces_module_MOD_run_polychord_no_prior_no_setup 
#else
       #error Do not know how to link to Fortran libraries, check symbol table for your platform (nm libnest3.a | grep nestrun) & edit example_eggbox_C++/eggbox.cc
#endif

#ifndef MULTINEST_H
#define MULTINEST_H


/***************************************** C Interface to MultiNest **************************************************/


extern void POLYCHORD( double (*c_loglikelihood_ptr)(double[],int&,double[],int&) , int nlive, int num_repeats, bool do_clustering , int feedback , double precision_criterion , int max_ndead , double boost_posterior , bool posteriors , bool equals , bool cluster_posteriors , bool write_resume , bool write_paramnames , bool read_resume , bool write_stats , bool write_live , bool write_dead , int update_files , int nDims , int nDerived );

void run( double (*c_loglikelihood_ptr)(double[],int&,double[],int&) , int nlive, int num_repeats, bool do_clustering , int feedback , double precision_criterion , int max_ndead , double boost_posterior , bool posteriors , bool equals , bool cluster_posteriors , bool write_resume , bool write_paramnames , bool read_resume , bool write_stats , bool write_live , bool write_dead , int update_files , int nDims , int nDerived )
{

    POLYCHORD( c_loglikelihood_ptr, nlive, num_repeats, do_clustering , feedback , precision_criterion , max_ndead , boost_posterior , posteriors , equals , cluster_posteriors , write_resume , write_paramnames , read_resume , write_stats , write_live , write_dead , update_files , nDims , nDerived );
}

/***********************************************************************************************************************/

#endif // MULTINEST_H
