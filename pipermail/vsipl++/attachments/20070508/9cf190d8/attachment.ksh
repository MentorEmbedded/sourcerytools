Index: src/vsip/opt/fftw3/fft.cpp
===================================================================
--- src/vsip/opt/fftw3/fft.cpp	(revision 165174)
+++ src/vsip/opt/fftw3/fft.cpp	(working copy)
@@ -19,6 +19,11 @@
 #include <vsip/support.hpp>
 #include <fftw3.h>
 
+// We need to include this create_plan.hpp header file because fft_impl.cpp
+// uses this file. We cannot include this file in fft_impl.cpp because
+// fft_impl.cpp gets included multiple times here.
+#include <vsip/opt/fftw3/create_plan.hpp>
+
 /***********************************************************************
   Declarations
 ***********************************************************************/
Index: src/vsip/opt/fftw3/fft_impl.cpp
===================================================================
--- src/vsip/opt/fftw3/fft_impl.cpp	(revision 168725)
+++ src/vsip/opt/fftw3/fft_impl.cpp	(working copy)
@@ -21,8 +21,8 @@
 #include <vsip/core/fft/util.hpp>
 #include <vsip/opt/fftw3/fft.hpp>
 #include <vsip/core/equal.hpp>
+#include <vsip/dense.hpp>
 #include <fftw3.h>
