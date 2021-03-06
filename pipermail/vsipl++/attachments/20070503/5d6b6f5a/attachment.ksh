Index: ChangeLog
===================================================================
--- ChangeLog	(revision 170234)
+++ ChangeLog	(working copy)
@@ -1,4 +1,13 @@
+2007-05-03  Jules Bergmann  <jules@codesourcery.com>
+
+	* src/vsip/opt/cbe/ppu/fft.cpp (Fftm_impl): Return if empty subblock.
+	* tests/regressions/dist_fftm.cpp: New file, regression test for
+	  empty subblock handling.
+	* tests/GNUmakefile.inc.in (tests_parallel_CXXINCLUDES): New
+	  variable, add include path for compiling tests in parallel/ subdir.
+	
 2007-04-29  Assem Salama <assem@codesourcery.com>
+	
 	* tests/parallel/vram.cpp: New file. This file tests the ramp
 	  function.
 	* src/vsip/core/expr/map_subset_block.hpp: Added const to the get
Index: src/vsip/opt/cbe/ppu/fft.cpp
===================================================================
--- src/vsip/opt/cbe/ppu/fft.cpp	(revision 168970)
+++ src/vsip/opt/cbe/ppu/fft.cpp	(working copy)
@@ -289,12 +289,14 @@
   {
     if (A != 0)
     {
+      if (rows == 0) return; // Handle empty local subblock.
       assert(rows <= this->size_[0]); // OK if rows are distributed.
       assert(cols == this->size_[1]); // Columns must be whole.
       assert(c_stride == 1);
     }
     else
     {
+      if (cols == 0) return; // Handle empty local subblock.
       assert(rows == this->size_[0]); // Rows must be whole.
       assert(cols <= this->size_[1]); // OK if columns are distributed.
       assert(r_stride == 1);
@@ -319,12 +321,14 @@
   {
     if (A != 0)
     {
+      if (rows == 0) return; // Handle empty local subblock.
       assert(rows <= this->size_[0]); // OK if rows are distributed.
       assert(cols == this->size_[1]); // Columns must be whole.
       assert(in_c_stride == 1 && out_c_stride == 1);
     }
     else
     {
+      if (cols == 0) return; // Handle empty local subblock.
       assert(rows == this->size_[0]); // Rows must be whole.
       assert(cols <= this->size_[1]); // OK if columns are distributed.
       assert(in_r_stride == 1 && out_r_stride == 1);
Index: tests/regressions/dist_fftm.cpp
===================================================================
--- tests/regressions/dist_fftm.cpp	(revision 0)
+++ tests/regressions/dist_fftm.cpp	(revision 0)
@@ -0,0 +1,197 @@
+/* Copyright (c) 2007 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+
+/** @file    tests/dist_fftm.cpp
+    @author  Jules Bergmann
+    @date    2007-05-03
+    @brief   VSIPL++ Library: Distributed Fftm regression.
+
+    Empty local subblocks caused an assert failure in the CBE FFTM BE.
+*/
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <algorithm>
+
+#include <vsip/initfin.hpp>
+#include <vsip/support.hpp>
+#include <vsip/matrix.hpp>
+#include <vsip/signal.hpp>
+#include <vsip/map.hpp>
+
+#include <vsip_csl/test.hpp>
+
+using namespace std;
+using namespace vsip;
+
+
+/***********************************************************************
+  Definitions
+***********************************************************************/
+
+// By-value Fftm, out-of-place
+
+template <typename T,
+	  typename MapT>
+void
+test_fftm_bv_op(
+  bool        scale,
+  MapT const& map = MapT())
+{
+  typedef Fftm<T, T, row, fft_fwd, by_value, 1> fftm_type;
+
+  length_type rows = 16;
+  length_type cols = 64;
+
+  fftm_type fftm(Domain<2>(rows, cols), scale ? 1.f / cols : 1.f);
+
+  Matrix<T, Dense<2, T, row2_type, MapT> > in (rows, cols,          map);
+  Matrix<T, Dense<2, T, row2_type, MapT> > out(rows, cols, T(-100), map);
+
+  in = T(1);
+
+  out = fftm(in); 
+
+  for (index_type r=0; r<rows; ++r)
+    test_assert(out.get(r, 0) == T(scale ? 1 : cols));
+}
+
+
+
+// By-value Fftm, in-place
+
+template <typename T,
+	  typename MapT>
+void
+test_fftm_bv_ip(
+  bool        scale,
+  MapT const& map = MapT())
+{
+  typedef Fftm<T, T, row, fft_fwd, by_value, 1> fftm_type;
+
+  length_type rows = 16;
+  length_type cols = 64;
+
+  fftm_type fftm(Domain<2>(rows, cols), scale ? 1.f / cols : 1.f);
+
+  Matrix<T, Dense<2, T, row2_type, MapT> > inout(rows, cols, map);
+
+  inout = T(1);
+
+  inout = fftm(inout); 
+
+  for (index_type r=0; r<rows; ++r)
+    test_assert(inout.get(r, 0) == T(scale ? 1 : cols));
+}
+
+
+
+// By-reference Fftm, out-of-place
+
+template <typename T,
+	  typename MapT>
+void
+test_fftm_br_op(
+  bool        scale,
+  MapT const& map = MapT())
+{
+  typedef Fftm<T, T, row, fft_fwd, by_reference, 1> fftm_type;
+
+  length_type rows = 16;
+  length_type cols = 64;
+
+  fftm_type fftm(Domain<2>(rows, cols), scale ? 1.f / cols : 1.f);
+
+  Matrix<T, Dense<2, T, row2_type, MapT> > in (rows, cols,          map);
+  Matrix<T, Dense<2, T, row2_type, MapT> > out(rows, cols, T(-100), map);
+
+  in = T(1);
+
+  fftm(in, out); 
+
+  for (index_type r=0; r<rows; ++r)
+    test_assert(out.get(r, 0) == T(scale ? 1 : cols));
+}
+
+
+
+// By-reference Fftm, in-place
+
+template <typename T,
+	  typename MapT>
+void
+test_fftm_br_ip(
+  bool        scale,
+  MapT const& map = MapT())
+{
+  typedef Fftm<T, T, row, fft_fwd, by_reference, 1> fftm_type;
+
+  length_type rows = 16;
+  length_type cols = 64;
+
+  fftm_type fftm(Domain<2>(rows, cols), scale ? 1.f / cols : 1.f);
+
+  Matrix<T, Dense<2, T, row2_type, MapT> > inout(rows, cols, map);
+
+  inout = T(1);
+
+  fftm(inout); 
+
+  for (index_type r=0; r<rows; ++r)
+    test_assert(inout.get(r, 0) == T(scale ? 1 : cols));
+}
+
+
+
+/***********************************************************************
+  Main
+***********************************************************************/
+
+int
+main(int argc, char** argv)
+{
+  vsipl init(argc, argv);
+
+  // Test with local map.
+
+  Local_map lmap;
+
+  test_fftm_bv_op<complex<float> >(true,  lmap);
+  test_fftm_bv_ip<complex<float> >(true,  lmap);
+  test_fftm_br_op<complex<float> >(true,  lmap);
+  test_fftm_br_ip<complex<float> >(true,  lmap);
+
+
+  // Test with map that distributes rows across all processors.
+  // (Each processor should have 1 or more rows, unless, NP > 64).
+
+  length_type np = vsip::num_processors();
+  Map<> map1(np, 1);
+
+  test_fftm_bv_op<complex<float> >(true, map1);
+  test_fftm_bv_ip<complex<float> >(true, map1);
+  test_fftm_br_op<complex<float> >(true, map1);
+  test_fftm_br_ip<complex<float> >(true, map1);
+
+
+  // Test with map that collects all rows on root processor.
+  // (Other processor will have 0 rows, i.e. an empty subblock).
+  //
+  // 070503: This triggered an assertion failure in the CBE FFTM BE
+  //         when run with 2 or more processors.
+
+  Map<> map2(1, 1);
+
+  test_fftm_bv_op<complex<float> >(true, map2);
+  test_fftm_bv_ip<complex<float> >(true, map2);
+  test_fftm_br_op<complex<float> >(true, map2);
+  test_fftm_br_ip<complex<float> >(true, map2);
+
+  return 0;
+}
Index: tests/GNUmakefile.inc.in
===================================================================
--- tests/GNUmakefile.inc.in	(revision 168970)
+++ tests/GNUmakefile.inc.in	(working copy)
@@ -34,6 +34,9 @@
 tests_cxx_exes := \
 	$(patsubst $(srcdir)/%.cpp, %$(EXEEXT), $(tests_cxx_sources))
 
+# Add tests/ to include search path for tests/ subdirectories.
+tests_parallel_CXXINCLUDES := -I$(srcdir)/tests
+
 ########################################################################
 # Rules
 ########################################################################
