Index: ChangeLog
===================================================================
--- ChangeLog	(revision 222098)
+++ ChangeLog	(working copy)
@@ -1,5 +1,16 @@
 2008-09-19  Jules Bergmann  <jules@codesourcery.com>
 
+	* src/vsip/opt/fast_transpose.hpp (transpose): Add split-complex
+	  overload.
+	  (transpose_unit): Likewise.
+	* src/vsip/opt/expr/serial_evaluator.hpp: Move matrix copy/transpose
+	  evaluator to ...
+	* src/vsip/opt/expr/eval_mcopy.hpp: New file, matrix copy/transpose
+	  evaluator.  Add split-complex support.
+	* src/vsip/opt/expr/serial_dispatch.hpp: Include eval_mcopy.hpp.
+
+2008-09-19  Jules Bergmann  <jules@codesourcery.com>
+
 	Document matvec functions.
 	* doc/manual/functions.xml: Include matvec functions.
 	* doc/manual/dot.xml: New file.
Index: src/vsip/opt/fast_transpose.hpp
===================================================================
--- src/vsip/opt/fast_transpose.hpp	(revision 222098)
+++ src/vsip/opt/fast_transpose.hpp	(working copy)
@@ -648,12 +648,30 @@
 
 
 
+template <typename T1,
+	  typename T2>
+inline void
+transpose_unit(
+  std::pair<T1*, T1*> const& dst,
+  std::pair<T2*, T2*> const& src,
+  length_type const          rows,		// dst rows
+  length_type const          cols,		// dst cols
+  stride_type const          dst_col_stride,
+  stride_type const          src_row_stride)
+{
+  transpose_unit(dst.first, src.first,
+		 rows, cols, dst_col_stride, src_row_stride);
+  transpose_unit(dst.second, src.second,
+		 rows, cols, dst_col_stride, src_row_stride);
+}
+
+
+
 // Transpose for matrices with arbitrary strides.
 
 // Algorithm based on "Cache-Oblivious Algorithms (Extended Abstract)"
 // by M. Frigo, C. Leiseron, H. Prokop, S. Ramachandran.
 // citeseer.csail.mit.edu/307799.html.
-
 template <typename T1,
 	  typename T2>
 void
@@ -700,6 +718,29 @@
   }
 }
 
+template <typename T1,
+	  typename T2>
+void
+transpose(
+  std::pair<T1*, T1*> const& dst,
+  std::pair<T2*, T2*> const& src,
+  length_type const          rows,		// dst rows
+  length_type const          cols,		// dst cols
+  stride_type const          dst_stride0,
+  stride_type const          dst_stride1,
+  stride_type const          src_stride0,
+  stride_type const          src_stride1)
+{
+  transpose(dst.first, src.first,
+	    rows, cols,
+	    dst_stride0, dst_stride1,
+	    src_stride0, src_stride1);
+  transpose(dst.second, src.second,
+	    rows, cols,
+	    dst_stride0, dst_stride1,
+	    src_stride0, src_stride1);
+}
+
 } // namespace vsip::impl
 } // namespace vsip
 
Index: src/vsip/opt/expr/serial_dispatch.hpp
===================================================================
--- src/vsip/opt/expr/serial_dispatch.hpp	(revision 222098)
+++ src/vsip/opt/expr/serial_dispatch.hpp	(working copy)
@@ -26,6 +26,7 @@
 #include <vsip/core/type_list.hpp>
 #include <vsip/opt/expr/serial_evaluator.hpp>
 #include <vsip/opt/expr/serial_dispatch_fwd.hpp>
+#include <vsip/opt/expr/eval_mcopy.hpp>
 #include <vsip/opt/expr/eval_mdim.hpp>
 #include <vsip/opt/expr/eval_dense.hpp>
 #include <vsip/opt/expr/eval_return_block.hpp>