-#include <complex>
 
 /***********************************************************************
   Declarations
@@ -40,25 +40,25 @@
 {
   Fft_base(Domain<D> const& dom, int exp, int flags)
     VSIP_THROW((std::bad_alloc))
-      : in_buffer_(32, dom.size()),
-	out_buffer_(32, dom.size())
+      : in_buffer_(dom.size()),
+	out_buffer_(dom.size())
   {
     // For multi-dimensional transforms, these plans assume both
     // input and output data is dense, row-major, interleave-complex
     // format.
-
-    for (vsip::dimension_type i = 0; i < D; ++i) size_[i] = dom[i].size();
-    plan_in_place_ = FFTW(plan_dft)(D, size_,
-      reinterpret_cast<FFTW(complex)*>(in_buffer_.get()),
-      reinterpret_cast<FFTW(complex)*>(in_buffer_.get()),
-      exp, flags);
     
+    for(index_type i=0;i<D;i++) size_[i] = dom[i].size();
+    plan_in_place_ =
+      Create_plan<vsip::impl::dense_complex_type>
+        ::create<FFTW(plan), FFTW(iodim)>
+        (in_buffer_.ptr(), in_buffer_.ptr(), exp, flags, dom);
+    
     if (!plan_in_place_) VSIP_IMPL_THROW(std::bad_alloc());
 
-    plan_by_reference_ = FFTW(plan_dft)(D, size_,
-      reinterpret_cast<FFTW(complex)*>(in_buffer_.get()),
-      reinterpret_cast<FFTW(complex)*>(out_buffer_.get()),
-      exp, FFTW_PRESERVE_INPUT | flags);    
+    plan_by_reference_ = Create_plan<vsip::impl::dense_complex_type>
+      ::create<FFTW(plan), FFTW(iodim)>
+      (in_buffer_.ptr(), out_buffer_.ptr(), exp, flags, dom);
+
     if (!plan_by_reference_)
     {
       FFTW(destroy_plan)(plan_in_place_);
@@ -71,8 +71,8 @@
     if (plan_by_reference_) FFTW(destroy_plan)(plan_by_reference_);
   }
 
-  aligned_array<std::complex<SCALAR_TYPE> > in_buffer_;
-  aligned_array<std::complex<SCALAR_TYPE> > out_buffer_;
+  Cmplx_buffer<dense_complex_type, SCALAR_TYPE> in_buffer_;
+  Cmplx_buffer<dense_complex_type, SCALAR_TYPE> out_buffer_;
   FFTW(plan) plan_in_place_;
   FFTW(plan) plan_by_reference_;
   int size_[D];
@@ -84,17 +84,15 @@
   Fft_base(Domain<D> const& dom, int A, int flags)
     VSIP_THROW((std::bad_alloc))
     : in_buffer_(32, dom.size()),
-      out_buffer_(32, dom.size())
+      out_buffer_(dom.size())
   { 
     for (vsip::dimension_type i = 0; i < D; ++i) size_[i] = dom[i].size();  
     // FFTW3 assumes A == D - 1.
     // See also query_layout().
     if (A != D - 1) std::swap(size_[A], size_[D - 1]);
-    plan_by_reference_ = FFTW(plan_dft_r2c)(
-      D, size_,
-      in_buffer_.get(), reinterpret_cast<FFTW(complex)*>(out_buffer_.get()),
-      FFTW_PRESERVE_INPUT | flags);
-    
+    plan_by_reference_ = Create_plan<dense_complex_type>::
+      create<FFTW(plan), FFTW(iodim)>
+      (in_buffer_.get(), out_buffer_.ptr(), A, flags, dom);
     if (!plan_by_reference_) VSIP_IMPL_THROW(std::bad_alloc());
   }
   ~Fft_base() VSIP_NOTHROW
@@ -103,7 +101,7 @@
   }
 
   aligned_array<SCALAR_TYPE> in_buffer_;
-  aligned_array<std::complex<SCALAR_TYPE> > out_buffer_;
+  Cmplx_buffer<dense_complex_type, SCALAR_TYPE> out_buffer_;
   FFTW(plan) plan_by_reference_;
   int size_[D];
 };
@@ -113,17 +111,16 @@
 {
   Fft_base(Domain<D> const& dom, int A, int flags)
     VSIP_THROW((std::bad_alloc))
-    : in_buffer_(32, dom.size()),
+    : in_buffer_(dom.size()),
       out_buffer_(32, dom.size())
   {
     for (vsip::dimension_type i = 0; i < D; ++i) size_[i] = dom[i].size();
     // FFTW3 assumes A == D - 1.
     // See also query_layout().
     if (A != D - 1) std::swap(size_[A], size_[D - 1]);
-    plan_by_reference_ = FFTW(plan_dft_c2r)(
-      D, size_,
-      reinterpret_cast<FFTW(complex)*>(in_buffer_.get()), out_buffer_.get(),
-      flags);
+    plan_by_reference_ = Create_plan<dense_complex_type>::
+      create<FFTW(plan), FFTW(iodim)>
+      (in_buffer_.ptr(), out_buffer_.get(), A, flags, dom);
 
     if (!plan_by_reference_) VSIP_IMPL_THROW(std::bad_alloc());
   }
@@ -132,8 +129,8 @@
     if (plan_by_reference_) FFTW(destroy_plan)(plan_by_reference_);
   }
 
-  aligned_array<std::complex<SCALAR_TYPE> > in_buffer_;
-  aligned_array<SCALAR_TYPE> out_buffer_;
+  Cmplx_buffer<dense_complex_type, SCALAR_TYPE> in_buffer_;
+  aligned_array<SCALAR_TYPE>              out_buffer_;
   FFTW(plan) plan_by_reference_;
   int size_[D];
 };
@@ -156,6 +153,23 @@
     : Fft_base<1, ctype, ctype>(dom, E, convert_NoT(number))
   {}
   virtual char const* name() { return "fft-fftw3-1D-complex"; }
+  virtual void query_layout(Rt_layout<1> &rtl_inout)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>
+    rtl_inout.pack = stride_unit_dense;
+    rtl_inout.order = tuple<0, 1, 2>();
+    // make default based on library
+    rtl_inout.complex = Create_plan<dense_complex_type>::type;
+  }
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    // make default based on library
+    rtl_in.complex = rtl_out.complex = Create_plan<dense_complex_type>::type;
+  }
+
   virtual void in_place(ctype *inout, stride_type s, length_type l)
   {
     assert(s == 1 && static_cast<int>(l) == this->size_[0]);
@@ -163,8 +177,12 @@
 		      reinterpret_cast<FFTW(complex)*>(inout),
 		      reinterpret_cast<FFTW(complex)*>(inout));
   }
-  virtual void in_place(ztype, stride_type, length_type)
+  virtual void in_place(ztype inout, stride_type s, length_type l)
   {
+    assert(s == 1 && static_cast<int>(l) == this->size_[0]);
+    FFTW(execute_split_dft)(plan_in_place_,
+		      inout.first, inout.second,
+		      inout.first, inout.second);
   }
   virtual void by_reference(ctype *in, stride_type in_stride,
 			    ctype *out, stride_type out_stride,
@@ -173,13 +191,18 @@
     assert(in_stride == 1 && out_stride == 1 &&
 	   static_cast<int>(length) == this->size_[0]);
     FFTW(execute_dft)(plan_by_reference_,
-		      reinterpret_cast<FFTW(complex)*>(in), 
+		      reinterpret_cast<FFTW(complex)*>(in),
 		      reinterpret_cast<FFTW(complex)*>(out));
   }
-  virtual void by_reference(ztype, stride_type,
-			    ztype, stride_type,
-			    length_type)
+  virtual void by_reference(ztype in, stride_type in_stride,
+			    ztype out, stride_type out_stride,
+			    length_type length)
   {
+    assert(in_stride == 1 && out_stride == 1 &&
+	   static_cast<int>(length) == this->size_[0]);
+    FFTW(execute_split_dft)(plan_by_reference_,
+		      in.first,  in.second,
+		      out.first, out.second);
   }
 };
 
@@ -206,11 +229,29 @@
     FFTW(execute_dft_r2c)(plan_by_reference_, 
 			  in, reinterpret_cast<FFTW(complex)*>(out));
   }
-  virtual void by_reference(rtype *, stride_type,
-			    ztype, stride_type,
-			    length_type)
+  virtual void by_reference(rtype *in, stride_type is,
+			    ztype out, stride_type os,
+			    length_type length)
   {
+    FFTW(execute_split_dft_r2c)(plan_by_reference_, 
+			  in, out.first, out.second);
   }
+  virtual void query_layout(Rt_layout<1> &rtl_inout)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>
+    rtl_inout.pack = stride_unit_dense;
+    rtl_inout.order = tuple<0, 1, 2>();
+    // make default based on library
+    rtl_inout.complex = Create_plan<dense_complex_type>::type;
+  }
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    // make default based on library
+    rtl_in.complex = rtl_out.complex = Create_plan<dense_complex_type>::type;
+  }
 
 };
 
@@ -241,11 +282,29 @@
     FFTW(execute_dft_c2r)(plan_by_reference_,
 			  reinterpret_cast<FFTW(complex)*>(in), out);
   }
-  virtual void by_reference(ztype, stride_type,
-			    rtype *, stride_type,
-			    length_type)
+  virtual void by_reference(ztype in, stride_type is,
+			    rtype *out, stride_type os,
+			    length_type length)
   {
+    FFTW(execute_split_dft_c2r)(plan_by_reference_,
+			  in.first, in.second, out);
   }
+  virtual void query_layout(Rt_layout<1> &rtl_inout)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>
+    rtl_inout.pack = stride_unit_dense;
+    rtl_inout.order = tuple<0, 1, 2>();
+    // make default based on library
+    rtl_inout.complex = Create_plan<dense_complex_type>::type;
+  }
+  virtual void query_layout(Rt_layout<1> &rtl_in, Rt_layout<1> &rtl_out)
+  {
+    // By default use unit_stride, tuple<0, 1, 2>, cmplx_inter_fmt
+    rtl_in.pack = rtl_out.pack = stride_unit_dense;
+    rtl_in.order = rtl_out.order = tuple<0, 1, 2>();
+    // make default based on library
+    rtl_in.complex = rtl_out.complex = Create_plan<dense_complex_type>::type;
+  }
 
 };
 
@@ -270,8 +329,8 @@
   virtual void query_layout(Rt_layout<2> &rtl_in, Rt_layout<2> &rtl_out)
   {
     rtl_in.pack = stride_unit_dense;
-    rtl_in.complex = cmplx_inter_fmt;
     rtl_in.order = row2_type();
+    rtl_in.complex = Create_plan<dense_complex_type>::type;
     rtl_out = rtl_in;
   }
   virtual void in_place(ctype *inout,
@@ -288,10 +347,13 @@
 		      reinterpret_cast<FFTW(complex)*>(inout));
   }
   /// complex (split) in-place
-  virtual void in_place(ztype,
+  virtual void in_place(ztype inout,
 			stride_type, stride_type,
 			length_type, length_type)
   {
+    FFTW(execute_split_dft)(plan_in_place_,
+		      inout.first, inout.second,
+		      inout.first, inout.second);
   }
   virtual void by_reference(ctype *in,
 			    stride_type in_r_stride,
@@ -311,12 +373,21 @@
 		      reinterpret_cast<FFTW(complex)*>(in), 
 		      reinterpret_cast<FFTW(complex)*>(out));
   }
-  virtual void by_reference(ztype,
-			    stride_type, stride_type,
-			    ztype,
-			    stride_type, stride_type,
-			    length_type, length_type)
+  virtual void by_reference(ztype in,
+			    stride_type in_r_stride, stride_type in_c_stride,
+			    ztype out,
+			    stride_type out_r_stride, stride_type out_c_stride,
+			    length_type, length_type cols)
   {
+    // Check that data is dense row-major.
+    assert(in_r_stride == static_cast<stride_type>(cols));
+    assert(in_c_stride == 1);
+    assert(out_r_stride == static_cast<stride_type>(cols));
+    assert(out_c_stride == 1);
+
+    FFTW(execute_split_dft)(plan_by_reference_,
+                            in.first, in.second,
+                            out.first, out.second);
   }
 };
 
@@ -344,7 +415,7 @@
     // FFTW3 assumes A is the last dimension.
     if (A == 0) rtl_in.order = tuple<1, 0, 2>();
     else rtl_in.order = tuple<0, 1, 2>();
-    rtl_in.complex = cmplx_inter_fmt;
+    rtl_in.complex = Create_plan<dense_complex_type>::type;
     rtl_out = rtl_in;
   }
   virtual bool requires_copy(Rt_layout<2> &) { return true;}
@@ -358,12 +429,14 @@
     FFTW(execute_dft_r2c)(plan_by_reference_,
 			  in, reinterpret_cast<FFTW(complex)*>(out));
   }
-  virtual void by_reference(rtype *,
+  virtual void by_reference(rtype *in,
 			    stride_type, stride_type,
-			    ztype,
+			    ztype out,
 			    stride_type, stride_type,
 			    length_type, length_type)
   {
+    FFTW(execute_split_dft_r2c)(plan_by_reference_,
+			  in, out.first, out.second);
   }
 
 };
@@ -392,7 +465,7 @@
     // FFTW3 assumes A is the last dimension.
     if (A == 0) rtl_in.order = tuple<1, 0, 2>();
     else rtl_in.order = tuple<0, 1, 2>();
-    rtl_in.complex = cmplx_inter_fmt;
+    rtl_in.complex = Create_plan<dense_complex_type>::type;
     rtl_out = rtl_in;
   }
   virtual bool requires_copy(Rt_layout<2> &) { return true;}
@@ -406,12 +479,14 @@
     FFTW(execute_dft_c2r)(plan_by_reference_, 
 			  reinterpret_cast<FFTW(complex)*>(in), out);
   }
-  virtual void by_reference(ztype,
+  virtual void by_reference(ztype in,
 			    stride_type, stride_type,
-			    rtype *,
+			    rtype *out,
 			    stride_type, stride_type,
 			    length_type, length_type)
   {
+    FFTW(execute_split_dft_c2r)(plan_by_reference_, 
+			  in.first, in.second, out);
   }
 
 };
@@ -437,8 +512,8 @@
   virtual void query_layout(Rt_layout<3> &rtl_in, Rt_layout<3> &rtl_out)
   {
     rtl_in.pack = stride_unit_dense;
-    rtl_in.complex = cmplx_inter_fmt;
     rtl_in.order = row3_type();
+    rtl_in.complex = Create_plan<dense_complex_type>::type;
     rtl_out = rtl_in;
   }
   virtual void in_place(ctype *inout,
@@ -462,14 +537,26 @@
 		      reinterpret_cast<FFTW(complex)*>(inout),
 		      reinterpret_cast<FFTW(complex)*>(inout));
   }
-  virtual void in_place(ztype,
-			stride_type,
-			stride_type,
-			stride_type,
-			length_type,
-			length_type,
-			length_type)
+  virtual void in_place(ztype inout,
+			stride_type x_stride,
+			stride_type y_stride,
+			stride_type z_stride,
+			length_type x_length,
+			length_type y_length,
+			length_type z_length)
   {
+    assert(static_cast<int>(x_length) == this->size_[0]);
+    assert(static_cast<int>(y_length) == this->size_[1]);
+    assert(static_cast<int>(z_length) == this->size_[2]);
+
+    // Check that data is dense row-major.
+    assert(x_stride == static_cast<stride_type>(y_length*z_length));
+    assert(y_stride == static_cast<stride_type>(z_length));
+    assert(z_stride == 1);
+
+    FFTW(execute_split_dft)(plan_in_place_,
+		      inout.first, inout.second,
+		      inout.first, inout.second);
   }
   virtual void by_reference(ctype *in,
 			    stride_type in_x_stride,
@@ -499,18 +586,33 @@
 		      reinterpret_cast<FFTW(complex)*>(in), 
 		      reinterpret_cast<FFTW(complex)*>(out));
   }
-  virtual void by_reference(ztype,
-			    stride_type,
-			    stride_type,
-			    stride_type,
-			    ztype,
-			    stride_type,
-			    stride_type,
-			    stride_type,
-			    length_type,
-			    length_type,
-			    length_type)
+  virtual void by_reference(ztype in,
+			    stride_type in_x_stride,
+			    stride_type in_y_stride,
+			    stride_type in_z_stride,
+			    ztype out,
+			    stride_type out_x_stride,
+			    stride_type out_y_stride,
+			    stride_type out_z_stride,
+			    length_type x_length,
+			    length_type y_length,
+			    length_type z_length)
   {
+    assert(static_cast<int>(x_length) == this->size_[0]);
+    assert(static_cast<int>(y_length) == this->size_[1]);
+    assert(static_cast<int>(z_length) == this->size_[2]);
+
+    // Check that data is dense row-major.
+    assert(in_x_stride == static_cast<stride_type>(y_length*z_length));
+    assert(in_y_stride == static_cast<stride_type>(z_length));
+    assert(in_z_stride == 1);
+    assert(out_x_stride == static_cast<stride_type>(y_length*z_length));
+    assert(out_y_stride == static_cast<stride_type>(z_length));
+    assert(out_z_stride == 1);
+
+    FFTW(execute_split_dft)(plan_by_reference_,
+                      in.first, in.second,
+                      out.first, out.second);
   }
 };
 
@@ -542,7 +644,7 @@
       case 1: rtl_in.order = tuple<0, 2, 1>(); break;
       default: rtl_in.order = tuple<0, 1, 2>(); break;
     }
-    rtl_in.complex = cmplx_inter_fmt;
+    rtl_in.complex = Create_plan<dense_complex_type>::type;
     rtl_out = rtl_in;
   }
   virtual bool requires_copy(Rt_layout<3> &) { return true;}
@@ -562,11 +664,11 @@
     FFTW(execute_dft_r2c)(plan_by_reference_,
 			  in, reinterpret_cast<FFTW(complex)*>(out));
   }
-  virtual void by_reference(rtype *,
+  virtual void by_reference(rtype *in,
 			    stride_type,
 			    stride_type,
 			    stride_type,
-			    ztype,
+			    ztype out,
 			    stride_type,
 			    stride_type,
 			    stride_type,
@@ -574,6 +676,8 @@
 			    length_type,
 			    length_type)
   {
+    FFTW(execute_split_dft_r2c)(plan_by_reference_,
+			  in, out.first, out.second);
   }
 
 };
@@ -606,7 +710,7 @@
       case 1: rtl_in.order = tuple<0, 2, 1>(); break;
       default: rtl_in.order = tuple<0, 1, 2>(); break;
     }
-    rtl_in.complex = cmplx_inter_fmt;
+    rtl_in.complex = Create_plan<dense_complex_type>::type;
     rtl_out = rtl_in;
   }
   virtual bool requires_copy(Rt_layout<3> &) { return true;}
@@ -626,11 +730,11 @@
     FFTW(execute_dft_c2r)(plan_by_reference_,
 			  reinterpret_cast<FFTW(complex)*>(in), out);
   }
-  virtual void by_reference(ztype,
+  virtual void by_reference(ztype in,
 			    stride_type,
 			    stride_type,
 			    stride_type,
-			    rtype *,
+			    rtype *out,
 			    stride_type,
 			    stride_type,
 			    stride_type,
@@ -638,6 +742,8 @@
 			    length_type,
 			    length_type)
   {
+    FFTW(execute_split_dft_c2r)(plan_by_reference_,
+			  in.first, in.second, out);
   }
 
 };
Index: src/vsip/opt/fftw3/create_plan.hpp
===================================================================
--- src/vsip/opt/fftw3/create_plan.hpp	(revision 0)
+++ src/vsip/opt/fftw3/create_plan.hpp	(revision 0)
@@ -0,0 +1,224 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/fftw3/create_plan.hpp
+    @author  Assem Salama
+    @date    2007-04-13
+    @brief   VSIPL++ Library: File that has create_plan struct
+*/
+#ifndef VSIP_OPT_FFTW3_CREATE_PLAN_HPP
+#define VSIP_OPT_FFTW3_CREATE_PLAN_HPP
+
+#include <vsip/dense.hpp>
+
+#include <vsip/opt/fftw3/fftw_support.hpp>
+
+namespace vsip
+{
+namespace impl
+{
+namespace fftw3
+{
+
+// This is a helper struct to create temporary buffers used durring plan
+// creation.
+template <typename complex_type, typename T>
+struct Cmplx_buffer;
+
+// intereaved complex
+template <typename T>
+struct Cmplx_buffer<Cmplx_inter_fmt, T>
+{
+  std::complex<T> *ptr() { return buffer_.get(); }
+
+  Cmplx_buffer(length_type size) : buffer_(32, size)
+  {}
+  aligned_array<std::complex<T> > buffer_;
+};
+
+// split complex
+template <typename T>
+struct Cmplx_buffer<Cmplx_split_fmt, T>
+{
+  Cmplx_buffer(length_type size) :
+    buffer_r_(32, size),
+    buffer_i_(32, size)
+  {}
+
+  std::pair<T*,T*> ptr()
+  { return std::pair<T*, T*>(buffer_r_.get(), buffer_i_.get()); }
+
+  aligned_array<T>  buffer_r_;
+  aligned_array<T>  buffer_i_;
+};
+
+// Convert form axis to tuple
+template <dimension_type Dim>
+Rt_tuple tuple_from_axis(int A);
+
+template <>
+Rt_tuple tuple_from_axis<1>(int A) { return Rt_tuple(0,1,2); }
+template <>
+Rt_tuple tuple_from_axis<2>(int A) 
+{
+  switch (A) {
+    case 0:  return Rt_tuple(1,0,2);
+    default: return Rt_tuple(0,1,2);
+  };
+}
+
+template <>
+Rt_tuple tuple_from_axis<3>(int A) 
+{
+  switch (A) {
+    case 0:  return Rt_tuple(2,1,0);
+    case 1:  return Rt_tuple(0,2,1);
+    default: return Rt_tuple(0,1,2);
+  };
+}
+
+// This is a helper strcut to create plans
+template<typename complex_type>
+struct Create_plan;
+
+// interleaved
+template<>
+struct Create_plan<vsip::impl::Cmplx_inter_fmt>
+{
+
+  // create function for complex -> complex
+  template <typename PlanT, typename IodimT,
+            typename T, dimension_type Dim>
+  static PlanT
+  create(std::complex<T>* ptr1, std::complex<T>* ptr2,
+         int exp, int flags, Domain<Dim> const& size)
+  {
+    int sz[Dim],i;
+    for(i=0;i<Dim;i++) sz[i] = size[i].size();
+    return create_fftw_plan(Dim, sz, ptr1,ptr2,exp,flags);
+  }
+
+  // create function for real -> complex
+  template <typename PlanT, typename IodimT,
+            typename T, dimension_type Dim>
+  static PlanT
+  create(T* ptr1, std::complex<T>* ptr2,
+         int A, int flags, Domain<Dim> const& size)
+  {
+    int sz[Dim],i;
+    for(i=0;i<Dim;i++) sz[i] = size[i].size();
+    if(A != Dim-1) std::swap(sz[A], sz[Dim-1]);
+    return create_fftw_plan(Dim,sz,ptr1,ptr2,flags);
+  }
+
+  // create function for complex -> real
+  template <typename PlanT, typename IodimT,
+            typename T, dimension_type Dim>
+  static PlanT
+  create(std::complex<T>* ptr1, T* ptr2,
+         int A, int flags, Domain<Dim> const& size)
+  {
+    int sz[Dim],i;
+    for(i=0;i<Dim;i++) sz[i] = size[i].size();
+    if(A != Dim-1) std::swap(sz[A], sz[Dim-1]);
+    return create_fftw_plan(Dim,sz,ptr1,ptr2,flags);
+  }
+
+  static rt_complex_type const type = cmplx_inter_fmt;  
+
+};
+
+// split
+template<>
+struct Create_plan<vsip::impl::Cmplx_split_fmt>
+{
+
+  // create for complex -> complex
+  template <typename PlanT, typename IodimT,
+            typename T, dimension_type Dim>
+  static PlanT
+  create(std::pair<T*,T*> ptr1, std::pair<T*,T*> ptr2,
+         int exp, int flags, Domain<Dim> const& size)
+  {
+    IodimT iodims[Dim];
+    int i;
+    Applied_layout<Layout<Dim, typename Row_major<Dim>::type,
+                   Stride_unit_dense, Cmplx_split_fmt> >
+    app_layout(size);
+
+    for(i=0;i<Dim;i++) 
+    { 
+      iodims[i].n = app_layout.size(i);
+      iodims[i].is = iodims[i].os = app_layout.stride(i);
+    }
+
+    return create_fftw_plan(Dim, iodims, ptr1,ptr2, flags);
+
+  }
+
+  // create for real -> complex
+  template <typename PlanT, typename IodimT,
+            typename T, dimension_type Dim>
+  static PlanT
+  create(T *ptr1, std::pair<T*, T*> ptr2, 
+         int A, int flags, Domain<Dim> const& size)
+  {
+    IodimT iodims[Dim];
+    int i;
+    Applied_layout<Rt_layout<Dim> >
+       app_layout(Rt_layout<Dim>(stride_unit_align,
+                                 tuple_from_axis<Dim>(A),
+                                 cmplx_split_fmt,
+                                 0),
+              size, sizeof(T));
+
+
+    for(i=0;i<Dim;i++) 
+    { 
+      iodims[i].n = app_layout.size(i);
+      iodims[i].is = iodims[i].os = app_layout.stride(i); 
+    }
+
+    return create_fftw_plan(Dim, iodims, ptr1,ptr2, flags);
+  }
+
+  // create for complex -> real
+  template <typename PlanT, typename IodimT,
+            typename T, dimension_type Dim>
+  static PlanT
+  create(std::pair<T*,T*> ptr1, T* ptr2,
+         int A, int flags, Domain<Dim> const& size)
+  {
+    IodimT iodims[Dim];
+    int i;
+    Applied_layout<Rt_layout<Dim> >
+       app_layout(Rt_layout<Dim>(stride_unit_align,
+                                 tuple_from_axis<Dim>(A),
+                                 cmplx_split_fmt,
+                                 0),
+              size, sizeof(T));
+
+
+
+
+    for(i=0;i<Dim;i++) 
+    { 
+      iodims[i].n = app_layout.size(i);
+      iodims[i].is = iodims[i].os = app_layout.stride(i);
+    }
+
+    return create_fftw_plan(Dim, iodims, ptr1,ptr2, flags);
+  }
+
+  static rt_complex_type const type = cmplx_split_fmt;  
+};
+
+
+} // namespace vsip::impl::fftw3
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif // VSIP_OPT_FFTW3_CREATE_PLAN_HPP
Index: src/vsip/opt/fftw3/fftw_support.hpp
===================================================================
--- src/vsip/opt/fftw3/fftw_support.hpp	(revision 0)
+++ src/vsip/opt/fftw3/fftw_support.hpp	(revision 0)
@@ -0,0 +1,92 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/fftw3/fftw_support.hpp
+    @author  Assem Salama
+    @date    2007-04-25
+    @brief   VSIPL++ Library: File that has overloaded create functions for
+                              fftw
+
+*/
+#ifndef VSIP_OPT_FFTW3_FFTW_SUPPORT_HPP
+#define VSIP_OPT_FFTW3_FFTW_SUPPORT_HPP
+
+namespace vsip
+{
+namespace impl
+{
+namespace fftw3
+{
+
+#define DCL_FFTW_PLAN_FUNC_C2C(T, fT) \
+fT##_plan create_fftw_plan(int dim, int *sz, \
+                      std::complex<T>* ptr1, std::complex<T>* ptr2,\
+                      int exp, int flags) \
+{ return fT##_plan_dft(dim,sz,reinterpret_cast<fT##_complex*>(ptr1), \
+                     reinterpret_cast<fT##_complex*>(ptr2), exp, flags); \
+} \
+\
+fT##_plan create_fftw_plan(int dim, fT##_iodim *iodim, \
+                      std::pair<T*,T*> ptr1, std::pair<T*,T*> ptr2,\
+                      int flags) \
+{ return fT##_plan_guru_split_dft(dim,iodim,0,NULL, \
+                            ptr1.first,ptr1.second,ptr2.first,ptr2.second, \
+                            flags); \
+}
+
+#define DCL_FFTW_PLAN_FUNC_R2C(T, fT) \
+fT##_plan create_fftw_plan(int dim, int *sz, \
+                      T* ptr1, std::complex<T>* ptr2,\
+                      int flags) \
+{ return fT##_plan_dft_r2c(dim,sz,ptr1, \
+                     reinterpret_cast<fT##_complex*>(ptr2), flags); \
+} \
+\
+fT##_plan create_fftw_plan(int dim, fT##_iodim *iodim, \
+                      T* ptr1, std::pair<T*,T*> ptr2,\
+                      int flags) \
+{ return fT##_plan_guru_split_dft_r2c(dim,iodim,0,NULL, \
+                            ptr1,ptr2.first,ptr2.second, \
+                            flags); \
+}
+
+#define DCL_FFTW_PLAN_FUNC_C2R(T, fT) \
+fT##_plan create_fftw_plan(int dim, int *sz, \
+                      std::complex<T>* ptr1, T* ptr2,\
+                      int flags) \
+{ return fT##_plan_dft_c2r(dim,sz,reinterpret_cast<fT##_complex*>(ptr1), \
+                     ptr2, flags); \
+} \
+\
+fT##_plan create_fftw_plan(int dim, fT##_iodim *iodim, \
+                      std::pair<T*,T*> ptr1, T* ptr2,\
+                      int flags) \
+{ return fT##_plan_guru_split_dft_c2r(dim,iodim,0,NULL, \
+                            ptr1.first,ptr1.second,ptr2, \
+                            flags); \
+}
+
+#define DCL_FFTW_PLANS(T, fT) \
+  DCL_FFTW_PLAN_FUNC_C2C(T, fT) \
+  DCL_FFTW_PLAN_FUNC_R2C(T, fT) \
+  DCL_FFTW_PLAN_FUNC_C2R(T, fT)
+
+
+#if VSIP_IMPL_PROVIDE_FFT_FLOAT
+  DCL_FFTW_PLANS(float, fftwf)
+#endif
+#if VSIP_IMPL_PROVIDE_FFT_DOUBLE
+  DCL_FFTW_PLANS(double, fftw)
+#endif
+#if VSIP_IMPL_PROVIDE_FFT_LONG_DOUBLE
+  DCL_FFTW_PLANS(long double, fftwl)
+#endif
+
+} // namespace vsip::impl::fftw3
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif
