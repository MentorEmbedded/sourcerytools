Index: ChangeLog
===================================================================
--- ChangeLog	(revision 237124)
+++ ChangeLog	(working copy)
@@ -1,3 +1,8 @@
+2009-02-24  Jules Bergmann  <jules@codesourcery.com>
+
+	* apps/ssar/Makefile.in: New file, makefile for in-objdir building
+	  of SSAR.
+
 2009-02-19  Jules Bergmann  <jules@codesourcery.com>
 
 	* doc/getting-started/getting-started.xml: Update documentation for
Index: apps/ssar/Makefile.in
===================================================================
--- apps/ssar/Makefile.in	(revision 0)
+++ apps/ssar/Makefile.in	(revision 0)
@@ -0,0 +1,116 @@
+########################################################################
+#
+# File:   apps/ssar/Makefile.in
+# Author: Jules Bergmann
+# Date:   2008-09-20
+#
+# Contents: Makefile for in-tree SSAR build
+#
+########################################################################
+
+# The default precision is single (double may also be used)
+precision = single
+
+ifeq ($(precision),double)
+ref_image_base := ref_image_dp
+ssar_type := SSAR_BASE_TYPE=double
+else
+ref_image_base := ref_image_sp
+ssar_type := SSAR_BASE_TYPE=float
+endif
+
+
+
+PGM =
+
+srcdir := @srcdir@
+OBJEXT := @OBJEXT@
+
+vpath %.cpp $(srcdir)
+vpath %.hpp $(srcdir)
+
+cxx_sources := $(wildcard $(srcdir)/*.cpp)
+cxx_exclude := # $(srcdir)/tests/sumval-func.cpp
+
+objects := $(patsubst $(srcdir)/%.cpp, %.$(OBJEXT), $(cxx_sources))
+deps    := $(patsubst $(srcdir)/%.cpp, %.d, $(cxx_sources))
+tests   := $(patsubst $(srcdir)/%.cpp, %.test, $(cxx_sources))
+xtests  := $(patsubst $(srcdir)/%.cpp, %, $(cxx_sources))
+
+relpath := ../..
+
+INC	= -I$(relpath)/src -I$(srcdir)/$(relpath)/src -I$(srcdir) @CPPFLAGS@
+LIBS    = -L$(relpath)/lib -lvsip_csl -lsvpp @LIBS@
+LDFLAGS = @LDFLAGS@
+
+REMOTE  =
+
+CXX      = @CXX@
+CXXFLAGS = @CXXFLAGS@ $(INC) -DVSIP_IMPL_PROFILER=11 -D$(ssar_type)
+
+fmtprof := $(srcdir)/$(relpath)/scripts/fmt-profile.pl
+
+%.o: %.cpp
+	$(CXX) -c $(CXXFLAGS) -o $@ $<
+
+%.s: %.cpp
+	$(CXX) -S $(CXXFLAGS) -o $@ $<
+
+%.d: %.cpp
+	$(SHELL) -ec '$(CXX) -M $(CXXFLAGS) $< \
+		      | sed "s|$(*F)\\.o[ :]*|$*\\.d $*\\.o : |g" > $@' \
+		|| rm -f $@
+
+ifeq (,$(filter $(MAKECMDGOALS), xtest clean xclean))
+include $(deps)
+endif
+
+########################################################################
+# Rules
+########################################################################
+
+all: ssar viewtopng diffview
+
+clean: 
+	rm -f *.o
+	rm -f ssar
+	rm -f viewtopng
+	rm -f diffview
+
+check: all
+	@echo "Running SSAR application..."
+	./ssar data3
+	@echo
+	@echo "Comparing output to reference view (should be less than -100)"
+	./diffview -r data3/image.view data3/$(ref_image_base).view 756 1144
+	@echo
+	@echo "Creating viewable image of output"
+	./viewtopng -s data3/image.view data3/image.png 1144 756
+	@echo "Creating viewable image of reference view"
+	./viewtopng -s data3/$(ref_image_base).view data3/$(ref_image_base).png 1144 756
+
+profile1: ssar viewtopng
+	@echo "Profiling SSAR application (SCALE = 1)..."
+	./ssar data1 -loop 10 --vsipl++-profile-mode=accum --vsipl++-profile-output=profile.out
+	@echo "Formatting profiler output..."
+	${fmtprof}  -sec -o profile1.txt data1/profile.out
+	./make_images.sh data1 438 160 382 266
+
+profile3: ssar viewtopng
+	@echo "Profiling SSAR application (SCALE = 3)..."
+	./ssar data3 -loop 10 --vsipl++-profile-mode=accum --vsipl++-profile-output=profile.out
+	@echo "Formatting profiler output..."
+	${fmtprof}  -sec -o profile3.txt data3/profile.out
+	./make_images.sh data3 1072 480 1144 756
+
+
+ssar.o: ssar.cpp kernel1.hpp
+
+ssar: ssar.o
+	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS) $(LIBS)
+
+viewtopng: viewtopng.o
+	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS) $(LIBS) -lpng
+
+diffview: diffview.o
+	$(CXX) $(CXXFLAGS) -o $@ $^ $(LDFLAGS) $(LIBS)
