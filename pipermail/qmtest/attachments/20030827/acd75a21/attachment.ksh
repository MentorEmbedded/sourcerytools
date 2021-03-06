Index: setup.py
===================================================================
RCS file: /home/qm/Repository/qm/setup.py,v
retrieving revision 1.1
diff -u -r1.1 setup.py
--- setup.py	27 Aug 2003 16:18:31 -0000	1.1
+++ setup.py	27 Aug 2003 20:45:19 -0000
@@ -16,7 +16,10 @@
 from distutils.core import setup
 from distutils.command import build
 from distutils.command import install_data
-from distutils.spawn import find_executable
+from distutils.spawn import spawn, find_executable
+from distutils.dep_util import newer, newer_group
+from distutils.dir_util import copy_tree, remove_tree
+from distutils.file_util import copy_file
 import os
 import os.path
 import string
@@ -24,6 +27,153 @@
 
 def prefix(list, pref): return map(lambda x, p=pref: p + x, list)
 
+def find_file(paths, predicate):
+    """This function returns the found file (with path) or None if it
+    wasn't found"""
+    for path in paths:
+        matches = filter(predicate, glob.glob(path))
+        if matches:
+            return matches[0]
+    return None
+
+class qm_build_doc(build.build):
+    """This class compiles the QMTest's documentation."""
+
+    def call_jade(self, jade, args, dcl, type, src, builddir):
+        """The call_jade command compiles the output file from the
+        input files, using 'type' as the type attribute."""
+        cwd = os.getcwd()
+        # just to be sure this is still valid after chdir()
+        src = os.path.abspath(src)
+        builddir = os.path.join(self.build_temp, builddir)
+        self.mkpath(builddir)
+        # the stylesheet defines the output dir, which is identical
+        # to the last component in 'builddir'. So we move one level
+        # up
+        os.chdir(os.path.dirname(builddir))
+        cmd = [jade] + args + ['-t', type]
+        cmd += ['-d', os.path.join(cwd, 'doc', 'qm-%s.dsl'%type)]
+        if type == 'tex':
+            out = os.path.splitext(os.path.basename(src))[0] + '.tex'
+            cmd += ['-o', out]
+        cmd += [dcl]
+        cmd += [src]
+        spawn(cmd)
+
+        if (type == 'sgml'):
+            tidy = find_executable('tidy')
+            if tidy:
+                for f in glob.glob('html/*.html'):
+                    spawn([tidy, '-wrap', '72', '-i', '--indent-spaces', '1',
+                           '-f', '/dev/null', '-asxml', '-modify', f])
+        elif (type == 'tex'):
+            # We have to change -- into -{-} so that TeX does not generate long 
+            # dashes.  This is a bug in Jade.
+            self.spawn(['sh', '-c',
+                        'sed -e "s|--|-{-}|g" < manual.tex > print/manual.tex'])
+            os.remove('manual.tex')
+
+        os.chdir(cwd)
+
+    def run(self):
+
+        source_files = ['qm/test/doc/manual.xml',
+                        'qm/test/doc/introduction.xml',
+                        'qm/test/doc/tour.xml',
+                        'qm/test/doc/reference.xml']
+
+        jade = find_executable('jade')
+        dcl = find_file(['/usr/share/doc/jade*/pubtext/xml.dcl',
+                         '/usr/share/doc/openjade*/pubtext/xml.dcl',
+                         '/usr/doc/jade*/pubtext/xml.dcl',
+                         '/usr/share/sgml/declaration/xml.dcl'],
+                        os.path.isfile)
+
+        stylesheets = find_file(['/usr/lib/sgml/stylesheets/docbook',
+                                 '/usr/lib/sgml/stylesheets/dsssl/docbook',
+                                 '/usr/share/sgml/docbook/dsssl-stylesheets'],
+                                os.path.isdir)
+
+        dtd = find_file(['/usr/lib/sgml',
+                         '/usr/share/sgml/docbook'],
+                        os.path.isdir)
+
+        if not jade or not dcl or not stylesheets or not dtd:
+            self.announce("can't build documentation")
+            return
+
+        #
+        # build html output
+        #
+        self.announce("building html manual")
+        target = os.path.join(self.build_lib, 'qm/test/doc/html')
+        if newer_group(source_files, target):
+            # remove first such that its mtime reflects this build
+            if os.path.isdir(target): remove_tree(target)
+            self.call_jade(jade, ['-D%s'%dtd, '-D%s'%stylesheets],
+                           dcl, 'sgml',
+                           'qm/test/doc/manual.xml',
+                           'qm/test/doc/html')
+            if self.build_temp != self.build_lib:
+                src = os.path.join(self.build_temp, 'qm/test/doc/html')
+                dst = target
+                self.mkpath(dst)
+                copy_tree(src, dst, 1, 1, 0, 1, self.verbose, self.dry_run)
+
+        #
+        # build tex output
+        #
+        self.announce("building tex manual")
+        target = os.path.join(self.build_lib, 'qm/test/doc/print/manual.tex')
+        if newer_group(source_files, target):
+            # remove first such that its mtime reflects this build
+            if os.path.isfile(target): os.remove(target)
+            # build tex output
+            # Jade places the output TeX source file in the current directory,
+            # so move it where we want it afterwards.
+            self.call_jade(jade, ['-D%s'%dtd, '-D%s'%stylesheets],
+                           dcl, 'tex',
+                           'qm/test/doc/manual.xml',
+                           'qm/test/doc/print')
+
+            if self.build_temp != self.build_lib:
+                src = os.path.join(self.build_temp, 'qm/test/doc/print/manual.tex')
+                dst = target
+                self.mkpath(os.path.dirname(dst))
+                copy_file(src, target,
+                          1, 1, 1, None, self.verbose, self.dry_run)
+
+        #
+        # build pdf output
+        #
+        self.announce("building pdf manual")
+        target = os.path.join(self.build_lib, 'qm/test/doc/print/manual.pdf')
+        if newer_group(source_files, target):
+            # remove first such that its mtime reflects this build
+            if os.path.isfile(target): os.remove(target)
+            cwd = os.getcwd()
+            os.chdir(os.path.join(self.build_temp, 'qm/test/doc/print/'))
+            self.spawn(['pdfjadetex', 'manual.tex'])
+            self.spawn(['pdfjadetex', 'manual.tex'])
+            self.spawn(['pdfjadetex', 'manual.tex'])
+            os.chdir(cwd)
+            if self.build_temp != self.build_lib:
+                src = os.path.join(self.build_temp, 'qm/test/doc/print/manual.pdf')
+                dst = target
+                self.mkpath(os.path.dirname(dst))
+                copy_file(src, target,
+                          1, 1, 1, None, self.verbose, self.dry_run)
+
+        happydoc = find_executable('happydoc')
+        if (happydoc):
+            self.announce("building reference manual")
+            spawn(['happydoc', 'qm'])
+
+class qm_build(build.build):
+    """The qm_build class extends the build subcommands by 'qm_build_doc'."""
+
+    sub_commands = build.build.sub_commands[:] + [('build_doc', None)]
+
 class qm_install_data(install_data.install_data):
     """This class overrides the system install_data command. In addition
     to the original processing, a 'config' module is created that
@@ -63,7 +213,9 @@
 
 messages=['help.txt', 'diagnostics.txt']
 
-setup(cmdclass={'install_data': qm_install_data},
+setup(cmdclass={'build_doc': qm_build_doc,
+                'build': qm_build,
+                'install_data': qm_install_data},
       name="qm", 
       version="2.1",
       packages=packages,