Index: src/vsip/opt/expr/eval_mcopy.hpp
===================================================================
--- src/vsip/opt/expr/eval_mcopy.hpp	(revision 0)
+++ src/vsip/opt/expr/eval_mcopy.hpp	(revision 0)
@@ -0,0 +1,287 @@
+/* Copyright (c) 2008 by CodeSourcery.  All rights reserved.
+
+   This file is available for license from CodeSourcery, Inc. under the terms
+   of a commercial license and under the GPL.  It is not part of the VSIPL++
+   reference implementation and is not available under the BSD license.
+*/
+/** @file    vsip/opt/expr/mcopy.hpp
+    @author  Jules Bergmann
+    @date    2008-09-19
+    @brief   VSIPL++ Library: Generic matrix copy/transpose evaluator.
+*/
+
+#ifndef VSIP_OPT_EXPR_MCOPY_HPP
+#define VSIP_OPT_EXPR_MCOPY_HPP
+
+#if VSIP_IMPL_REF_IMPL
+# error "vsip/opt files cannot be used as part of the reference impl."
+#endif
+
+/***********************************************************************
+  Included Files
+***********************************************************************/
+
+#include <vsip/core/metaprogramming.hpp>
+#include <vsip/core/block_traits.hpp>
+#include <vsip/core/extdata.hpp>
+#include <vsip/opt/fast_transpose.hpp>
+#include <vsip/core/impl_tags.hpp>
+
+
+
+/***********************************************************************
+  Declarations
+***********************************************************************/
+
+namespace vsip
+{
+namespace impl
+{
+
+// Generic in-place transpose
+
+template <typename T>
+void
+ip_transpose(
+  T*          d_ptr,
+  stride_type row_stride,
+  stride_type col_stride,
+  length_type rows,
+  length_type cols)
+{
+  for (index_type i=0; i<rows; ++i)
+    for (index_type j=i; j<cols; ++j)
+    {
+      std::swap(d_ptr[col_stride * i + row_stride * j],
+		d_ptr[col_stride * j + row_stride * i]);
+    }
+}
+
+// Split-complex in-place transpose
+
+template <typename T>
+void
+ip_transpose(
+  std::pair<T*, T*> const& d,
+  stride_type              row_stride,
+  stride_type              col_stride,
+  length_type              rows,
+  length_type              cols)
+{
+  ip_transpose(d.first,  row_stride, col_stride, rows, cols);
+  ip_transpose(d.second, row_stride, col_stride, rows, cols);
+}
+
+
+
+// Generic matrix copy.
+
+template <typename T>
+void
+mcopy(
+  T*          d_ptr,
+  T*          s_ptr,
+  stride_type d_stride_0,
+  stride_type d_stride_1,
+  stride_type s_stride_0,
+  stride_type s_stride_1,
+  length_type size_0,
+  length_type size_1)
+{
+  if (d_stride_1 == 1 && s_stride_1 == 1)
+  {
+    // Dense
+    if (d_stride_0 == static_cast<stride_type>(size_1) &&
+	s_stride_0 == static_cast<stride_type>(size_1))
+      memcpy(d_ptr, s_ptr, size_0*size_1*sizeof(T));
+    // Contiguous rows
+    else
+      for (index_type i=0; i<size_0; ++i)
+      {
+	memcpy(d_ptr, s_ptr, size_1*sizeof(T));
+	d_ptr += d_stride_0;
+	s_ptr += s_stride_0;
+      }
+  }
+  else
+  {
+    for (index_type i=0; i<size_0; ++i)
+    {
+      T* d_row = d_ptr;
+      T* s_row = s_ptr;
+      
+      for (index_type j=0; j<size_1; ++j)
+      {
+	*d_row = *s_row;
+	d_row += d_stride_1;
+	s_row += s_stride_1;
+      }
+      
+      d_ptr += d_stride_0;
+      s_ptr += s_stride_0;
+    }
+  }
+}
+
+// Split-complex matrix copy.
+
+template <typename T>
+void
+mcopy(
+  std::pair<T*, T*> const& d,
+  std::pair<T*, T*> const& s,
+  stride_type              d_stride_0,
+  stride_type              d_stride_1,
+  stride_type              s_stride_0,
+  stride_type              s_stride_1,
+  length_type              size_0,
+  length_type              size_1)
+{
+  mcopy(d.first, s.first,
+	    d_stride_0, d_stride_1,
+	    s_stride_0, s_stride_1,
+	    size_0, size_1);
+  mcopy(d.second, s.second,
+	    d_stride_0, d_stride_1,
+	    s_stride_0, s_stride_1,
+	    size_0, size_1);
+}
+
+
+
+// Matrix copy and transpose evaluator.
+
+template <typename DstBlock,
+	  typename SrcBlock>
+struct Serial_expr_evaluator<2, DstBlock, SrcBlock, Transpose_tag>
+{
+  static char const* name()
+  {
+    char s = Type_equal<src_order_type, row2_type>::value ? 'r' : 'c';
+    char d = Type_equal<dst_order_type, row2_type>::value ? 'r' : 'c';
+    if      (s == 'r' && d == 'r')    return "Expr_Trans (rr copy)";
+    else if (s == 'r' && d == 'c')    return "Expr_Trans (rc trans)";
+    else if (s == 'c' && d == 'r')    return "Expr_Trans (cr trans)";
+    else /* (s == 'c' && d == 'c') */ return "Expr_Trans (cc copy)";
+  }
+
+  typedef typename DstBlock::value_type dst_value_type;
+  typedef typename SrcBlock::value_type src_value_type;
+
+  static bool const is_rhs_expr   = Is_expr_block<SrcBlock>::value;
+
+  static bool const is_rhs_simple =
+    Is_simple_distributed_block<SrcBlock>::value;
+
+  static bool const is_lhs_split  = Is_split_block<DstBlock>::value;
+  static bool const is_rhs_split  = Is_split_block<SrcBlock>::value;
+
+  static int const  lhs_cost      = Ext_data_cost<DstBlock>::value;
+  static int const  rhs_cost      = Ext_data_cost<SrcBlock>::value;
+
+  typedef typename Block_layout<SrcBlock>::order_type src_order_type;
+  typedef typename Block_layout<DstBlock>::order_type dst_order_type;
+
+  static bool const ct_valid =
+    Type_equal<src_value_type, dst_value_type>::value &&
+    !is_rhs_expr &&
+    lhs_cost == 0 && rhs_cost == 0 &&
+    (is_lhs_split == is_rhs_split);
+
+  static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
+  { return true; }
+
+  static void exec(DstBlock& dst, SrcBlock const& src, row2_type, row2_type)
+  {
+    vsip::impl::Ext_data<DstBlock> d_ext(dst, vsip::impl::SYNC_OUT);
+    vsip::impl::Ext_data<SrcBlock> s_ext(src, vsip::impl::SYNC_IN);
+
+    mcopy(
+      d_ext.data(), s_ext.data(),
+      d_ext.stride(0), d_ext.stride(1),
+      s_ext.stride(0), s_ext.stride(1),
+      d_ext.size(0), d_ext.size(1));
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src, col2_type, col2_type)
+  {
+    vsip::impl::Ext_data<DstBlock> d_ext(dst, vsip::impl::SYNC_OUT);
+    vsip::impl::Ext_data<SrcBlock> s_ext(src, vsip::impl::SYNC_IN);
+
+    mcopy(
+      d_ext.data(), s_ext.data(),
+      d_ext.stride(1), d_ext.stride(0),
+      s_ext.stride(1), s_ext.stride(0),
+      d_ext.size(1), d_ext.size(0));
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src, col2_type, row2_type)
+  {
+    vsip::impl::Ext_data<DstBlock> dst_ext(dst, vsip::impl::SYNC_OUT);
+    vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
+
+    // In-place transpose
+    if (is_same_ptr(dst_ext.data(), src_ext.data()))
+    {
+      // in-place transpose implies square matrix
+      assert(dst.size(2, 0) == dst.size(2, 1));
+      ip_transpose(dst_ext.data(),
+		   dst_ext.stride(0), dst_ext.stride(1),
+		   dst.size(2, 0), dst.size(2, 1));
+    }
+    else if (dst_ext.stride(0) == 1 && src_ext.stride(1) == 1)
+    {
+      transpose_unit(dst_ext.data(), src_ext.data(),
+		     dst.size(2, 0), dst.size(2, 1), // rows, cols
+		     dst_ext.stride(1),		     // dst_col_stride
+		     src_ext.stride(0));	     // src_row_stride
+    }
+    else
+    {
+      transpose(dst_ext.data(), src_ext.data(),
+		dst.size(2, 0), dst.size(2, 1),		// rows, cols
+		dst_ext.stride(0), dst_ext.stride(1),	// dst strides
+		src_ext.stride(0), src_ext.stride(1));	// srd strides
+    }
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src, row2_type, col2_type)
+  {
+    vsip::impl::Ext_data<DstBlock> dst_ext(dst, vsip::impl::SYNC_OUT);
+    vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
+
+    // In-place transpose
+    if (is_same_ptr(dst_ext.data(), src_ext.data()))
+    {
+      // in-place transpose implies square matrix
+      assert(dst.size(2, 0) == dst.size(2, 1));
+      ip_transpose(dst_ext.data(),
+		   dst_ext.stride(0), dst_ext.stride(1),
+		   dst.size(2, 0), dst.size(2, 1));
+    }
+    else if (dst_ext.stride(1) == 1 && src_ext.stride(0) == 1)
+    {
+      transpose_unit(dst_ext.data(), src_ext.data(),
+		     dst.size(2, 1), dst.size(2, 0), // rows, cols
+		     dst_ext.stride(0),	  // dst_col_stride
+		     src_ext.stride(1));	  // src_row_stride
+    }
+    else
+    {
+      transpose(dst_ext.data(), src_ext.data(),
+		dst.size(2, 1), dst.size(2, 0), // rows, cols
+		dst_ext.stride(1), dst_ext.stride(0),	// dst strides
+		src_ext.stride(1), src_ext.stride(0));	// srd strides
+    }
+  }
+
+  static void exec(DstBlock& dst, SrcBlock const& src)
+  {
+    exec(dst, src, dst_order_type(), src_order_type());
+  }
+};
+
+} // namespace vsip::impl
+} // namespace vsip
+
+#endif
Index: src/vsip/opt/expr/serial_evaluator.hpp
===================================================================
--- src/vsip/opt/expr/serial_evaluator.hpp	(revision 222098)
+++ src/vsip/opt/expr/serial_evaluator.hpp	(working copy)
@@ -24,13 +24,13 @@
 #include <vsip/core/metaprogramming.hpp>
 #include <vsip/core/block_traits.hpp>
 #include <vsip/core/extdata.hpp>
