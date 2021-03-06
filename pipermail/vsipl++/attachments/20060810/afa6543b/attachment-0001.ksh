Index: scripts/config
===================================================================
--- scripts/config	(revision 146557)
+++ scripts/config	(working copy)
@@ -70,8 +70,8 @@
 # Configure flags
 ########################################################################
 
-common_32 = ['--enable-profile-timer=pentiumtsc']
-common_64 = ['--enable-profile-timer=x86_64_tsc']
+common_32 = ['--enable-timer=pentiumtsc']
+common_64 = ['--enable-timer=x86_64_tsc']
 
 cross = ['--host=i686-pc-linux-gnu',
          '--build=x86_64-unknown-linux-gnu',
@@ -344,7 +344,7 @@
 # SPARC/Solaris Configure flags
 ########################################################################
 
-common_sparc = ['--enable-profile-timer=posix']
+common_sparc = ['--enable-timer=posix']
 
 builtin_fft_sparc    = ['--enable-fft=builtin', '--disable-fft-long-double']
 
Index: src/vsip/impl/signal-iir.hpp
===================================================================
--- src/vsip/impl/signal-iir.hpp	(revision 146557)
+++ src/vsip/impl/signal-iir.hpp	(working copy)
@@ -17,6 +17,7 @@
 #include <vsip/impl/signal-types.hpp>
 
 
+#define PROFILING_ENABLED   (VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILER_SIGNAL)
 
 /***********************************************************************
   Declarations
@@ -195,7 +196,9 @@
   Vector<T, Block1>       out)
   VSIP_NOTHROW
 {
+#if PROFILING_ENABLED
   impl::profile::Scope_profile_event scope_event(this->event_);
+#endif
   index_type const A1 = 0;
   index_type const A2 = 1;
 
@@ -255,4 +258,6 @@
 
 } // namespace vsip
 
+#undef PROFILING_ENABLED
+
 #endif // VSIP_IMPL_SIGNAL_IIR_HPP
Index: src/vsip/impl/signal-conv.hpp
===================================================================
--- src/vsip/impl/signal-conv.hpp	(revision 146557)
+++ src/vsip/impl/signal-conv.hpp	(working copy)
@@ -34,6 +34,7 @@
 #endif
 
 
+#define PROFILING_ENABLED   (VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILER_SIGNAL)
 
 /***********************************************************************
   Declarations
@@ -117,7 +118,9 @@
     impl_View<V2, Block2, T, dim>       out)
     VSIP_NOTHROW
   {
+#if PROFILING_ENABLED
     impl::profile::Scope_profile_event scope_event(this->event_);
+#endif
     for (dimension_type d=0; d<dim; ++d)
       assert(in.size(d) == this->input_size()[d].size());
 
@@ -137,8 +140,9 @@
     Vector<T, Block2>       out)
     VSIP_NOTHROW
   {
+#if PROFILING_ENABLED
     impl::profile::Scope_profile_event scope_event(this->event_);
-
+#endif
     for (dimension_type d=0; d<dim; ++d)
       assert(in.size(d) == this->input_size()[d].size());
 
@@ -158,8 +162,9 @@
     Matrix<T, Block2>       out)
     VSIP_NOTHROW
   {
+#if PROFILING_ENABLED
     impl::profile::Scope_profile_event scope_event(this->event_);
-
+#endif
     for (dimension_type d=0; d<dim; ++d)
       assert(in.size(d) == this->input_size()[d].size());
 
@@ -174,10 +179,13 @@
 
   float impl_performance(char* what) const
   {
+#if PROFILING_ENABLED
     if      (!strcmp(what, "mops"))     return this->event_.mflops();
     else if (!strcmp(what, "time"))     return this->event_.total();
     else if (!strcmp(what, "count"))    return this->event_.count();
-    else return this->base_type::impl_performance(what);
+    else
+#endif
+      return this->base_type::impl_performance(what);
   }
 
   // Member data.
@@ -199,4 +207,6 @@
 
 } // namespace vsip
 
+#undef PROFILING_ENABLED
+
 #endif // VSIP_IMPL_SIGNAL_CONV_HPP
Index: src/vsip/impl/signal-corr.hpp
===================================================================
--- src/vsip/impl/signal-corr.hpp	(revision 146557)
+++ src/vsip/impl/signal-corr.hpp	(working copy)
@@ -24,6 +24,7 @@
 #include <vsip/impl/signal-corr-opt.hpp>
 
 
+#define PROFILING_ENABLED   (VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILER_SIGNAL)
 
 /***********************************************************************
   Declarations
@@ -102,8 +103,9 @@
     Vector<T, Block2>       out)
     VSIP_NOTHROW
   {
+#if PROFILING_ENABLED
     impl::profile::Scope_profile_event scope_event(this->event_);
-
+#endif
     for (dimension_type d=0; d<dim; ++d)
     {
       assert(ref.size(d) == this->reference_size()[d].size());
@@ -127,8 +129,9 @@
     Matrix<T, Block2>       out)
     VSIP_NOTHROW
   {
+#if PROFILING_ENABLED
     impl::profile::Scope_profile_event scope_event(this->event_);
-
+#endif
     for (dimension_type d=0; d<dim; ++d)
     {
       assert(ref.size(d) == this->reference_size()[d].size());
@@ -167,4 +170,6 @@
 
 } // namespace vsip
 
+#undef PROFILING_ENABLED
+
 #endif // VSIP_IMPL_SIGNAL_CORR_HPP
Index: src/vsip/impl/signal-conv-ipp.hpp
===================================================================
--- src/vsip/impl/signal-conv-ipp.hpp	(revision 146557)
+++ src/vsip/impl/signal-conv-ipp.hpp	(working copy)
@@ -24,6 +24,7 @@
 #include <vsip/impl/ipp.hpp>
 
 
+#define PROFILING_ENABLED   (VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILER_SIGNAL)
 
 /***********************************************************************
   Declarations
@@ -102,6 +103,7 @@
 
   float impl_performance(char* what) const
   {
+#if PROFILING_ENABLED
     if      (!strcmp(what, "in_ext_cost"))
     {
       return pm_in_ext_cost_;
@@ -114,6 +116,7 @@
     {
       return pm_non_opt_calls_;
     }
+#endif
     return 0.f;
   }
 
@@ -262,8 +265,10 @@
   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
 
+#if PROFILING_ENABLED
   pm_in_ext_cost_  += in_ext.cost();
   pm_out_ext_cost_ += out_ext.cost();
+#endif
 
   T* pin    = in_ext.data();
   T* pout   = out_ext.data();
@@ -279,7 +284,9 @@
     }
     else
     {
+#if PROFILING_ENABLED
       pm_non_opt_calls_++;
+#endif
       conv_full<T>(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
     }
   }
@@ -293,7 +300,9 @@
     }
     else
     {
+#if PROFILING_ENABLED
       pm_non_opt_calls_++;
+#endif
       conv_same<T>(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
     }
   }
@@ -307,7 +316,9 @@
     }
     else
     {
+#if PROFILING_ENABLED
       pm_non_opt_calls_++;
+#endif
       conv_min<T>(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
     }
   }
@@ -349,8 +360,10 @@
   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
 
+#if PROFILING_ENABLED
   pm_in_ext_cost_  += in_ext.cost();
   pm_out_ext_cost_ += out_ext.cost();
+#endif
 
   T* pin    = in_ext.data();
   T* pout   = out_ext.data();
@@ -440,4 +453,6 @@
 
 } // namespace vsip
 
+#undef PROFILING_ENABLED
+
 #endif // VSIP_IMPL_SIGNAL_CONV_IPP_HPP
Index: src/vsip/impl/signal-conv-ext.hpp
===================================================================
--- src/vsip/impl/signal-conv-ext.hpp	(revision 146557)
+++ src/vsip/impl/signal-conv-ext.hpp	(working copy)
@@ -24,6 +24,7 @@
 #include <vsip/impl/extdata-local.hpp>
 
 
+#define PROFILING_ENABLED   (VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILER_SIGNAL)
 
 /***********************************************************************
   Declarations
@@ -85,6 +86,7 @@
 
   float impl_performance(char* what) const
   {
+#if PROFILING_ENABLED
     if      (!strcmp(what, "in_ext_cost"))
     {
       return pm_in_ext_cost_;
@@ -97,6 +99,7 @@
     {
       return pm_non_opt_calls_;
     }
+#endif
     return 0.f;
   }
 
@@ -256,8 +259,10 @@
   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
 
+#if PROFILING_ENABLED
   pm_in_ext_cost_  += in_ext.cost();
   pm_out_ext_cost_ += out_ext.cost();
+#endif
 
   T* pin    = in_ext.data();
   T* pout   = out_ext.data();
@@ -328,8 +333,10 @@
   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
 
+#if PROFILING_ENABLED
   pm_in_ext_cost_  += in_ext.cost();
   pm_out_ext_cost_ += out_ext.cost();
+#endif
 
   T* pin    = in_ext.data();
   T* pout   = out_ext.data();
@@ -368,4 +375,6 @@
 
 } // namespace vsip
 
+#undef PROFILING_ENABLED
+
 #endif // VSIP_IMPL_SIGNAL_CONV_EXT_HPP
Index: src/vsip/impl/signal-corr-ext.hpp
===================================================================
--- src/vsip/impl/signal-corr-ext.hpp	(revision 146557)
+++ src/vsip/impl/signal-corr-ext.hpp	(working copy)
@@ -25,6 +25,7 @@
 #include <vsip/impl/extdata-local.hpp>
 
 
+#define PROFILING_ENABLED   (VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILER_SIGNAL)
 
 /***********************************************************************
   Declarations
@@ -79,6 +80,7 @@
 
   float impl_performance(char* what) const
   {
+#if PROFILING_ENABLED
     if      (!strcmp(what, "in_ext_cost"))
     {
       return pm_in_ext_cost_;
@@ -87,6 +89,7 @@
     {
       return pm_out_ext_cost_;
     }
+#endif
     return 0.f;
   }
 
@@ -363,4 +366,6 @@
 
 } // namespace vsip
 
+#undef PROFILING_ENABLED
+
 #endif // VSIP_IMPL_SIGNAL_CORR_EXT_HPP
Index: src/vsip/impl/fft.hpp
===================================================================
--- src/vsip/impl/fft.hpp	(revision 146557)
+++ src/vsip/impl/fft.hpp	(working copy)
@@ -35,6 +35,9 @@
 #include <vsip/impl/fft/no_fft.hpp>
 #endif
 
+
+#define PROFILING_ENABLED   (VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILER_SIGNAL)
+
 namespace vsip
 {
 
@@ -107,14 +110,13 @@
   
   float impl_performance(char* what) const
   {
-    if (!strcmp(what, "mops"))
-    {
-      return this->event_.mops();
-    }
-    else if (!strcmp(what, "time"))
-    {
-      return this->event_.total();
-    }
+#if PROFILING_ENABLED
+    if      (!strcmp(what, "mops"))     return this->event_.mops();
+    else if (!strcmp(what, "time"))     return this->event_.total();
+#else
+    if (what);   // Avoid warning.
+#endif
+
     return 0.f;
   }
 
@@ -168,7 +170,9 @@
   operator()(ViewT in)
     VSIP_THROW((std::bad_alloc))
   {
+#if PROFILING_ENABLED
     impl::profile::Scope_profile_event scope_event(this->event_);
+#endif
     typedef fft::result<O, typename ViewT::block_type> traits;
     typename traits::view_type out(traits::create(this->output_size(),
 						  in.block().map()));
@@ -214,7 +218,9 @@
   operator()(View0<I,Block0> in, View1<O,Block1> out)
     VSIP_NOTHROW
   {
+#if PROFILING_ENABLED
     impl::profile::Scope_profile_event scope_event(this->event_);
+#endif
     VSIP_IMPL_STATIC_ASSERT((View0<I,Block0>::dim == View1<O,Block1>::dim));
     workspace_.by_reference(this->backend_.get(), in, out);
     return out;
@@ -224,7 +230,9 @@
   View<I,BlockT>
   operator()(View<I,BlockT> inout) VSIP_NOTHROW
   {
+#if PROFILING_ENABLED
     impl::profile::Scope_profile_event scope_event(this->event_);
+#endif
     workspace_.in_place(this->backend_.get(), inout);
     return inout;
   }
@@ -271,7 +279,9 @@
   operator()(const_Matrix<I,BlockT> in)
     VSIP_THROW((std::bad_alloc))
   {
+#if PROFILING_ENABLED
     impl::profile::Scope_profile_event scope_event(this->event_);
+#endif
     typedef fft::result<O,BlockT> traits;
     typename traits::view_type out(traits::create(this->output_size(),
 						  in.block().map()));
@@ -317,7 +327,9 @@
   operator()(const_Matrix<I,Block0> in, Matrix<O,Block1> out)
     VSIP_NOTHROW
   {
+#if PROFILING_ENABLED
     impl::profile::Scope_profile_event scope_event(this->event_);
+#endif
     assert(extent(in)  == extent(this->input_size()));
     assert(extent(out) == extent(this->output_size()));
     if (Is_global_map<typename Block0::map_type>::value ||
@@ -339,7 +351,9 @@
   Matrix<O,BlockT>
   operator()(Matrix<O,BlockT> inout) VSIP_NOTHROW
   {
+#if PROFILING_ENABLED
     impl::profile::Scope_profile_event scope_event(this->event_);
+#endif
     assert(extent(inout) == extent(this->input_size()));
     if (Is_global_map<typename BlockT::map_type>::value &&
 	inout.block().map().num_subblocks(A) != 1)
@@ -400,4 +414,6 @@
 
 } // namespace vsip
 
+#undef PROFILING_ENABLED
+
 #endif // VSIP_IMPL_FFT_HPP
Index: src/vsip/impl/signal-corr-opt.hpp
===================================================================
--- src/vsip/impl/signal-corr-opt.hpp	(revision 146557)
+++ src/vsip/impl/signal-corr-opt.hpp	(working copy)
@@ -28,6 +28,7 @@
 #include <vsip/impl/signal-corr-common.hpp>
 
 
+#define PROFILING_ENABLED   (VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILER_SIGNAL)
 
 /***********************************************************************
   Declarations
@@ -111,6 +112,7 @@
 
   float impl_performance(char* what) const
   {
+#if PROFILING_ENABLED
     if      (!strcmp(what, "in_ext_cost"))
     {
       return pm_in_ext_cost_;
@@ -123,6 +125,7 @@
     {
       return pm_non_opt_calls_;
     }
+#endif
     return 0.f;
   }
 
@@ -394,4 +397,6 @@
 
 } // namespace vsip
 
+#undef PROFILING_ENABLED
+
 #endif // VSIP_IMPL_SIGNAL_CORR_OPT_HPP
Index: src/vsip/impl/signal-fir.hpp
===================================================================
--- src/vsip/impl/signal-fir.hpp	(revision 146557)
+++ src/vsip/impl/signal-fir.hpp	(working copy)
@@ -20,6 +20,9 @@
 #include <vsip/impl/profile.hpp>
 #include <vsip/impl/ops_info.hpp>
 
+
+#define PROFILING_ENABLED   (VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILER_SIGNAL)
+
 namespace vsip
 {
 
@@ -227,7 +230,9 @@
     vsip::Vector<T, Block1>  out)
       VSIP_NOTHROW
   {
+#if PROFILING_ENABLED
     impl::profile::Scope_profile_event scope_event(this->event_);
+#endif
     assert(data.size() == this->input_size_);
     assert(out.size() == this->output_size_);
 
@@ -316,9 +321,11 @@
 
   float impl_performance(char* what) const  VSIP_NOTHROW
   {
+#if PROFILING_ENABLED
     if      (!strcmp(what, "mops"))     return this->event_.mflops();
     else if (!strcmp(what, "time"))     return this->event_.total();
     else if (!strcmp(what, "count"))    return this->event_.count();
+#endif
     return 0.f;
   }
 
@@ -346,5 +353,7 @@
 
 } // namespace vsip
 
+#undef PROFILING_ENABLED
+
 #endif // VSIP_IMPL_SIGNAL_FIR_HPP
 
Index: src/vsip/impl/signal-conv-sal.hpp
===================================================================
--- src/vsip/impl/signal-conv-sal.hpp	(revision 146557)
+++ src/vsip/impl/signal-conv-sal.hpp	(working copy)
@@ -24,6 +24,7 @@
 #include <vsip/impl/sal.hpp>
 
 
+#define PROFILING_ENABLED   (VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILER_SIGNAL)
 
 /***********************************************************************
   Declarations
@@ -116,6 +117,7 @@
 
   float impl_performance(char* what) const
   {
+#if PROFILING_ENABLED
     if      (!strcmp(what, "in_ext_cost"))
     {
       return pm_in_ext_cost_;
@@ -128,6 +130,7 @@
     {
       return pm_non_opt_calls_;
     }
+#endif
     return 0.f;
   }
 
@@ -270,8 +273,10 @@
   in_ext_type  in_ext (in.block(),  vsip::impl::SYNC_IN,  in_buffer_);
   out_ext_type out_ext(out.block(), vsip::impl::SYNC_OUT, out_buffer_);
 
+#if PROFILING_ENABLED
   pm_in_ext_cost_  += in_ext.cost();
   pm_out_ext_cost_ += out_ext.cost();
+#endif
 
   ptr_type pin    = in_ext.data();
   ptr_type pout   = out_ext.data();
@@ -348,17 +353,23 @@
   {
     if (Supp == support_full)
     {
+#if PROFILING_ENABLED
       pm_non_opt_calls_++;
+#endif
       conv_full(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
     }
     else if (Supp == support_same)
     {
+#if PROFILING_ENABLED
       pm_non_opt_calls_++;
+#endif
       conv_same(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
     }
     else // (Supp == support_min)
     {
+#if PROFILING_ENABLED
       pm_non_opt_calls_++;
+#endif
       conv_min(pcoeff_, M, pin, N, s_in, pout, P, s_out, decimation_);
     }
   }
@@ -392,4 +403,6 @@
 
 } // namespace vsip
 
+#undef PROFILING_ENABLED
+
 #endif // VSIP_IMPL_SIGNAL_CONV_EXT_HPP
Index: src/vsip/impl/profile.hpp
===================================================================
--- src/vsip/impl/profile.hpp	(revision 146557)
+++ src/vsip/impl/profile.hpp	(working copy)
@@ -29,6 +29,7 @@
 #  include <time.h>
 #endif
 
+#define PROFILING_ENABLED   (VSIP_IMPL_PROFILER)
 
 
 /***********************************************************************
@@ -358,13 +359,23 @@
 {
 public:
   Profile(char *filename, profiler_mode mode = pm_accum)
-    : filename_(filename)
-  { prof->set_mode( mode ); }
+    : filename_(filename), mode_(mode)
+  { 
+#if PROFILING_ENABLED
+    prof->set_mode( mode ); 
+#endif
+  }
 
-  ~Profile() { prof->dump( this->filename_ ); }
+  ~Profile() 
+  { 
+#if PROFILING_ENABLED
+    prof->dump( this->filename_ ); 
+#endif
+  }
 
 private:
   char* const filename_;
+  profiler_mode mode_;
 };
 
 class Profile_event
@@ -461,4 +472,6 @@
 } // namespace vsip::impl
 } // namespace vsip
 
+#undef PROFILING_ENABLED
+
 #endif // VSIP_IMPL_PROFILE_HPP
Index: src/vsip/impl/matvec.hpp
===================================================================
--- src/vsip/impl/matvec.hpp	(revision 146557)
+++ src/vsip/impl/matvec.hpp	(working copy)
@@ -27,6 +27,8 @@
 #include <vsip/impl/ops_info.hpp>
 
 
+#define PROFILING_ENABLED   (VSIP_IMPL_PROFILER & VSIP_IMPL_PROFILER_MATVEC)
+
 namespace vsip
 {
 
@@ -573,11 +575,12 @@
   const_Vector<T0, Block0> v,
   const_Vector<T1, Block1> w) VSIP_NOTHROW
 {
+#if PROFILING_ENABLED
   typedef typename Promotion<T0, T1>::type result_type;
   impl::profile::Scope_event event( 
     impl::matvec::Description<result_type>::tag("dot", impl::extent(v)),
     impl::matvec::Op_count_dot<result_type>::value(impl::extent(v)) );
-
+#endif
   return impl::impl_dot(v, w);
 }
 
@@ -590,11 +593,12 @@
   const_Vector<complex<T0>, Block0> v,
   const_Vector<complex<T1>, Block1> w) VSIP_NOTHROW
 {
+#if PROFILING_ENABLED
   typedef typename Promotion<T0, T1>::type result_type;
   impl::profile::Scope_event event( 
     impl::matvec::Description<result_type>::tag("cvjdot", impl::extent(v)),
     impl::matvec::Op_count_cvjdot<result_type>::value(impl::extent(v)) );
-
+#endif
   return impl::impl_dot(v, conj(w));
 }
 
@@ -607,9 +611,10 @@
 typename const_Matrix<T, Block>::transpose_type
 trans(const_Matrix<T, Block> m) VSIP_NOTHROW
 {
+#if PROFILING_ENABLED
   impl::profile::Scope_event event( 
     impl::matvec::Description<T>::tag("trans", impl::extent(m)) );
-
+#endif
   return m.transpose();
 }
 
@@ -620,10 +625,11 @@
   Block>::transpose_type>::result_type
 herm(const_Matrix<complex<T>, Block> m) VSIP_NOTHROW
 {
+#if PROFILING_ENABLED
   impl::profile::Scope_event event( 
     impl::matvec::Description<complex<T> >::tag("herm", impl::extent(m)),
     impl::matvec::Op_count_herm<complex<T> >::value(impl::extent(m)) );
-
+#endif
   typedef typename const_Matrix<complex<T>, Block>::transpose_type 
     transpose_type;
   typedef impl::Unary_func_view<impl::conj_functor, transpose_type> 
@@ -649,11 +655,13 @@
   dimension_type const dim = impl::Dim_of_view<const_View>::dim;
   typedef typename Promotion<T0, typename Promotion<T1, T2>::type
     >::type result_type;
+#if PROFILING_ENABLED
   impl::profile::Scope_event event( 
     impl::matvec::Description<result_type>::tag("kron", impl::extent(v), 
       impl::extent(w)),
     impl::matvec::Op_count_kron<dim, result_type>::value(impl::extent(v), 
       impl::extent(w)) );
+#endif
 
   return impl::impl_kron( alpha, v, w );
 }
@@ -672,12 +680,13 @@
     VSIP_NOTHROW
 {
   typedef typename Promotion<T1, T2>::type return_type;
+#if PROFILING_ENABLED
   impl::profile::Scope_event event( 
     impl::matvec::Description<return_type>::tag("outer", impl::extent(v), 
       impl::extent(w)),
     impl::matvec::Op_count_outer<return_type>::value(impl::extent(v), 
       impl::extent(w)) );
-
+#endif
   Matrix<return_type> r(v.size(), w.size(), return_type());
 
   impl::outer(alpha, v, w, r);
@@ -708,12 +717,13 @@
     Matrix<T4, Block4> C)
      VSIP_NOTHROW
 {
+#if PROFILING_ENABLED
   impl::profile::Scope_event event( 
     impl::matvec::Description<T4>::tag("gemp", impl::extent(A), 
       impl::extent(B)),
     impl::matvec::Op_count_gemp<T4>::value(impl::extent(A), 
       impl::extent(B), OpA, OpB) );
-
+#endif
   // equivalent to C = alpha * OpA(A) * OpB(B) + beta * C
   impl::gemp( alpha, 
               impl::apply_mat_op<OpA>(A), 
@@ -739,10 +749,11 @@
   Matrix<T4, Block4> C) 
     VSIP_NOTHROW
 {
+#if PROFILING_ENABLED
   impl::profile::Scope_event event( 
     impl::matvec::Description<T4>::tag("gems", impl::extent(A)),
     impl::matvec::Op_count_gems<T4>::value(impl::extent(A), OpA) );
-
+#endif
   impl::gems( alpha,
               impl::apply_mat_op<OpA>(A),
               beta,
@@ -766,10 +777,12 @@
   View<T1, Block1> w) 
     VSIP_NOTHROW
 {
+#if PROFILING_ENABLED
   dimension_type const dim = impl::Dim_of_view<const_View>::dim;
   impl::profile::Scope_event event( 
     impl::matvec::Description<T0>::tag("cumsum", impl::extent(v)),
     impl::matvec::Op_count_cumsum<dim, T0>::value(impl::extent(v)) );
+#endif
 
   impl::cumsum<d>(v, w);
 }
@@ -789,13 +802,16 @@
   Vector<complex<T3>, Block1> w)
     VSIP_NOTHROW
 {
+#if PROFILING_ENABLED
   impl::profile::Scope_event event( 
     impl::matvec::Description<T0>::tag("modulate", impl::extent(v)),
     impl::matvec::Op_count_modulate<T0>::value(impl::extent(v)) );
-
+#endif
   return impl::modulate(v, nu, phi, w);
 }
 
 } // namespace vsip
 
-#endif
+#undef PROFILING_ENABLED
+
+#endif // VSIP_IMPL_MATVEC_HPP
Index: configure.ac
===================================================================
--- configure.ac	(revision 146557)
+++ configure.ac	(working copy)
@@ -258,16 +258,22 @@
   [with_alignment=probe])
 
 
-AC_ARG_ENABLE([profile_timer],
-  AS_HELP_STRING([--enable-profile-timer=type],
+AC_ARG_ENABLE([timer],
+  AS_HELP_STRING([--enable-timer=type],
                  [set profile timer type.  Choices include none, posix, realtime, pentiumtsc, x86_64_tsc]),,
-  [enable_profile_timer=none])
+  [enable_timer=none])
 
 AC_ARG_ENABLE([cpu_mhz],
   AS_HELP_STRING([--enable-cpu-mhz=speed],
                  [set CPU speed in MHz.  Only necessary for TSC and if /proc/cpuinfo does not exist or is wrong]),,
   [enable_cpu_mhz=none])
 
+AC_ARG_ENABLE([profiler],
+  AS_HELP_STRING([--enable-profiler=type],
+                 [Specify list of areas to profile.  Choices include none, all
+		  or a combination of: signal, matvec, fns and user.  Default is none.]),,
+  [enable_profiler=none])
+
 AC_ARG_ENABLE([simd_loop_fusion],
   AS_HELP_STRING([--enable-simd-loop-fusion],
                  [Enable SIMD loop-fusion]),,
@@ -1632,11 +1638,12 @@
 #
 # Configure profile timer
 #
-if test "$enable_profile_timer" == "none"; then
+if test "$enable_timer" == "none" \
+     -o "$enable_timer" == "no"; then
   AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILE_TIMER, 0,
     [Profile timer (1: Posix, 2: Posix realtime, 3: ia32 TSC, 4: x86_64 TSC).])
 
-elif test "$enable_profile_timer" == "posix"; then
+elif test "$enable_timer" == "posix"; then
   AC_MSG_CHECKING([if Posix clock() available.])
   AC_LINK_IFELSE(
     [AC_LANG_PROGRAM([[#include <time.h>]],
@@ -1648,7 +1655,7 @@
   AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILE_TIMER, 1,
     [Profile timer (1: Posix, 2: Posix realtime, 3: ia32 TSC, 4: x86_64 TSC).])
 
-elif test "$enable_profile_timer" == "realtime"; then
+elif test "$enable_timer" == "realtime"; then
   AC_MSG_CHECKING([if Posix realtime is available.])
   AC_LINK_IFELSE(
     [AC_LANG_PROGRAM([[#include <time.h>]],
@@ -1661,7 +1668,7 @@
   AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILE_TIMER, 2,
     [Profile timer (1: Posix, 2: Posix realtime, 3: ia32 TSC, 4: x86_64 TSC).])
 
-elif test "$enable_profile_timer" == "pentiumtsc"; then
+elif test "$enable_timer" == "pentiumtsc"; then
   AC_MSG_CHECKING([if Pentium ia32 TSC assembly syntax supported.])
   AC_LINK_IFELSE(
     [AC_LANG_PROGRAM([],
@@ -1673,7 +1680,7 @@
   AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILE_TIMER, 3,
     [Profile timer (1: Posix, 2: Posix realtime, 3: ia32 TSC, 4: x86_64 TSC).])
 
-elif test "$enable_profile_timer" == "x86_64_tsc"; then
+elif test "$enable_timer" == "x86_64_tsc"; then
   AC_MSG_CHECKING([if x86_64 TSC assembly syntax supported.])
   AC_LINK_IFELSE(
     [AC_LANG_PROGRAM([],
@@ -1696,6 +1703,59 @@
 
 
 #
+# Configure profiler
+#
+profiler_options=`echo "${enable_profiler}" | \
+                sed -e 's/[[ 	,]][[ 	,]]*/ /g' -e 's/,$//'`
+
+prof_opt_mask=0
+profiler_mode=""
+
+if test "$enable_profiler" != ""; then
+  for prof_opt in ${profiler_options} ; do
+    case ${prof_opt} in
+      no)      profiler_enabled="no";;
+      none)    profiler_enabled="no";;
+      signal)  let prof_opt_mask+=1;;
+      matvec)  let prof_opt_mask+=2;;
+      fns)     let prof_opt_mask+=4;;
+      user)    let prof_opt_mask+=8;;
+      all)     profiler_mode="all";;
+      yes)     profiler_mode="all";;
+      *) AC_MSG_ERROR([Unknown profiler option ${prof_opt}.]);;
+    esac
+  done
+fi
+
+if test "$profiler_enabled" == "no"; then
+   prof_opt_mask=0
+   profiler_options="disabled"
+else
+  if test "$enable_timer" == "none" \
+       -o "$enable_timer" == "no"; then
+    AC_MSG_ERROR([Enable a timer to use the profiler.])
+  fi
+  if test "$profiler_options" == "yes"; then
+     profiler_mode="all"
+  fi
+  if test "$profiler_mode" == "all"; then
+     profiler_options="signal matvec fns user"
+     let prof_opt_mask=1+2+4+8
+  fi	
+fi
+
+AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILER, $prof_opt_mask,
+  [Profiler (None, Signal Processing, Matrix-Vector Math, Functions
+   User Events, All).])
+
+AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILER_SIGNAL,  1, [Profiler event type mask.])
+AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILER_MATVEC,  2, [Profiler event type mask.])
+AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILER_FNS,     4, [Profiler event type mask.])
+AC_DEFINE_UNQUOTED(VSIP_IMPL_PROFILER_USER,    8, [Profiler event type mask.])
+
+
+
+#
 # Configure use of SIMD loop-fusion
 #
 if test "$enable_simd_loop_fusion" = "yes"; then
