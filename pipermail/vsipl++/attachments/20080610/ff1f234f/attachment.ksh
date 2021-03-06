2008-06-10  Don McCoy  <don@codesourcery.com>

	* src/vsip/core/signal/fir.hpp: Add new tag for CML to type list. 
	* src/vsip/core/signal/fir_backend.hpp: Fix strides to use 'stride_type'.
	* src/vsip/core/cvsip/fir.hpp: Don't double-increment reference count.
	* src/vsip/opt/ipp/fir.hpp: Likewise.
	* src/vsip/opt/cbe/cml/fir.hpp: New file.  Implements FIR filters
	  using CML backend.
	* src/vsip/opt/signal/fir_opt.hpp: Fix stride types and double-increment.
