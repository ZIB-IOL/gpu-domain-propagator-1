#include "../include/interface.h"
#include "propagators/GPU_propagator.cuh"
#include "propagators/sequential_propagator.h"
#include "GPU_interface.cuh"
#include "propagators/OMP_propagator.h"


void propagateConstraintsFullGPUdouble(
    const int n_cons,
    const int n_vars,
    const int nnz,
    int* csr_col_indices,
    int* csr_row_ptrs,
    double* csr_vals,
    double* lhss,
    double* rhss,
    double* lbs,
    double* ubs,
    int* vartypes
  )
  {
        if (n_cons == 0 || n_vars == 0 || nnz == 0)
        {
            printf("propagation of 0 size problem. Nothing to propagate.\n");
            return;
        }

        propagateConstraintsFullGPU<double>
        (
            n_cons,
            n_vars,
            nnz,
            csr_col_indices,
            csr_row_ptrs,
            csr_vals,
            lhss,
            rhss,
            lbs,
            ubs,
            vartypes
        );
  }

void propagateConstraintsGPUAtomicDouble(
   const int n_cons,
   const int n_vars,
   const int nnz,
   int* csr_col_indices,
   int* csr_row_ptrs,
   double* csr_vals,
   double* lhss,
   double* rhss,
   double* lbs,
   double* ubs,
   int* vartypes
)
{
   if (n_cons == 0 || n_vars == 0 || nnz == 0)
   {
      printf("propagation of 0 size problem. Nothing to propagate.\n");
      return;
   }

   propagateConstraintsGPUAtomic<double>
           (
                   n_cons,
                   n_vars,
                   nnz,
                   csr_col_indices,
                   csr_row_ptrs,
                   csr_vals,
                   lhss,
                   rhss,
                   lbs,
                   ubs,
                   vartypes
           );

}

void propagateConstraintsSequentialDouble
  (
      const int n_cons,
      const int n_vars,
      const int nnz,
      const int* col_indices,
      const int* row_indices,
      const double* vals,
      const double* lhss,
      const double* rhss,
      double* lbs,
      double* ubs,
      const int* vartypes
  )
{
    if (n_cons == 0 || n_vars == 0 || nnz == 0)
    {
        printf("propagation of 0 size problem. Nothing to propagate.\n");
        return;
    }

    // need csc format of A. Convert on GPU
    GPUInterface gpu = GPUInterface();
    int* d_col_indices = gpu.initArrayGPU<int>   (col_indices, nnz);
    int* d_row_ptrs    = gpu.initArrayGPU<int>   (row_indices, n_cons + 1);
    double* d_vals     = gpu.initArrayGPU<double>(vals       , nnz);

    double* csc_vals     = (double*)malloc(nnz * sizeof(double));
    int* csc_row_indices = (int*)malloc(nnz * sizeof(int));
    int* csc_col_ptrs    = (int*)malloc((n_vars+1) * sizeof(int));

    csr_to_csc(gpu, n_cons, n_vars, nnz, d_col_indices, d_row_ptrs, csc_col_ptrs, csc_row_indices, csc_vals, d_vals);

    sequentialPropagate<double>
    (
        n_cons,
        n_vars,
        col_indices,
        row_indices,
        csc_col_ptrs,
        csc_row_indices,
        vals,
        lhss,
        rhss,
        lbs,
        ubs,
        vartypes
    );

    free( csc_vals );
    free( csc_col_ptrs );
    free( csc_row_indices );
}

void propagateConstraintsFullOMPDouble
(
   const int n_cons,
   const int n_vars,
   const int nnz,
   const int* col_indices,
   const int* row_indices,
   const double* vals,
   const double* lhss,
   const double* rhss,
   double* lbs,
   double* ubs,
   const int* vartypes
)
{
   if (n_cons == 0 || n_vars == 0 || nnz == 0)
   {
      printf("propagation of 0 size problem. Nothing to propagate.\n");
      return;
   }

   // Need csc fomrat of A. Convert on GPU
   GPUInterface gpu = GPUInterface();
   int* d_col_indices = gpu.initArrayGPU<int>   (col_indices, nnz);
   int* d_row_ptrs    = gpu.initArrayGPU<int>   (row_indices, n_cons + 1);
   double* d_vals     = gpu.initArrayGPU<double>(vals       , nnz);

   double* csc_vals     = (double*)malloc(nnz * sizeof(double));
   int* csc_row_indices = (int*)malloc(nnz * sizeof(int));
   int* csc_col_ptrs    = (int*)malloc((n_vars+1) * sizeof(int));

   csr_to_csc(gpu, n_cons, n_vars, nnz, d_col_indices, d_row_ptrs, csc_col_ptrs, csc_row_indices, csc_vals, d_vals);

   fullOMPPropagate<double>
           (
                   n_cons,
                   n_vars,
                   col_indices,
                   row_indices,
                   csc_col_ptrs,
                   csc_row_indices,
                   vals,
                   lhss,
                   rhss,
                   lbs,
                   ubs,
                   vartypes
           );

   free( csc_vals );
   free( csc_col_ptrs );
   free( csc_row_indices );
}

void propagateConstraintsSequentialDisjointDouble
(
    const int n_cons,
    const int n_vars,
    const int nnz,
    const int* col_indices,
    const int* row_indices,
    const double* vals,
    const double* lhss,
    const double* rhss,
    double* lbs,
    double* ubs,
    const int* vartypes
)
{
  if (n_cons == 0 || n_vars == 0 || nnz == 0)
  {
      printf("propagation of 0 size problem. Nothing to propagate.\n");
      return;
  }
  // todo csc conversion
  GPUInterface gpu = GPUInterface();
  int* d_col_indices = gpu.initArrayGPU<int>   (col_indices, nnz);
  int* d_row_ptrs    = gpu.initArrayGPU<int>   (row_indices, n_cons + 1);
  double* d_vals     = gpu.initArrayGPU<double>(vals       , nnz);

  double* csc_vals     = (double*)malloc(nnz * sizeof(double));
  int* csc_row_indices = (int*)malloc(nnz * sizeof(int));
  int* csc_col_ptrs    = (int*)malloc((n_vars+1) * sizeof(int));

  csr_to_csc(gpu, n_cons, n_vars, nnz, d_col_indices, d_row_ptrs, csc_col_ptrs, csc_row_indices, csc_vals, d_vals);

  sequentialPropagateDisjoint<double>
  (
      n_cons,
      n_vars,
      col_indices,
      row_indices,
      csc_col_ptrs,
      csc_row_indices,
      vals,
      lhss,
      rhss,
      lbs,
      ubs,
      vartypes
  );

  free( csc_vals );
  free( csc_col_ptrs );
  free( csc_row_indices );
}