@@ -1836,6 +1896,7 @@
 else
   AC_MSG_RESULT([Complex storage format:                  interleaved])
 fi
+AC_MSG_RESULT([Profiling:                               ${profiler_options}])
 
 #
 # Done.
Index: doc/quickstart/quickstart.xml
===================================================================
--- doc/quickstart/quickstart.xml	(revision 146557)
+++ doc/quickstart/quickstart.xml	(working copy)
@@ -965,7 +965,7 @@
      </varlistentry>
 
      <varlistentry>
-      <term><option>--enable-profile-timer=<replaceable>timer</replaceable></option></term>
+      <term><option>--enable-timer=<replaceable>timer</replaceable></option></term>
       <listitem>
        <para>
         Use <replaceable>timer</replaceable> type of timer for
@@ -1270,7 +1270,7 @@
       </listitem>
 
       <listitem>
-       <para><option>--enable-profile-timer=realtime</option></para>
+       <para><option>--enable-timer=realtime</option></para>
        <para>
         Use the POSIX-realtime timer for profiling.
        </para>
Index: examples/mercury/mcoe-setup.sh
===================================================================
--- examples/mercury/mcoe-setup.sh	(revision 146557)
+++ examples/mercury/mcoe-setup.sh	(working copy)
@@ -142,4 +142,4 @@
 	--disable-simd-loop-fusion		\
 	$cfg_flags				\
 	--with-test-level=$testlevel		\
-	--enable-profile-timer=realtime
+	--enable-timer=realtime