-#include <vsip/opt/fast_transpose.hpp>
 #include <vsip/core/adjust_layout.hpp>
 #include <vsip/core/coverage.hpp>
 #include <vsip/core/impl_tags.hpp>
 #include <vsip/opt/expr/lf_initfini.hpp>
 
 
+
 /***********************************************************************
   Declarations
 ***********************************************************************/
@@ -129,240 +129,9 @@
 
 
 
-template <typename DstBlock,
-	  typename SrcBlock>
-struct Serial_expr_evaluator<2, DstBlock, SrcBlock, Transpose_tag>
-{
-  static char const* name()
-  {
-    char s = Type_equal<src_order_type, row2_type>::value ? 'r' : 'c';
-    char d = Type_equal<dst_order_type, row2_type>::value ? 'r' : 'c';
-    if      (s == 'r' && d == 'r')    return "Expr_Trans (rr copy)";
-    else if (s == 'r' && d == 'c')    return "Expr_Trans (rc trans)";
-    else if (s == 'c' && d == 'r')    return "Expr_Trans (cr trans)";
-    else /* (s == 'c' && d == 'c') */ return "Expr_Trans (cc copy)";
-  }
 
-  typedef typename DstBlock::value_type dst_value_type;
-  typedef typename SrcBlock::value_type src_value_type;
 
-  static bool const is_rhs_expr   = Is_expr_block<SrcBlock>::value;
 
-  static bool const is_rhs_simple =
-    Is_simple_distributed_block<SrcBlock>::value;
-
-  static bool const is_lhs_split  = Is_split_block<DstBlock>::value;
-  static bool const is_rhs_split  = Is_split_block<SrcBlock>::value;
-
-  static int const  lhs_cost      = Ext_data_cost<DstBlock>::value;
-  static int const  rhs_cost      = Ext_data_cost<SrcBlock>::value;
-
-  typedef typename Block_layout<SrcBlock>::order_type src_order_type;
-  typedef typename Block_layout<DstBlock>::order_type dst_order_type;
-
-  static bool const ct_valid =
-    // Skip evaluator if expression is non-transpose type-conversion
-    !(! Type_equal<src_value_type, dst_value_type>::value &&
-        Type_equal<src_order_type, dst_order_type>::value) &&
-    !is_rhs_expr &&
-    lhs_cost == 0 && rhs_cost == 0 &&
-    !is_lhs_split && !is_rhs_split;
-
-  static bool rt_valid(DstBlock& /*dst*/, SrcBlock const& /*src*/)
-  { return true; }
-
-  static void exec(DstBlock& dst, SrcBlock const& src, row2_type, row2_type)
-  {
-    vsip::impl::Ext_data<DstBlock> d_ext(dst, vsip::impl::SYNC_OUT);
-    vsip::impl::Ext_data<SrcBlock> s_ext(src, vsip::impl::SYNC_IN);
-
-    dst_value_type* d_ptr = d_ext.data();
-    src_value_type* s_ptr = s_ext.data();
-
-    stride_type d_stride_0 = d_ext.stride(0);
-    stride_type d_stride_1 = d_ext.stride(1);
-    stride_type s_stride_0 = s_ext.stride(0);
-    stride_type s_stride_1 = s_ext.stride(1);
-
-    length_type size_0     = d_ext.size(0);
-    length_type size_1     = d_ext.size(1);
-
-    assert(size_0 <= s_ext.size(0));
-    assert(size_1 <= s_ext.size(1));
-
-    if (Type_equal<dst_value_type, src_value_type>::value
-	&& d_stride_1 == 1 && s_stride_1 == 1)
-    {
-      if (d_stride_0 == static_cast<stride_type>(size_1) &&
-	  s_stride_0 == static_cast<stride_type>(size_1))
-	memcpy(d_ptr, s_ptr, size_0*size_1*sizeof(dst_value_type));
-      else
-	for (index_type i=0; i<size_0; ++i)
-	{
-	  memcpy(d_ptr, s_ptr, size_1*sizeof(dst_value_type));
-	  d_ptr += d_stride_0;
-	  s_ptr += s_stride_0;
-	}
-    }
-    else
-    {
-      for (index_type i=0; i<size_0; ++i)
-      {
-	dst_value_type* d_row = d_ptr;
-	src_value_type* s_row = s_ptr;
-	
-	for (index_type j=0; j<size_1; ++j)
-        {
-	  *d_row = *s_row;
-	  d_row += d_stride_1;
-	  s_row += s_stride_1;
-        }
-
-	d_ptr += d_stride_0;
-	s_ptr += s_stride_0;
-      }
-    }
-  }
-
-  static void exec(DstBlock& dst, SrcBlock const& src, col2_type, col2_type)
-  {
-    vsip::impl::Ext_data<DstBlock> d_ext(dst, vsip::impl::SYNC_OUT);
-    vsip::impl::Ext_data<SrcBlock> s_ext(src, vsip::impl::SYNC_IN);
-
-    dst_value_type* d_ptr = d_ext.data();
-    src_value_type* s_ptr = s_ext.data();
-
-    stride_type d_stride_0 = d_ext.stride(0);
-    stride_type d_stride_1 = d_ext.stride(1);
-    stride_type s_stride_0 = s_ext.stride(0);
-    stride_type s_stride_1 = s_ext.stride(1);
-
-    length_type size_0     = d_ext.size(0);
-    length_type size_1     = d_ext.size(1);
-
-    assert(size_0 <= s_ext.size(0));
-    assert(size_1 <= s_ext.size(1));
-
-    if (Type_equal<dst_value_type, src_value_type>::value
-	&& d_stride_0 == 1 && s_stride_0 == 1)
-    {
-      if (d_stride_1 == static_cast<stride_type>(size_0) &&
-	  s_stride_1 == static_cast<stride_type>(size_0))
-	memcpy(d_ptr, s_ptr, size_0*size_1*sizeof(dst_value_type));
-      else
-	for (index_type j=0; j<size_1; ++j)
-	{
-	  memcpy(d_ptr, s_ptr, size_0*sizeof(dst_value_type));
-	  d_ptr += d_stride_1;
-	  s_ptr += s_stride_1;
-	}
-    }
-    else
-    {
-      for (index_type j=0; j<size_1; ++j)
-      {
-	dst_value_type* d_row = d_ptr;
-	src_value_type* s_row = s_ptr;
-	
-	for (index_type i=0; i<size_0; ++i)
-        {
-	  *d_row = *s_row;
-	  d_row += d_stride_0;
-	  s_row += s_stride_0;
-        }
-
-	d_ptr += d_stride_1;
-	s_ptr += s_stride_1;
-      }
-    }
-  }
-
-  static void exec(DstBlock& dst, SrcBlock const& src, col2_type, row2_type)
-  {
-    vsip::impl::Ext_data<DstBlock> dst_ext(dst, vsip::impl::SYNC_OUT);
-    vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
-
-    // In-place transpose
-    if (is_same_ptr(dst_ext.data(), src_ext.data()))
-    {
-      dst_value_type* d_ptr = dst_ext.data();
-      // in-place transpose implies square matrix
-      length_type const rows = dst.size(2, 0);
-      length_type const cols = dst.size(2, 1);
-      stride_type row_stride = dst_ext.stride(0);
-      stride_type col_stride = dst_ext.stride(1);
-      assert(rows == cols);
-      for (index_type i=0; i<rows; ++i)
-	for (index_type j=i; j<cols; ++j)
-        {
-          std::swap(d_ptr[col_stride * i + row_stride * j],
-                    d_ptr[col_stride * j + row_stride * i]);
-        }
-    }
-    else if (dst_ext.stride(0) == 1 && src_ext.stride(1) == 1)
-    {
-      transpose_unit(dst_ext.data(), src_ext.data(),
-		     dst.size(2, 0), dst.size(2, 1), // rows, cols
-		     dst_ext.stride(1),		     // dst_col_stride
-		     src_ext.stride(0));	     // src_row_stride
-    }
-    else
-    {
-      transpose(dst_ext.data(), src_ext.data(),
-		dst.size(2, 0), dst.size(2, 1),		// rows, cols
-		dst_ext.stride(0), dst_ext.stride(1),	// dst strides
-		src_ext.stride(0), src_ext.stride(1));	// srd strides
-    }
-  }
-
-  static void exec(DstBlock& dst, SrcBlock const& src, row2_type, col2_type)
-  {
-    vsip::impl::Ext_data<DstBlock> dst_ext(dst, vsip::impl::SYNC_OUT);
-    vsip::impl::Ext_data<SrcBlock> src_ext(src, vsip::impl::SYNC_IN);
-
-    // In-place transpose
-    if (is_same_ptr(dst_ext.data(), src_ext.data()))
-    {
-      dst_value_type* d_ptr = dst_ext.data();
-      // in-place transpose implies square matrix
-      length_type const rows = dst.size(2, 0);
-      length_type const cols = dst.size(2, 1);
-      stride_type row_stride = dst_ext.stride(0);
-      stride_type col_stride = dst_ext.stride(1);
-      assert(rows == cols);
-      for (index_type i=0; i<rows; ++i)
-	for (index_type j=i; j<cols; ++j)
-        {
-          std::swap(d_ptr[col_stride * i + row_stride * j],
-                    d_ptr[col_stride * j + row_stride * i]);
-        }
-    }
-    else if (dst_ext.stride(1) == 1 && src_ext.stride(0) == 1)
-    {
-      transpose_unit(dst_ext.data(), src_ext.data(),
-		     dst.size(2, 1), dst.size(2, 0), // rows, cols
-		     dst_ext.stride(0),	  // dst_col_stride
-		     src_ext.stride(1));	  // src_row_stride
-    }
-    else
-    {
-      transpose(dst_ext.data(), src_ext.data(),
-		dst.size(2, 1), dst.size(2, 0), // rows, cols
-		dst_ext.stride(1), dst_ext.stride(0),	// dst strides
-		src_ext.stride(1), src_ext.stride(0));	// srd strides
-    }
-  }
-
-  static void exec(DstBlock& dst, SrcBlock const& src)
-  {
-    exec(dst, src, dst_order_type(), src_order_type());
-  }
-  
-};
-
-
-
-
 template <typename DstBlock,
 	  typename SrcBlock>
 struct Serial_expr_evaluator<2, DstBlock, SrcBlock, Loop_fusion_tag>
