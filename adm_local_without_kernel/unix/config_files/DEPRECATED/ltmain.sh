# ltmain.sh - Provide generalized library-building support services.
# NOTE: Changing this file will not affect anything until you rerun ltconfig.
#
# Copyright (C) 1996-2014  CEA/DEN, EDF R&D, OPEN CASCADE
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
# See http://www.salome-platform.org/ or email : webmaster.salome@opencascade.com
#

# Check that we have a working $echo.
if test "X$1" = X--no-reexec; then
  # Discard the --no-reexec flag, and continue.
  shift
elif test "X$1" = X--fallback-echo; then
  # Avoid inline document here, it may be left over
  :
elif test "X`($echo '\t') 2>/dev/null`" = 'X\t'; then
  # Yippee, $echo works!
  :
else
  # Restart under the correct shell, and then maybe $echo will work.
  exec $SHELL "$0" --no-reexec ${1+"$@"}
fi

if test "X$1" = X--fallback-echo; then
  # used as fallback echo
  shift
  cat <<EOF
$*
EOF
  exit 0
fi

# The name of this program.
progname=`$echo "$0" | sed 's%^.*/%%'`
modename="$progname"

# Constants.
PROGRAM=ltmain.sh
PACKAGE=libtool
VERSION=1.3.5
TIMESTAMP=" (1.385.2.206 2000/05/27 11:12:27)"

default_mode=
help="Try \`$progname --help' for more information."
magic="%%%MAGIC variable%%%"
mkdir="mkdir"
mv="mv -f"
rm="rm -f"

# Sed substitution that helps us do robust quoting.  It backslashifies
# metacharacters that are still active within double-quoted strings.
Xsed='sed -e 1s/^X//'
sed_quote_subst='s/\([\\`\\"$\\\\]\)/\\\1/g'
SP2NL='tr \040 \012'
NL2SP='tr \015\012 \040\040'

# NLS nuisances.
# Only set LANG and LC_ALL to C if already set.
# These must not be set unconditionally because not all systems understand
# e.g. LANG=C (notably SCO).
# We save the old values to restore during execute mode.
if test "${LC_ALL+set}" = set; then
  save_LC_ALL="$LC_ALL"; LC_ALL=C; export LC_ALL
fi
if test "${LANG+set}" = set; then
  save_LANG="$LANG"; LANG=C; export LANG
fi

if test "$LTCONFIG_VERSION" != "$VERSION"; then
  echo "$modename: ltconfig version \`$LTCONFIG_VERSION' does not match $PROGRAM version \`$VERSION'" 1>&2
  echo "Fatal configuration error.  See the $PACKAGE docs for more information." 1>&2
  exit 1
fi

if test "$build_libtool_libs" != yes && test "$build_old_libs" != yes; then
  echo "$modename: not configured to build any kind of library" 1>&2
  echo "Fatal configuration error.  See the $PACKAGE docs for more information." 1>&2
  exit 1
fi

# Global variables.
mode=$default_mode
nonopt=
prev=
prevopt=
run=
show="$echo"
show_help=
execute_dlfiles=
lo2o="s/\\.lo\$/.${objext}/"
o2lo="s/\\.${objext}\$/.lo/"

# Parse our command line options once, thoroughly.
while test $# -gt 0
do
  arg="$1"
  shift

  case "$arg" in
  -*=*) optarg=`$echo "X$arg" | $Xsed -e 's/[-_a-zA-Z0-9]*=//'` ;;
  *) optarg= ;;
  esac

  # If the previous option needs an argument, assign it.
  if test -n "$prev"; then
    case "$prev" in
    execute_dlfiles)
      eval "$prev=\"\$$prev \$arg\""
      ;;
    *)
      eval "$prev=\$arg"
      ;;
    esac

    prev=
    prevopt=
    continue
  fi

  # Have we seen a non-optional argument yet?
  case "$arg" in
  --help)
    show_help=yes
    ;;

  --version)
    echo "$PROGRAM (GNU $PACKAGE) $VERSION$TIMESTAMP"
    exit 0
    ;;

  --config)
    sed -e '1,/^### BEGIN LIBTOOL CONFIG/d' -e '/^### END LIBTOOL CONFIG/,$d' $0
    exit 0
    ;;

  --debug)
    echo "$progname: enabling shell trace mode"
    set -x
    ;;

  --dry-run | -n)
    run=:
    ;;

  --features)
    echo "host: $host"
    if test "$build_libtool_libs" = yes; then
      echo "enable shared libraries"
    else
      echo "disable shared libraries"
    fi
    if test "$build_old_libs" = yes; then
      echo "enable static libraries"
    else
      echo "disable static libraries"
    fi
    exit 0
    ;;

  --finish) mode="finish" ;;

  --mode) prevopt="--mode" prev=mode ;;
  --mode=*) mode="$optarg" ;;

  --quiet | --silent)
    show=:
    ;;

  -dlopen)
    prevopt="-dlopen"
    prev=execute_dlfiles
    ;;

  -*)
    $echo "$modename: unrecognized option \`$arg'" 1>&2
    $echo "$help" 1>&2
    exit 1
    ;;

  *)
    nonopt="$arg"
    break
    ;;
  esac
done

if test -n "$prevopt"; then
  $echo "$modename: option \`$prevopt' requires an argument" 1>&2
  $echo "$help" 1>&2
  exit 1
fi

if test -z "$show_help"; then

  # Infer the operation mode.
  if test -z "$mode"; then
    case "$nonopt" in
    *cc | *++ | gcc* | *-gcc*)
      mode=link
      for arg
      do
	case "$arg" in
	-c)
	   mode=compile
	   break
	   ;;
	esac
      done
      ;;
    *db | *dbx | *strace | *truss)
      mode=execute
      ;;
    *install*|cp|mv)
      mode=install
      ;;
    *rm)
      mode=uninstall
      ;;
    *)
      # If we have no mode, but dlfiles were specified, then do execute mode.
      test -n "$execute_dlfiles" && mode=execute

      # Just use the default operation mode.
      if test -z "$mode"; then
	if test -n "$nonopt"; then
	  $echo "$modename: warning: cannot infer operation mode from \`$nonopt'" 1>&2
	else
	  $echo "$modename: warning: cannot infer operation mode without MODE-ARGS" 1>&2
	fi
      fi
      ;;
    esac
  fi

  # Only execute mode is allowed to have -dlopen flags.
  if test -n "$execute_dlfiles" && test "$mode" != execute; then
    $echo "$modename: unrecognized option \`-dlopen'" 1>&2
    $echo "$help" 1>&2
    exit 1
  fi

  # Change the help message to a mode-specific one.
  generic_help="$help"
  help="Try \`$modename --help --mode=$mode' for more information."

  # These modes are in order of execution frequency so that they run quickly.
  case "$mode" in
  # libtool compile mode
  compile)
    modename="$modename: compile"
    # Get the compilation command and the source file.
    base_compile=
    lastarg=
    srcfile="$nonopt"
    suppress_output=

    user_target=no
    for arg
    do
      # Accept any command-line options.
      case "$arg" in
      -o)
	if test "$user_target" != "no"; then
	  $echo "$modename: you cannot specify \`-o' more than once" 1>&2
	  exit 1
	fi
	user_target=next
	;;

      -static)
	build_old_libs=yes
	continue
	;;
      esac

      case "$user_target" in
      next)
	# The next one is the -o target name
	user_target=yes
	continue
	;;
      yes)
	# We got the output file
	user_target=set
	libobj="$arg"
	continue
	;;
      esac

      # Accept the current argument as the source file.
      lastarg="$srcfile"
      srcfile="$arg"

      # Aesthetically quote the previous argument.

      # Backslashify any backslashes, double quotes, and dollar signs.
      # These are the only characters that are still specially
      # interpreted inside of double-quoted scrings.
      lastarg=`$echo "X$lastarg" | $Xsed -e "$sed_quote_subst"`

      # Double-quote args containing other shell metacharacters.
      # Many Bourne shells cannot handle close brackets correctly in scan
      # sets, so we specify it separately.
      case "$lastarg" in
      *[\[\~\#\^\&\*\(\)\{\}\|\;\<\>\?\'\ \	]*|*]*)
	lastarg="\"$lastarg\""
	;;
      esac

      # Add the previous argument to base_compile.
      if test -z "$base_compile"; then
	base_compile="$lastarg"
      else
	base_compile="$base_compile $lastarg"
      fi
    done

    case "$user_target" in
    set)
      ;;
    no)
      # Get the name of the library object.
      libobj=`$echo "X$srcfile" | $Xsed -e 's%^.*/%%'`
      ;;
    *)
      $echo "$modename: you must specify a target with \`-o'" 1>&2
      exit 1
      ;;
    esac

    # Recognize several different file suffixes.
    # If the user specifies -o file.o, it is replaced with file.lo
    xform='[cCFSfmso]'
    case "$libobj" in
    *.ada) xform=ada ;;
    *.adb) xform=adb ;;
    *.ads) xform=ads ;;
    *.asm) xform=asm ;;
    *.c++) xform=c++ ;;
    *.cc) xform=cc ;;
    *.cpp) xform=cpp ;;
    *.cxx) xform=cxx ;;
    *.f90) xform=f90 ;;
    *.for) xform=for ;;
    esac

    libobj=`$echo "X$libobj" | $Xsed -e "s/\.$xform$/.lo/"`

    case "$libobj" in
    *.lo) obj=`$echo "X$libobj" | $Xsed -e "$lo2o"` ;;
    *)
      $echo "$modename: cannot determine name of library object from \`$libobj'" 1>&2
      exit 1
      ;;
    esac

    if test -z "$base_compile"; then
      $echo "$modename: you must specify a compilation command" 1>&2
      $echo "$help" 1>&2
      exit 1
    fi

    # Delete any leftover library objects.
    if test "$build_old_libs" = yes; then
      removelist="$obj $libobj"
    else
      removelist="$libobj"
    fi

    $run $rm $removelist
    trap "$run $rm $removelist; exit 1" 1 2 15

    # Calculate the filename of the output object if compiler does
    # not support -o with -c
    if test "$compiler_c_o" = no; then
      output_obj=`$echo "X$srcfile" | $Xsed -e 's%^.*/%%' -e 's%\..*$%%'`.${objext}
      lockfile="$output_obj.lock"
      removelist="$removelist $output_obj $lockfile"
      trap "$run $rm $removelist; exit 1" 1 2 15
    else
      need_locks=no
      lockfile=
    fi

    # Lock this critical section if it is needed
    # We use this script file to make the link, it avoids creating a new file
    if test "$need_locks" = yes; then
      until ln "$0" "$lockfile" 2>/dev/null; do
	$show "Waiting for $lockfile to be removed"
	sleep 2
      done
    elif test "$need_locks" = warn; then
      if test -f "$lockfile"; then
	echo "\
*** ERROR, $lockfile exists and contains:
`cat $lockfile 2>/dev/null`

This indicates that another process is trying to use the same
temporary object file, and libtool could not work around it because
your compiler does not support \`-c' and \`-o' together.  If you
repeat this compilation, it may succeed, by chance, but you had better
avoid parallel builds (make -j) in this platform, or get a better
compiler."

	$run $rm $removelist
	exit 1
      fi
      echo $srcfile > "$lockfile"
    fi

    if test -n "$fix_srcfile_path"; then
      eval srcfile=\"$fix_srcfile_path\"
    fi

    # Only build a PIC object if we are building libtool libraries.
    if test "$build_libtool_libs" = yes; then
      # Without this assignment, base_compile gets emptied.
      fbsd_hideous_sh_bug=$base_compile

      # All platforms use -DPIC, to notify preprocessed assembler code.
      command="$base_compile $srcfile $pic_flag -DPIC"
      if test "$build_old_libs" = yes; then
	lo_libobj="$libobj"
	dir=`$echo "X$libobj" | $Xsed -e 's%/[^/]*$%%'`
	if test "X$dir" = "X$libobj"; then
	  dir="$objdir"
	else
	  dir="$dir/$objdir"
	fi
	libobj="$dir/"`$echo "X$libobj" | $Xsed -e 's%^.*/%%'`

	if test -d "$dir"; then
	  $show "$rm $libobj"
	  $run $rm $libobj
	else
	  $show "$mkdir $dir"
	  $run $mkdir $dir
	  status=$?
	  if test $status -ne 0 && test ! -d $dir; then
	    exit $status
	  fi
	fi
      fi
      if test "$compiler_o_lo" = yes; then
	output_obj="$libobj"
	command="$command -o $output_obj"
      elif test "$compiler_c_o" = yes; then
	output_obj="$obj"
	command="$command -o $output_obj"
      fi

      $run $rm "$output_obj"
      $show "$command"
      if $run eval "$command"; then :
      else
	test -n "$output_obj" && $run $rm $removelist
	exit 1
      fi

      if test "$need_locks" = warn &&
	 test x"`cat $lockfile 2>/dev/null`" != x"$srcfile"; then
	echo "\
*** ERROR, $lockfile contains:
`cat $lockfile 2>/dev/null`

but it should contain:
$srcfile

This indicates that another process is trying to use the same
temporary object file, and libtool could not work around it because
your compiler does not support \`-c' and \`-o' together.  If you
repeat this compilation, it may succeed, by chance, but you had better
avoid parallel builds (make -j) in this platform, or get a better
compiler."

	$run $rm $removelist
	exit 1
      fi

      # Just move the object if needed, then go on to compile the next one
      if test x"$output_obj" != x"$libobj"; then
	$show "$mv $output_obj $libobj"
	if $run $mv $output_obj $libobj; then :
	else
	  error=$?
	  $run $rm $removelist
	  exit $error
	fi
      fi

      # If we have no pic_flag, then copy the object into place and finish.
      if test -z "$pic_flag" && test "$build_old_libs" = yes; then
	# Rename the .lo from within objdir to obj
	if test -f $obj; then
	  $show $rm $obj
	  $run $rm $obj
	fi

	$show "$mv $libobj $obj"
	if $run $mv $libobj $obj; then :
	else
	  error=$?
	  $run $rm $removelist
	  exit $error
	fi

	xdir=`$echo "X$obj" | $Xsed -e 's%/[^/]*$%%'`
	if test "X$xdir" = "X$obj"; then
	  xdir="."
	else
	  xdir="$xdir"
	fi
	baseobj=`$echo "X$obj" | $Xsed -e "s%.*/%%"`
	libobj=`$echo "X$baseobj" | $Xsed -e "$o2lo"`
	# Now arrange that obj and lo_libobj become the same file
	$show "(cd $xdir && $LN_S $baseobj $libobj)"
	if $run eval '(cd $xdir && $LN_S $baseobj $libobj)'; then
	  exit 0
	else
	  error=$?
	  $run $rm $removelist
	  exit $error
	fi
      fi

      # Allow error messages only from the first compilation.
      suppress_output=' >/dev/null 2>&1'
    fi

    # Only build a position-dependent object if we build old libraries.
    if test "$build_old_libs" = yes; then
      command="$base_compile $srcfile"
      if test "$compiler_c_o" = yes; then
	command="$command -o $obj"
	output_obj="$obj"
      fi

      # Suppress compiler output if we already did a PIC compilation.
      command="$command$suppress_output"
      $run $rm "$output_obj"
      $show "$command"
      if $run eval "$command"; then :
      else
	$run $rm $removelist
	exit 1
      fi

      if test "$need_locks" = warn &&
	 test x"`cat $lockfile 2>/dev/null`" != x"$srcfile"; then
	echo "\
*** ERROR, $lockfile contains:
`cat $lockfile 2>/dev/null`

but it should contain:
$srcfile

This indicates that another process is trying to use the same
temporary object file, and libtool could not work around it because
your compiler does not support \`-c' and \`-o' together.  If you
repeat this compilation, it may succeed, by chance, but you had better
avoid parallel builds (make -j) in this platform, or get a better
compiler."

	$run $rm $removelist
	exit 1
      fi

      # Just move the object if needed
      if test x"$output_obj" != x"$obj"; then
	$show "$mv $output_obj $obj"
	if $run $mv $output_obj $obj; then :
	else
	  error=$?
	  $run $rm $removelist
	  exit $error
	fi
      fi

      # Create an invalid libtool object if no PIC, so that we do not
      # accidentally link it into a program.
      if test "$build_libtool_libs" != yes; then
	$show "echo timestamp > $libobj"
	$run eval "echo timestamp > \$libobj" || exit $?
      else
	# Move the .lo from within objdir
	$show "$mv $libobj $lo_libobj"
	if $run $mv $libobj $lo_libobj; then :
	else
	  error=$?
	  $run $rm $removelist
	  exit $error
	fi
      fi
    fi

    # Unlock the critical section if it was locked
    if test "$need_locks" != no; then
      $rm "$lockfile"
    fi

    exit 0
    ;;

  # libtool link mode
  link)
    modename="$modename: link"
    case "$host" in
    *-*-cygwin* | *-*-mingw* | *-*-os2*)
      # It is impossible to link a dll without this setting, and
      # we shouldn't force the makefile maintainer to figure out
      # which system we are compiling for in order to pass an extra
      # flag for every libtool invokation.
      # allow_undefined=no

      # FIXME: Unfortunately, there are problems with the above when trying
      # to make a dll which has undefined symbols, in which case not
      # even a static library is built.  For now, we need to specify
      # -no-undefined on the libtool link line when we can be certain
      # that all symbols are satisfied, otherwise we get a static library.
      allow_undefined=yes

      # This is a source program that is used to create dlls on Windows
      # Don't remove nor modify the starting and closing comments
# /* ltdll.c starts here */
# #define WIN32_LEAN_AND_MEAN
# #include <windows.h>
# #undef WIN32_LEAN_AND_MEAN
# #include <stdio.h>
#
# #ifndef __CYGWIN__
# #  ifdef __CYGWIN32__
# #    define __CYGWIN__ __CYGWIN32__
# #  endif
# #endif
#
# #ifdef __cplusplus
# extern "C" {
# #endif
# BOOL APIENTRY DllMain (HINSTANCE hInst, DWORD reason, LPVOID reserved);
# #ifdef __cplusplus
# }
# #endif
#
# #ifdef __CYGWIN__
# #include <cygwin/cygwin_dll.h>
# DECLARE_CYGWIN_DLL( DllMain );
# #endif
# HINSTANCE __hDllInstance_base;
#
# BOOL APIENTRY
# DllMain (HINSTANCE hInst, DWORD reason, LPVOID reserved)
# {
#   __hDllInstance_base = hInst;
#   return TRUE;
# }
# /* ltdll.c ends here */
      # This is a source program that is used to create import libraries
      # on Windows for dlls which lack them. Don't remove nor modify the
      # starting and closing comments
# /* impgen.c starts here */
# /*   Copyright (C) 1999 Free Software Foundation, Inc.
# 
#  This file is part of GNU libtool.
# 
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
# 
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#  */
# 
#  #include <stdio.h>		/* for printf() */
#  #include <unistd.h>		/* for open(), lseek(), read() */
#  #include <fcntl.h>		/* for O_RDONLY, O_BINARY */
#  #include <string.h>		/* for strdup() */
# 
#  static unsigned int
#  pe_get16 (fd, offset)
#       int fd;
#       int offset;
#  {
#    unsigned char b[2];
#    lseek (fd, offset, SEEK_SET);
#    read (fd, b, 2);
#    return b[0] + (b[1]<<8);
#  }
# 
#  static unsigned int
#  pe_get32 (fd, offset)
#      int fd;
#      int offset;
#  {
#    unsigned char b[4];
#    lseek (fd, offset, SEEK_SET);
#    read (fd, b, 4);
#    return b[0] + (b[1]<<8) + (b[2]<<16) + (b[3]<<24);
#  }
# 
#  static unsigned int
#  pe_as32 (ptr)
#       void *ptr;
#  {
#    unsigned char *b = ptr;
#    return b[0] + (b[1]<<8) + (b[2]<<16) + (b[3]<<24);
#  }
# 
#  int
#  main (argc, argv)
#      int argc;
#      char *argv[];
#  {
#      int dll;
#      unsigned long pe_header_offset, opthdr_ofs, num_entries, i;
#      unsigned long export_rva, export_size, nsections, secptr, expptr;
#      unsigned long name_rvas, nexp;
#      unsigned char *expdata, *erva;
#      char *filename, *dll_name;
# 
#      filename = argv[1];
# 
#      dll = open(filename, O_RDONLY|O_BINARY);
#      if (!dll)
#  	return 1;
# 
#      dll_name = filename;
#    
#      for (i=0; filename[i]; i++)
#  	if (filename[i] == '/' || filename[i] == '\\'  || filename[i] == ':')
#  	    dll_name = filename + i +1;
# 
#      pe_header_offset = pe_get32 (dll, 0x3c);
#      opthdr_ofs = pe_header_offset + 4 + 20;
#      num_entries = pe_get32 (dll, opthdr_ofs + 92);
# 
#      if (num_entries < 1) /* no exports */
#  	return 1;
# 
#      export_rva = pe_get32 (dll, opthdr_ofs + 96);
#      export_size = pe_get32 (dll, opthdr_ofs + 100);
#      nsections = pe_get16 (dll, pe_header_offset + 4 +2);
#      secptr = (pe_header_offset + 4 + 20 +
#  	      pe_get16 (dll, pe_header_offset + 4 + 16));
# 
#      expptr = 0;
#      for (i = 0; i < nsections; i++)
#      {
#  	char sname[8];
#  	unsigned long secptr1 = secptr + 40 * i;
#  	unsigned long vaddr = pe_get32 (dll, secptr1 + 12);
#  	unsigned long vsize = pe_get32 (dll, secptr1 + 16);
#  	unsigned long fptr = pe_get32 (dll, secptr1 + 20);
#  	lseek(dll, secptr1, SEEK_SET);
#  	read(dll, sname, 8);
#  	if (vaddr <= export_rva && vaddr+vsize > export_rva)
#  	{
#  	    expptr = fptr + (export_rva - vaddr);
#  	    if (export_rva + export_size > vaddr + vsize)
#  		export_size = vsize - (export_rva - vaddr);
#  	    break;
#  	}
#      }
# 
#      expdata = (unsigned char*)malloc(export_size);
#      lseek (dll, expptr, SEEK_SET);
#      read (dll, expdata, export_size);
#      erva = expdata - export_rva;
# 
#      nexp = pe_as32 (expdata+24);
#      name_rvas = pe_as32 (expdata+32);
# 
#      printf ("EXPORTS\n");
#      for (i = 0; i<nexp; i++)
#      {
#  	unsigned long name_rva = pe_as32 (erva+name_rvas+i*4);
#  	printf ("\t%s @ %ld ;\n", erva+name_rva, 1+ i);
#      }
# 
#      return 0;
#  }
# /* impgen.c ends here */
      ;;
    *)
      allow_undefined=yes
      ;;
    esac
    compile_command="$nonopt"
    finalize_command="$nonopt"

    compile_rpath=
    finalize_rpath=
    compile_shlibpath=
    finalize_shlibpath=
    convenience=
    old_convenience=
    deplibs=
    linkopts=

    if test -n "$shlibpath_var"; then
      # get the directories listed in $shlibpath_var
      eval lib_search_path=\`\$echo \"X \${$shlibpath_var}\" \| \$Xsed -e \'s/:/ /g\'\`
    else
      lib_search_path=
    fi
    # now prepend the system-specific ones
    eval lib_search_path=\"$sys_lib_search_path_spec\$lib_search_path\"
    eval sys_lib_dlsearch_path=\"$sys_lib_dlsearch_path_spec\"
    
    avoid_version=no
    dlfiles=
    dlprefiles=
    dlself=no
    export_dynamic=no
    export_symbols=
    export_symbols_regex=
    generated=
    libobjs=
    link_against_libtool_libs=
    ltlibs=
    module=no
    objs=
    prefer_static_libs=no
    preload=no
    prev=
    prevarg=
    release=
    rpath=
    xrpath=
    perm_rpath=
    temp_rpath=
    thread_safe=no
    vinfo=

    # We need to know -static, to get the right output filenames.
    for arg
    do
      case "$arg" in
      -all-static | -static)
	if test "X$arg" = "X-all-static"; then
	  if test "$build_libtool_libs" = yes && test -z "$link_static_flag"; then
	    $echo "$modename: warning: complete static linking is impossible in this configuration" 1>&2
	  fi
	  if test -n "$link_static_flag"; then
	    dlopen_self=$dlopen_self_static
	  fi
	else
	  if test -z "$pic_flag" && test -n "$link_static_flag"; then
	    dlopen_self=$dlopen_self_static
	  fi
	fi
	build_libtool_libs=no
	build_old_libs=yes
	prefer_static_libs=yes
	break
	;;
      esac
    done

    # See if our shared archives depend on static archives.
    test -n "$old_archive_from_new_cmds" && build_old_libs=yes

    # Go through the arguments, transforming them on the way.
    while test $# -gt 0; do
      arg="$1"
      shift

      # If the previous option needs an argument, assign it.
      if test -n "$prev"; then
	case "$prev" in
	output)
	  compile_command="$compile_command @OUTPUT@"
	  finalize_command="$finalize_command @OUTPUT@"
	  ;;
	esac

	case "$prev" in
	dlfiles|dlprefiles)
	  if test "$preload" = no; then
	    # Add the symbol object into the linking commands.
	    compile_command="$compile_command @SYMFILE@"
	    finalize_command="$finalize_command @SYMFILE@"
	    preload=yes
	  fi
	  case "$arg" in
	  *.la | *.lo) ;;  # We handle these cases below.
	  force)
	    if test "$dlself" = no; then
	      dlself=needless
	      export_dynamic=yes
	    fi
	    prev=
	    continue
	    ;;
	  self)
	    if test "$prev" = dlprefiles; then
	      dlself=yes
	    elif test "$prev" = dlfiles && test "$dlopen_self" != yes; then
	      dlself=yes
	    else
	      dlself=needless
	      export_dynamic=yes
	    fi
	    prev=
	    continue
	    ;;
	  *)
	    if test "$prev" = dlfiles; then
	      dlfiles="$dlfiles $arg"
	    else
	      dlprefiles="$dlprefiles $arg"
	    fi
	    prev=
	    ;;
	  esac
	  ;;
	expsyms)
	  export_symbols="$arg"
	  if test ! -f "$arg"; then
	    $echo "$modename: symbol file \`$arg' does not exist"
	    exit 1
	  fi
	  prev=
	  continue
	  ;;
	expsyms_regex)
	  export_symbols_regex="$arg"
	  prev=
	  continue
	  ;;
	release)
	  release="-$arg"
	  prev=
	  continue
	  ;;
	rpath | xrpath)
	  # We need an absolute path.
	  case "$arg" in
	  [\\/]* | [A-Za-z]:[\\/]*) ;;
	  *)
	    $echo "$modename: only absolute run-paths are allowed" 1>&2
	    exit 1
	    ;;
	  esac
	  if test "$prev" = rpath; then
	    case "$rpath " in
	    *" $arg "*) ;;
	    *) rpath="$rpath $arg" ;;
	    esac
	  else
	    case "$xrpath " in
	    *" $arg "*) ;;
	    *) xrpath="$xrpath $arg" ;;
	    esac
	  fi
	  prev=
	  continue
	  ;;
	*)
	  eval "$prev=\"\$arg\""
	  prev=
	  continue
	  ;;
	esac
      fi

      prevarg="$arg"

      case "$arg" in
      -all-static)
	if test -n "$link_static_flag"; then
	  compile_command="$compile_command $link_static_flag"
	  finalize_command="$finalize_command $link_static_flag"
	fi
	continue
	;;

      -allow-undefined)
	# FIXME: remove this flag sometime in the future.
	$echo "$modename: \`-allow-undefined' is deprecated because it is the default" 1>&2
	continue
	;;

      -avoid-version)
	avoid_version=yes
	continue
	;;

      -dlopen)
	prev=dlfiles
	continue
	;;

      -dlpreopen)
	prev=dlprefiles
	continue
	;;

      -export-dynamic)
	export_dynamic=yes
	continue
	;;

      -export-symbols | -export-symbols-regex)
	if test -n "$export_symbols" || test -n "$export_symbols_regex"; then
	  $echo "$modename: not more than one -exported-symbols argument allowed"
	  exit 1
	fi
	if test "X$arg" = "X-export-symbols"; then
	  prev=expsyms
	else
	  prev=expsyms_regex
	fi
	continue
	;;

      -L*)
	dir=`$echo "X$arg" | $Xsed -e 's/^-L//'`
	# We need an absolute path.
	case "$dir" in
	[\\/]* | [A-Za-z]:[\\/]*) ;;
	*)
	  absdir=`cd "$dir" && pwd`
	  if test -z "$absdir"; then
	    $echo "$modename: warning: cannot determine absolute directory name of \`$dir'" 1>&2
	    $echo "$modename: passing it literally to the linker, although it might fail" 1>&2
	    absdir="$dir"
	  fi
	  dir="$absdir"
	  ;;
	esac
	case " $deplibs " in
	*" $arg "*) ;;
	*) deplibs="$deplibs $arg";;
	esac
	case " $lib_search_path " in
	*" $dir "*) ;;
	*) lib_search_path="$lib_search_path $dir";;
	esac
	case "$host" in
	*-*-cygwin* | *-*-mingw* | *-*-os2*)
	  dllsearchdir=`cd "$dir" && pwd || echo "$dir"`
	  case ":$dllsearchpath:" in
	  ::) dllsearchpath="$dllsearchdir";;
	  *":$dllsearchdir:"*) ;;
	  *) dllsearchpath="$dllsearchpath:$dllsearchdir";;
	  esac
	  ;;
	esac
	;;

      -l*)
	if test "$arg" = "-lc"; then
	  case "$host" in
	  *-*-cygwin* | *-*-mingw* | *-*-os2* | *-*-beos*)
	    # These systems don't actually have c library (as such)
	    continue
	    ;;
	  esac
	elif test "$arg" = "-lm"; then
	  case "$host" in
	  *-*-cygwin* | *-*-beos*)
	    # These systems don't actually have math library (as such)
	    continue
	    ;;
	  esac
	fi
	deplibs="$deplibs $arg"
	;;

      -module)
	module=yes
	continue
	;;

      -no-undefined)
	allow_undefined=no
	continue
	;;

      -o) prev=output ;;

      -release)
	prev=release
	continue
	;;

      -rpath)
	prev=rpath
	continue
	;;

      -R)
	prev=xrpath
	continue
	;;

      -R*)
	dir=`$echo "X$arg" | $Xsed -e 's/^-R//'`
	# We need an absolute path.
	case "$dir" in
	[\\/]* | [A-Za-z]:[\\/]*) ;;
	*)
	  $echo "$modename: only absolute run-paths are allowed" 1>&2
	  exit 1
	  ;;
	esac
	case "$xrpath " in
	*" $dir "*) ;;
	*) xrpath="$xrpath $dir" ;;
	esac
	continue
	;;

      -static)
	# If we have no pic_flag, then this is the same as -all-static.
	if test -z "$pic_flag" && test -n "$link_static_flag"; then
	  compile_command="$compile_command $link_static_flag"
	  finalize_command="$finalize_command $link_static_flag"
	fi
	continue
	;;

      -thread-safe)
	thread_safe=yes
	continue
	;;

      -version-info)
	prev=vinfo
	continue
	;;

      # Some other compiler flag.
      -* | +*)
	# Unknown arguments in both finalize_command and compile_command need
	# to be aesthetically quoted because they are evaled later.
	arg=`$echo "X$arg" | $Xsed -e "$sed_quote_subst"`
	case "$arg" in
	*[\[\~\#\^\&\*\(\)\{\}\|\;\<\>\?\'\ \	]*|*]*)
	  arg="\"$arg\""
	  ;;
	esac
	;;

      *.o | *.obj | *.a | *.lib)
	# A standard object.
	objs="$objs $arg"
	;;

      *.lo)
	# A library object.
	if test "$prev" = dlfiles; then
	  dlfiles="$dlfiles $arg"
	  if test "$build_libtool_libs" = yes && test "$dlopen" = yes; then
	    prev=
	    continue
	  else
	    # If libtool objects are unsupported, then we need to preload.
	    prev=dlprefiles
	  fi
	fi

	if test "$prev" = dlprefiles; then
	  # Preload the old-style object.
	  dlprefiles="$dlprefiles "`$echo "X$arg" | $Xsed -e "$lo2o"`
	  prev=
	fi
	libobjs="$libobjs $arg"
	;;

      *.la)
	# A libtool-controlled library.

	dlname=
	libdir=
	library_names=
	old_library=

	# Check to see that this really is a libtool archive.
	if (sed -e '2q' $arg | egrep "^# Generated by .*$PACKAGE") >/dev/null 2>&1; then :
	else
	  $echo "$modename: \`$arg' is not a valid libtool archive" 1>&2
	  exit 1
	fi

	# If the library was installed with an old release of libtool,
	# it will not redefine variable installed.
	installed=yes

	# Read the .la file
	# If there is no directory component, then add one.
	case "$arg" in
	*/* | *\\*) . $arg ;;
	*) . ./$arg ;;
	esac

	# Get the name of the library we link against.
	linklib=
	for l in $old_library $library_names; do
	  linklib="$l"
	done

	if test -z "$linklib"; then
	  $echo "$modename: cannot find name of link library for \`$arg'" 1>&2
	  exit 1
	fi

	# Find the relevant object directory and library name.
	name=`$echo "X$arg" | $Xsed -e 's%^.*/%%' -e 's/\.la$//' -e 's/^lib//'`

	if test "X$installed" = Xyes; then
	  dir="$libdir"
	else
	  dir=`$echo "X$arg" | $Xsed -e 's%/[^/]*$%%'`
	  if test "X$dir" = "X$arg"; then
	    dir="$objdir"
	  else
	    dir="$dir/$objdir"
	  fi
	fi

	if test -n "$dependency_libs"; then
	  # Extract -R and -L from dependency_libs
	  temp_deplibs=
	  for deplib in $dependency_libs; do
	    case "$deplib" in
	    -R*) temp_xrpath=`$echo "X$deplib" | $Xsed -e 's/^-R//'`
		 case " $rpath $xrpath " in
		 *" $temp_xrpath "*) ;;
		 *) xrpath="$xrpath $temp_xrpath";;
		 esac;;
	    -L*) case "$compile_command $temp_deplibs " in
		 *" $deplib "*) ;;
		 *) temp_deplibs="$temp_deplibs $deplib";;
		 esac
		 temp_dir=`$echo "X$deplib" | $Xsed -e 's/^-L//'`
		 case " $lib_search_path " in
		 *" $temp_dir "*) ;;
		 *) lib_search_path="$lib_search_path $temp_dir";;
		 esac
		 ;;
	    *) temp_deplibs="$temp_deplibs $deplib";;
	    esac
	  done
	  dependency_libs="$temp_deplibs"
	fi

	if test -z "$libdir"; then
	  # It is a libtool convenience library, so add in its objects.
	  convenience="$convenience $dir/$old_library"
	  old_convenience="$old_convenience $dir/$old_library"
	  deplibs="$deplibs$dependency_libs"
	  compile_command="$compile_command $dir/$old_library$dependency_libs"
	  finalize_command="$finalize_command $dir/$old_library$dependency_libs"
	  continue
	fi

	# This library was specified with -dlopen.
	if test "$prev" = dlfiles; then
	  dlfiles="$dlfiles $arg"
	  if test -z "$dlname" || test "$dlopen" != yes || test "$build_libtool_libs" = no; then
	    # If there is no dlname, no dlopen support or we're linking statically,
	    # we need to preload.
	    prev=dlprefiles
	  else
	    # We should not create a dependency on this library, but we
	    # may need any libraries it requires.
	    compile_command="$compile_command$dependency_libs"
	    finalize_command="$finalize_command$dependency_libs"
	    prev=
	    continue
	  fi
	fi

	# The library was specified with -dlpreopen.
	if test "$prev" = dlprefiles; then
	  # Prefer using a static library (so that no silly _DYNAMIC symbols
	  # are required to link).
	  if test -n "$old_library"; then
	    dlprefiles="$dlprefiles $dir/$old_library"
	  else
	    dlprefiles="$dlprefiles $dir/$linklib"
	  fi
	  prev=
	fi

	if test -n "$library_names" &&
	   { test "$prefer_static_libs" = no || test -z "$old_library"; }; then
	  link_against_libtool_libs="$link_against_libtool_libs $arg"
	  if test -n "$shlibpath_var"; then
	    # Make sure the rpath contains only unique directories.
	    case "$temp_rpath " in
	    *" $dir "*) ;;
	    *) temp_rpath="$temp_rpath $dir" ;;
	    esac
	  fi

	  # We need an absolute path.
	  case "$dir" in
	  [\\/] | [A-Za-z]:[\\/]*) absdir="$dir" ;;
	  *)
	    absdir=`cd "$dir" && pwd`
	    if test -z "$absdir"; then
	      $echo "$modename: warning: cannot determine absolute directory name of \`$dir'" 1>&2
	      $echo "$modename: passing it literally to the linker, although it might fail" 1>&2
	      absdir="$dir"
	    fi
	    ;;
	  esac
	  
	  # This is the magic to use -rpath.
	  # Skip directories that are in the system default run-time
	  # search path, unless they have been requested with -R.
	  case " $sys_lib_dlsearch_path " in
	  *" $absdir "*) ;;
	  *)
	    case "$compile_rpath " in
	    *" $absdir "*) ;;
	    *) compile_rpath="$compile_rpath $absdir" 
	    esac
	    ;;
	  esac

	  case " $sys_lib_dlsearch_path " in
	  *" $libdir "*) ;;
	  *)
	    case "$finalize_rpath " in
	    *" $libdir "*) ;;
	    *) finalize_rpath="$finalize_rpath $libdir"
	    esac
	    ;;
	  esac

	  lib_linked=yes
	  case "$hardcode_action" in
	  immediate | unsupported)
	    if test "$hardcode_direct" = no; then
	      compile_command="$compile_command $dir/$linklib"
	      deplibs="$deplibs $dir/$linklib"
	      case "$host" in
	      *-*-cygwin* | *-*-mingw* | *-*-os2*)
		dllsearchdir=`cd "$dir" && pwd || echo "$dir"`
		if test -n "$dllsearchpath"; then
		  dllsearchpath="$dllsearchpath:$dllsearchdir"
		else
		  dllsearchpath="$dllsearchdir"
		fi
		;;
	      esac
	    elif test "$hardcode_minus_L" = no; then
	      case "$host" in
	      *-*-sunos*)
		compile_shlibpath="$compile_shlibpath$dir:"
		;;
	      esac
	      case "$compile_command " in
	      *" -L$dir "*) ;;
	      *) compile_command="$compile_command -L$dir";;
	      esac
	      compile_command="$compile_command -l$name"
	      deplibs="$deplibs -L$dir -l$name"
	    elif test "$hardcode_shlibpath_var" = no; then
	      case ":$compile_shlibpath:" in
	      *":$dir:"*) ;;
	      *) compile_shlibpath="$compile_shlibpath$dir:";;
	      esac
	      compile_command="$compile_command -l$name"
	      deplibs="$deplibs -l$name"
	    else
	      lib_linked=no
	    fi
	    ;;

	  relink)
	    if test "$hardcode_direct" = yes; then
	      compile_command="$compile_command $absdir/$linklib"
	      deplibs="$deplibs $absdir/$linklib"
	    elif test "$hardcode_minus_L" = yes; then
	      case "$compile_command " in
	      *" -L$absdir "*) ;;
	      *) compile_command="$compile_command -L$absdir";;
	      esac
	      compile_command="$compile_command -l$name"
	      deplibs="$deplibs -L$absdir -l$name"
	    elif test "$hardcode_shlibpath_var" = yes; then
	      case ":$compile_shlibpath:" in
	      *":$absdir:"*) ;;
	      *) compile_shlibpath="$compile_shlibpath$absdir:";;
	      esac
	      compile_command="$compile_command -l$name"
	      deplibs="$deplibs -l$name"
	    else
	      lib_linked=no
	    fi
	    ;;

	  *)
	    lib_linked=no
	    ;;
	  esac

	  if test "$lib_linked" != yes; then
	    $echo "$modename: configuration error: unsupported hardcode properties"
	    exit 1
	  fi

	  # Finalize command for both is simple: just hardcode it.
	  if test "$hardcode_direct" = yes; then
	    finalize_command="$finalize_command $libdir/$linklib"
	  elif test "$hardcode_minus_L" = yes; then
	    case "$finalize_command " in
	    *" -L$libdir "*) ;;
	    *) finalize_command="$finalize_command -L$libdir";;
	    esac
	    finalize_command="$finalize_command -l$name"
	  elif test "$hardcode_shlibpath_var" = yes; then
	    case ":$finalize_shlibpath:" in
	    *":$libdir:"*) ;;
	    *) finalize_shlibpath="$finalize_shlibpath$libdir:";;
	    esac
	    finalize_command="$finalize_command -l$name"
	  else
	    # We cannot seem to hardcode it, guess we'll fake it.
	    case "$finalize_command " in
	    *" -L$dir "*) ;;
	    *) finalize_command="$finalize_command -L$libdir";;
	    esac
	    finalize_command="$finalize_command -l$name"
	  fi
	else
	  # Transform directly to old archives if we don't build new libraries.
	  if test -n "$pic_flag" && test -z "$old_library"; then
	    $echo "$modename: cannot find static library for \`$arg'" 1>&2
	    exit 1
	  fi

	  # Here we assume that one of hardcode_direct or hardcode_minus_L
	  # is not unsupported.  This is valid on all known static and
	  # shared platforms.
	  if test "$hardcode_direct" != unsupported; then
	    test -n "$old_library" && linklib="$old_library"
	    compile_command="$compile_command $dir/$linklib"
	    finalize_command="$finalize_command $dir/$linklib"
	  else
	    case "$compile_command " in
	    *" -L$dir "*) ;;
	    *) compile_command="$compile_command -L$dir";;
	    esac
	    compile_command="$compile_command -l$name"
	    case "$finalize_command " in
	    *" -L$dir "*) ;;
	    *) finalize_command="$finalize_command -L$dir";;
	    esac
	    finalize_command="$finalize_command -l$name"
	  fi
	fi

	# Add in any libraries that this one depends upon.
	compile_command="$compile_command$dependency_libs"
	finalize_command="$finalize_command$dependency_libs"
	continue
	;;

      # Some other compiler argument.
      *)
	# Unknown arguments in both finalize_command and compile_command need
	# to be aesthetically quoted because they are evaled later.
	arg=`$echo "X$arg" | $Xsed -e "$sed_quote_subst"`
	case "$arg" in
	*[\[\~\#\^\&\*\(\)\{\}\|\;\<\>\?\'\ \	]*|*]*)
	  arg="\"$arg\""
	  ;;
	esac
	;;
      esac

      # Now actually substitute the argument into the commands.
      if test -n "$arg"; then
	compile_command="$compile_command $arg"
	finalize_command="$finalize_command $arg"
      fi
    done

    if test -n "$prev"; then
      $echo "$modename: the \`$prevarg' option requires an argument" 1>&2
      $echo "$help" 1>&2
      exit 1
    fi

    if test "$export_dynamic" = yes && test -n "$export_dynamic_flag_spec"; then
      eval arg=\"$export_dynamic_flag_spec\"
      compile_command="$compile_command $arg"
      finalize_command="$finalize_command $arg"
    fi

    oldlibs=
    # calculate the name of the file, without its directory
    outputname=`$echo "X$output" | $Xsed -e 's%^.*/%%'`
    libobjs_save="$libobjs"

    case "$output" in
    "")
      $echo "$modename: you must specify an output file" 1>&2
      $echo "$help" 1>&2
      exit 1
      ;;

    *.a | *.lib)
      if test -n "$link_against_libtool_libs"; then
	$echo "$modename: error: cannot link libtool libraries into archives" 1>&2
	exit 1
      fi

      if test -n "$deplibs"; then
	$echo "$modename: warning: \`-l' and \`-L' are ignored for archives" 1>&2
      fi

      if test -n "$dlfiles$dlprefiles" || test "$dlself" != no; then
	$echo "$modename: warning: \`-dlopen' is ignored for archives" 1>&2
      fi

      if test -n "$rpath"; then
	$echo "$modename: warning: \`-rpath' is ignored for archives" 1>&2
      fi

      if test -n "$xrpath"; then
	$echo "$modename: warning: \`-R' is ignored for archives" 1>&2
      fi

      if test -n "$vinfo"; then
	$echo "$modename: warning: \`-version-info' is ignored for archives" 1>&2
      fi

      if test -n "$release"; then
	$echo "$modename: warning: \`-release' is ignored for archives" 1>&2
      fi

      if test -n "$export_symbols" || test -n "$export_symbols_regex"; then
	$echo "$modename: warning: \`-export-symbols' is ignored for archives" 1>&2
      fi

      # Now set the variables for building old libraries.
      build_libtool_libs=no
      oldlibs="$output"
      ;;

    *.la)
      # Make sure we only generate libraries of the form `libNAME.la'.
      case "$outputname" in
      lib*)
	name=`$echo "X$outputname" | $Xsed -e 's/\.la$//' -e 's/^lib//'`
	eval libname=\"$libname_spec\"
	;;
      *)
	if test "$module" = no; then
	  $echo "$modename: libtool library \`$output' must begin with \`lib'" 1>&2
	  $echo "$help" 1>&2
	  exit 1
	fi
	if test "$need_lib_prefix" != no; then
	  # Add the "lib" prefix for modules if required
	  name=`$echo "X$outputname" | $Xsed -e 's/\.la$//'`
	  eval libname=\"$libname_spec\"
	else
	  libname=`$echo "X$outputname" | $Xsed -e 's/\.la$//'`
	fi
	;;
      esac

      output_objdir=`$echo "X$output" | $Xsed -e 's%/[^/]*$%%'`
      if test "X$output_objdir" = "X$output"; then
	output_objdir="$objdir"
      else
	output_objdir="$output_objdir/$objdir"
      fi

      if test -n "$objs"; then
	$echo "$modename: cannot build libtool library \`$output' from non-libtool objects:$objs" 2>&1
	exit 1
      fi

      # How the heck are we supposed to write a wrapper for a shared library?
      if test -n "$link_against_libtool_libs"; then
	 $echo "$modename: error: cannot link shared libraries into libtool libraries" 1>&2
	 exit 1
      fi

      if test -n "$dlfiles$dlprefiles" || test "$dlself" != no; then
	$echo "$modename: warning: \`-dlopen' is ignored for libtool libraries" 1>&2
      fi

      set dummy $rpath
      if test $# -gt 2; then
	$echo "$modename: warning: ignoring multiple \`-rpath's for a libtool library" 1>&2
      fi
      install_libdir="$2"

      oldlibs=
      if test -z "$rpath"; then
	if test "$build_libtool_libs" = yes; then
	  # Building a libtool convenience library.
	  libext=al
	  oldlibs="$output_objdir/$libname.$libext $oldlibs"
	  build_libtool_libs=convenience
	  build_old_libs=yes
	fi
	dependency_libs="$deplibs"

	if test -n "$vinfo"; then
	  $echo "$modename: warning: \`-version-info' is ignored for convenience libraries" 1>&2
	fi

	if test -n "$release"; then
	  $echo "$modename: warning: \`-release' is ignored for convenience libraries" 1>&2
	fi
      else

	# Parse the version information argument.
	IFS="${IFS= 	}"; save_ifs="$IFS"; IFS=':'
	set dummy $vinfo 0 0 0
	IFS="$save_ifs"

	if test -n "$8"; then
	  $echo "$modename: too many parameters to \`-version-info'" 1>&2
	  $echo "$help" 1>&2
	  exit 1
	fi

	current="$2"
	revision="$3"
	age="$4"

	# Check that each of the things are valid numbers.
	case "$current" in
	[0-9]*) ;;
	*)
	  $echo "$modename: CURRENT \`$current' is not a nonnegative integer" 1>&2
	  $echo "$modename: \`$vinfo' is not valid version information" 1>&2
	  exit 1
	  ;;
	esac

	case "$revision" in
	[0-9]*) ;;
	*)
	  $echo "$modename: REVISION \`$revision' is not a nonnegative integer" 1>&2
	  $echo "$modename: \`$vinfo' is not valid version information" 1>&2
	  exit 1
	  ;;
	esac

	case "$age" in
	[0-9]*) ;;
	*)
	  $echo "$modename: AGE \`$age' is not a nonnegative integer" 1>&2
	  $echo "$modename: \`$vinfo' is not valid version information" 1>&2
	  exit 1
	  ;;
	esac

	if test $age -gt $current; then
	  $echo "$modename: AGE \`$age' is greater than the current interface number \`$current'" 1>&2
	  $echo "$modename: \`$vinfo' is not valid version information" 1>&2
	  exit 1
	fi

	# Calculate the version variables.
	major=
	versuffix=
	verstring=
	case "$version_type" in
	none) ;;

	irix)
	  major=`expr $current - $age + 1`
	  versuffix="$major.$revision"
	  verstring="sgi$major.$revision"

	  # Add in all the interfaces that we are compatible with.
	  loop=$revision
	  while test $loop != 0; do
	    iface=`expr $revision - $loop`
	    loop=`expr $loop - 1`
	    verstring="sgi$major.$iface:$verstring"
	  done
	  ;;

	linux)
	  major=.`expr $current - $age`
	  versuffix="$major.$age.$revision"
	  ;;

	osf)
	  major=`expr $current - $age`
	  versuffix=".$current.$age.$revision"
	  verstring="$current.$age.$revision"

	  # Add in all the interfaces that we are compatible with.
	  loop=$age
	  while test $loop != 0; do
	    iface=`expr $current - $loop`
	    loop=`expr $loop - 1`
	    verstring="$verstring:${iface}.0"
	  done

	  # Make executables depend on our current version.
	  verstring="$verstring:${current}.0"
	  ;;

	sunos)
	  major=".$current"
	  versuffix=".$current.$revision"
	  ;;

	freebsd-aout)
	  major=".$current"
	  versuffix=".$current.$revision";
	  ;;

	freebsd-elf)
	  major=".$current"
	  versuffix=".$current";
	  ;;

	windows)
	  # Like Linux, but with '-' rather than '.', since we only
	  # want one extension on Windows 95.
	  major=`expr $current - $age`
	  versuffix="-$major-$age-$revision"
	  ;;

	*)
	  $echo "$modename: unknown library version type \`$version_type'" 1>&2
	  echo "Fatal configuration error.  See the $PACKAGE docs for more information." 1>&2
	  exit 1
	  ;;
	esac

	# Clear the version info if we defaulted, and they specified a release.
	if test -z "$vinfo" && test -n "$release"; then
	  major=
	  verstring="0.0"
	  if test "$need_version" = no; then
	    versuffix=
	  else
	    versuffix=".0.0"
	  fi
	fi

	# Remove version info from name if versioning should be avoided
	if test "$avoid_version" = yes && test "$need_version" = no; then
	  major=
	  versuffix=
	  verstring=""
	fi
	
	# Check to see if the archive will have undefined symbols.
	if test "$allow_undefined" = yes; then
	  if test "$allow_undefined_flag" = unsupported; then
	    $echo "$modename: warning: undefined symbols not allowed in $host shared libraries" 1>&2
	    build_libtool_libs=no
	    build_old_libs=yes
	  fi
	else
	  # Don't allow undefined symbols.
	  allow_undefined_flag="$no_undefined_flag"
	fi

	dependency_libs="$deplibs"
	case "$host" in
	*-*-cygwin* | *-*-mingw* | *-*-os2* | *-*-beos*)
	  # these systems don't actually have a c library (as such)!
	  ;;
        *-*-rhapsody*)
	  # rhapsody is a little odd...
	  deplibs="$deplibs -framework System"
	  ;;
	*)
	  # Add libc to deplibs on all other systems.
	  deplibs="$deplibs -lc"
	  ;;
	esac
      fi

      # Create the output directory, or remove our outputs if we need to.
      if test -d $output_objdir; then
	$show "${rm}r $output_objdir/$outputname $output_objdir/$libname.* $output_objdir/${libname}${release}.*"
	$run ${rm}r $output_objdir/$outputname $output_objdir/$libname.* $output_objdir/${libname}${release}.*
      else
	$show "$mkdir $output_objdir"
	$run $mkdir $output_objdir
	status=$?
	if test $status -ne 0 && test ! -d $output_objdir; then
	  exit $status
	fi
      fi

      # Now set the variables for building old libraries.
      if test "$build_old_libs" = yes && test "$build_libtool_libs" != convenience ; then
	oldlibs="$oldlibs $output_objdir/$libname.$libext"

	# Transform .lo files to .o files.
	oldobjs="$objs "`$echo "X$libobjs" | $SP2NL | $Xsed -e '/\.'${libext}'$/d' -e "$lo2o" | $NL2SP`
      fi

      if test "$build_libtool_libs" = yes; then
	# Transform deplibs into only deplibs that can be linked in shared.
	name_save=$name
	libname_save=$libname
	release_save=$release
	versuffix_save=$versuffix
	major_save=$major
	# I'm not sure if I'm treating the release correctly.  I think
	# release should show up in the -l (ie -lgmp5) so we don't want to
	# add it in twice.  Is that correct?
	release=""
	versuffix=""
	major=""
	newdeplibs=
	droppeddeps=no
	case "$deplibs_check_method" in
	pass_all)
	  # Don't check for shared/static.  Everything works.
	  # This might be a little naive.  We might want to check
	  # whether the library exists or not.  But this is on
	  # osf3 & osf4 and I'm not really sure... Just
	  # implementing what was already the behaviour.
	  newdeplibs=$deplibs
	  ;;
	test_compile)
	  # This code stresses the "libraries are programs" paradigm to its
	  # limits. Maybe even breaks it.  We compile a program, linking it
	  # against the deplibs as a proxy for the library.  Then we can check
	  # whether they linked in statically or dynamically with ldd.
	  $rm conftest.c
	  cat > conftest.c <<EOF
	  int main() { return 0; }
EOF
	  $rm conftest
	  $CC -o conftest conftest.c $deplibs
	  if test $? -eq 0 ; then
	    ldd_output=`ldd conftest`
	    for i in $deplibs; do
	      name="`expr $i : '-l\(.*\)'`"
	      # If $name is empty we are operating on a -L argument.
	      if test "$name" != "" ; then
		libname=`eval \\$echo \"$libname_spec\"`
		deplib_matches=`eval \\$echo \"$library_names_spec\"`
		set dummy $deplib_matches
		deplib_match=$2
		if test `expr "$ldd_output" : ".*$deplib_match"` -ne 0 ; then
		  newdeplibs="$newdeplibs $i"
		else
		  droppeddeps=yes
		  echo
		  echo "*** Warning: This library needs some functionality provided by $i."
		  echo "*** I have the capability to make that library automatically link in when"
		  echo "*** you link to this library.  But I can only do this if you have a"
		  echo "*** shared version of the library, which you do not appear to have."
		fi
	      else
		newdeplibs="$newdeplibs $i"
	      fi
	    done
	  else
	    # Error occured in the first compile.  Let's try to salvage the situation:
	    # Compile a seperate program for each library.
	    for i in $deplibs; do
	      name="`expr $i : '-l\(.*\)'`"
	     # If $name is empty we are operating on a -L argument.
	      if test "$name" != "" ; then
		$rm conftest
		$CC -o conftest conftest.c $i
		# Did it work?
		if test $? -eq 0 ; then
		  ldd_output=`ldd conftest`
		  libname=`eval \\$echo \"$libname_spec\"`
		  deplib_matches=`eval \\$echo \"$library_names_spec\"`
		  set dummy $deplib_matches
		  deplib_match=$2
		  if test `expr "$ldd_output" : ".*$deplib_match"` -ne 0 ; then
		    newdeplibs="$newdeplibs $i"
		  else
		    droppeddeps=yes
		    echo
		    echo "*** Warning: This library needs some functionality provided by $i."
		    echo "*** I have the capability to make that library automatically link in when"
		    echo "*** you link to this library.  But I can only do this if you have a"
		    echo "*** shared version of the library, which you do not appear to have."
		  fi
		else
		  droppeddeps=yes
		  echo
		  echo "*** Warning!  Library $i is needed by this library but I was not able to"
		  echo "***  make it link in!  You will probably need to install it or some"
		  echo "*** library that it depends on before this library will be fully"
		  echo "*** functional.  Installing it before continuing would be even better."
		fi
	      else
		newdeplibs="$newdeplibs $i"
	      fi
	    done
	  fi
	  ;;
	file_magic*)
	  set dummy $deplibs_check_method
	  file_magic_regex="`expr \"$deplibs_check_method\" : \"$2 \(.*\)\"`"
	  for a_deplib in $deplibs; do
	    name="`expr $a_deplib : '-l\(.*\)'`"
	    # If $name is empty we are operating on a -L argument.
	    if test "$name" != "" ; then
	      libname=`eval \\$echo \"$libname_spec\"`
	      for i in $lib_search_path; do
		    potential_libs=`ls $i/$libname[.-]* 2>/dev/null`
		    for potent_lib in $potential_libs; do
		      # Follow soft links.
		      if ls -lLd "$potent_lib" 2>/dev/null \
			 | grep " -> " >/dev/null; then
			continue 
		      fi
		      # The statement above tries to avoid entering an
		      # endless loop below, in case of cyclic links.
		      # We might still enter an endless loop, since a link
		      # loop can be closed while we follow links,
		      # but so what?
		      potlib="$potent_lib"
		      while test -h "$potlib" 2>/dev/null; do
			potliblink=`ls -ld $potlib | sed 's/.* -> //'`
			case "$potliblink" in
			[\\/]* | [A-Za-z]:[\\/]*) potlib="$potliblink";;
			*) potlib=`$echo "X$potlib" | $Xsed -e 's,[^/]*$,,'`"$potliblink";;
			esac
		      done
		      if eval $file_magic_cmd \"\$potlib\" 2>/dev/null \
			 | sed 10q \
			 | egrep "$file_magic_regex" > /dev/null; then
			newdeplibs="$newdeplibs $a_deplib"
			a_deplib=""
			break 2
		      fi
		    done
	      done
	      if test -n "$a_deplib" ; then
		droppeddeps=yes
		echo
		echo "*** Warning: This library needs some functionality provided by $a_deplib."
		echo "*** I have the capability to make that library automatically link in when"
		echo "*** you link to this library.  But I can only do this if you have a"
		echo "*** shared version of the library, which you do not appear to have."
	      fi
	    else
	      # Add a -L argument.
	      newdeplibs="$newdeplibs $a_deplib"
	    fi
	  done # Gone through all deplibs.
	  ;;
	none | unknown | *)
	  newdeplibs=""
	  if $echo "X $deplibs" | $Xsed -e 's/ -lc$//' \
	       -e 's/ -[LR][^ ]*//g' -e 's/[ 	]//g' |
	     grep . >/dev/null; then
	    echo
	    if test "X$deplibs_check_method" = "Xnone"; then
	      echo "*** Warning: inter-library dependencies are not supported in this platform."
	    else
	      echo "*** Warning: inter-library dependencies are not known to be supported."
	    fi
	    echo "*** All declared inter-library dependencies are being dropped."
	    droppeddeps=yes
	  fi
	  ;;
	esac
	versuffix=$versuffix_save
	major=$major_save
	release=$release_save
	libname=$libname_save
	name=$name_save

	if test "$droppeddeps" = yes; then
	  if test "$module" = yes; then
	    echo
	    echo "*** Warning: libtool could not satisfy all declared inter-library"
	    echo "*** dependencies of module $libname.  Therefore, libtool will create"
	    echo "*** a static module, that should work as long as the dlopening"
	    echo "*** application is linked with the -dlopen flag."
	    if test -z "$global_symbol_pipe"; then
	      echo
	      echo "*** However, this would only work if libtool was able to extract symbol"
	      echo "*** lists from a program, using \`nm' or equivalent, but libtool could"
	      echo "*** not find such a program.  So, this module is probably useless."
	      echo "*** \`nm' from GNU binutils and a full rebuild may help."
	    fi
	    if test "$build_old_libs" = no; then
	      oldlibs="$output_objdir/$libname.$libext"
	      build_libtool_libs=module
	      build_old_libs=yes
	    else
	      build_libtool_libs=no
	    fi
	  else
	    echo "*** The inter-library dependencies that have been dropped here will be"
	    echo "*** automatically added whenever a program is linked with this library"
	    echo "*** or is declared to -dlopen it."
	  fi
	fi
	# Done checking deplibs!
	deplibs=$newdeplibs
      fi

      # All the library-specific variables (install_libdir is set above).
      library_names=
      old_library=
      dlname=
      
      # Test again, we may have decided not to build it any more
      if test "$build_libtool_libs" = yes; then
	# Get the real and link names of the library.
	eval library_names=\"$library_names_spec\"
	set dummy $library_names
	realname="$2"
	shift; shift

	if test -n "$soname_spec"; then
	  eval soname=\"$soname_spec\"
	else
	  soname="$realname"
	fi

	lib="$output_objdir/$realname"
	for link
	do
	  linknames="$linknames $link"
	done

	# Ensure that we have .o objects for linkers which dislike .lo
	# (e.g. aix) in case we are running --disable-static
	for obj in $libobjs; do
	  xdir=`$echo "X$obj" | $Xsed -e 's%/[^/]*$%%'`
	  if test "X$xdir" = "X$obj"; then
	    xdir="."
	  else
	    xdir="$xdir"
	  fi
	  baseobj=`$echo "X$obj" | $Xsed -e 's%^.*/%%'`
	  oldobj=`$echo "X$baseobj" | $Xsed -e "$lo2o"`
	  if test ! -f $xdir/$oldobj; then
	    $show "(cd $xdir && ${LN_S} $baseobj $oldobj)"
	    $run eval '(cd $xdir && ${LN_S} $baseobj $oldobj)' || exit $?
	  fi
	done

	# Use standard objects if they are pic
	test -z "$pic_flag" && libobjs=`$echo "X$libobjs" | $SP2NL | $Xsed -e "$lo2o" | $NL2SP`

	# Prepare the list of exported symbols
	if test -z "$export_symbols"; then
	  if test "$always_export_symbols" = yes || test -n "$export_symbols_regex"; then
	    $show "generating symbol list for \`$libname.la'"
	    export_symbols="$output_objdir/$libname.exp"
	    $run $rm $export_symbols
	    eval cmds=\"$export_symbols_cmds\"
	    IFS="${IFS= 	}"; save_ifs="$IFS"; IFS='~'
	    for cmd in $cmds; do
	      IFS="$save_ifs"
	      $show "$cmd"
	      $run eval "$cmd" || exit $?
	    done
	    IFS="$save_ifs"
	    if test -n "$export_symbols_regex"; then
	      $show "egrep -e \"$export_symbols_regex\" \"$export_symbols\" > \"${export_symbols}T\""
	      $run eval 'egrep -e "$export_symbols_regex" "$export_symbols" > "${export_symbols}T"'
	      $show "$mv \"${export_symbols}T\" \"$export_symbols\""
	      $run eval '$mv "${export_symbols}T" "$export_symbols"'
	    fi
	  fi
	fi

	if test -n "$export_symbols" && test -n "$include_expsyms"; then
	  $run eval '$echo "X$include_expsyms" | $SP2NL >> "$export_symbols"'
	fi

	if test -n "$convenience"; then
	  if test -n "$whole_archive_flag_spec"; then
	    eval libobjs=\"\$libobjs $whole_archive_flag_spec\"
	  else
	    gentop="$output_objdir/${outputname}x"
	    $show "${rm}r $gentop"
	    $run ${rm}r "$gentop"
	    $show "mkdir $gentop"
	    $run mkdir "$gentop"
	    status=$?
	    if test $status -ne 0 && test ! -d "$gentop"; then
	      exit $status
	    fi
	    generated="$generated $gentop"

	    for xlib in $convenience; do
	      # Extract the objects.
	      case "$xlib" in
	      [\\/]* | [A-Za-z]:[\\/]*) xabs="$xlib" ;;
	      *) xabs=`pwd`"/$xlib" ;;
	      esac
	      xlib=`$echo "X$xlib" | $Xsed -e 's%^.*/%%'`
	      xdir="$gentop/$xlib"

	      $show "${rm}r $xdir"
	      $run ${rm}r "$xdir"
	      $show "mkdir $xdir"
	      $run mkdir "$xdir"
	      status=$?
	      if test $status -ne 0 && test ! -d "$xdir"; then
		exit $status
	      fi
	      $show "(cd $xdir && $AR x $xabs)"
	      $run eval "(cd \$xdir && $AR x \$xabs)" || exit $?

	      libobjs="$libobjs "`find $xdir -name \*.o -print -o -name \*.lo -print | $NL2SP`
	    done
	  fi
	fi

	if test "$thread_safe" = yes && test -n "$thread_safe_flag_spec"; then
	  eval flag=\"$thread_safe_flag_spec\"
	  linkopts="$linkopts $flag"
	fi

	# Do each of the archive commands.
	if test -n "$export_symbols" && test -n "$archive_expsym_cmds"; then
	  eval cmds=\"$archive_expsym_cmds\"
	else
	  eval cmds=\"$archive_cmds\"
	fi
	IFS="${IFS= 	}"; save_ifs="$IFS"; IFS='~'
	for cmd in $cmds; do
	  IFS="$save_ifs"
	  $show "$cmd"
	  $run eval "$cmd" || exit $?
	done
	IFS="$save_ifs"

	# Create links to the real library.
	for linkname in $linknames; do
	  if test "$realname" != "$linkname"; then
	    $show "(cd $output_objdir && $rm $linkname && $LN_S $realname $linkname)"
	    $run eval '(cd $output_objdir && $rm $linkname && $LN_S $realname $linkname)' || exit $?
	  fi
	done

	# If -module or -export-dynamic was specified, set the dlname.
	if test "$module" = yes || test "$export_dynamic" = yes; then
	  # On all known operating systems, these are identical.
	  dlname="$soname"
	fi
      fi
      ;;

    *.lo | *.o | *.obj)
      if test -n "$link_against_libtool_libs"; then
	$echo "$modename: error: cannot link libtool libraries into objects" 1>&2
	exit 1
      fi

      if test -n "$deplibs"; then
	$echo "$modename: warning: \`-l' and \`-L' are ignored for objects" 1>&2
      fi

      if test -n "$dlfiles$dlprefiles" || test "$dlself" != no; then
	$echo "$modename: warning: \`-dlopen' is ignored for objects" 1>&2
      fi

      if test -n "$rpath"; then
	$echo "$modename: warning: \`-rpath' is ignored for objects" 1>&2
      fi

      if test -n "$xrpath"; then
	$echo "$modename: warning: \`-R' is ignored for objects" 1>&2
      fi

      if test -n "$vinfo"; then
	$echo "$modename: warning: \`-version-info' is ignored for objects" 1>&2
      fi

      if test -n "$release"; then
	$echo "$modename: warning: \`-release' is ignored for objects" 1>&2
      fi

      case "$output" in
      *.lo)
	if test -n "$objs"; then
	  $echo "$modename: cannot build library object \`$output' from non-libtool objects" 1>&2
	  exit 1
	fi
	libobj="$output"
	obj=`$echo "X$output" | $Xsed -e "$lo2o"`
	;;
      *)
	libobj=
	obj="$output"
	;;
      esac

      # Delete the old objects.
      $run $rm $obj $libobj

      # Objects from convenience libraries.  This assumes
      # single-version convenience libraries.  Whenever we create
      # different ones for PIC/non-PIC, this we'll have to duplicate
      # the extraction.
      reload_conv_objs=
      gentop=
      # reload_cmds runs $LD directly, so let us get rid of
      # -Wl from whole_archive_flag_spec
      wl= 

      if test -n "$convenience"; then
	if test -n "$whole_archive_flag_spec"; then
	  eval reload_conv_objs=\"\$reload_objs $whole_archive_flag_spec\"
	else
	  gentop="$output_objdir/${obj}x"
	  $show "${rm}r $gentop"
	  $run ${rm}r "$gentop"
	  $show "mkdir $gentop"
	  $run mkdir "$gentop"
	  status=$?
	  if test $status -ne 0 && test ! -d "$gentop"; then
	    exit $status
	  fi
	  generated="$generated $gentop"

	  for xlib in $convenience; do
	    # Extract the objects.
	    case "$xlib" in
	    [\\/]* | [A-Za-z]:[\\/]*) xabs="$xlib" ;;
	    *) xabs=`pwd`"/$xlib" ;;
	    esac
	    xlib=`$echo "X$xlib" | $Xsed -e 's%^.*/%%'`
	    xdir="$gentop/$xlib"

	    $show "${rm}r $xdir"
	    $run ${rm}r "$xdir"
	    $show "mkdir $xdir"
	    $run mkdir "$xdir"
	    status=$?
	    if test $status -ne 0 && test ! -d "$xdir"; then
	      exit $status
	    fi
	    $show "(cd $xdir && $AR x $xabs)"
	    $run eval "(cd \$xdir && $AR x \$xabs)" || exit $?

	    reload_conv_objs="$reload_objs "`find $xdir -name \*.o -print -o -name \*.lo -print | $NL2SP`
	  done
	fi
      fi

      # Create the old-style object.
      reload_objs="$objs "`$echo "X$libobjs" | $SP2NL | $Xsed -e '/\.'${libext}$'/d' -e '/\.lib$/d' -e "$lo2o" | $NL2SP`" $reload_conv_objs"

      output="$obj"
      eval cmds=\"$reload_cmds\"
      IFS="${IFS= 	}"; save_ifs="$IFS"; IFS='~'
      for cmd in $cmds; do
	IFS="$save_ifs"
	$show "$cmd"
	$run eval "$cmd" || exit $?
      done
      IFS="$save_ifs"

      # Exit if we aren't doing a library object file.
      if test -z "$libobj"; then
	if test -n "$gentop"; then
	  $show "${rm}r $gentop"
	  $run ${rm}r $gentop
	fi

	exit 0
      fi

      if test "$build_libtool_libs" != yes; then
	if test -n "$gentop"; then
	  $show "${rm}r $gentop"
	  $run ${rm}r $gentop
	fi

	# Create an invalid libtool object if no PIC, so that we don't
	# accidentally link it into a program.
	$show "echo timestamp > $libobj"
	$run eval "echo timestamp > $libobj" || exit $?
	exit 0
      fi

      if test -n "$pic_flag"; then
	# Only do commands if we really have different PIC objects.
	reload_objs="$libobjs $reload_conv_objs"
	output="$libobj"
	eval cmds=\"$reload_cmds\"
	IFS="${IFS= 	}"; save_ifs="$IFS"; IFS='~'
	for cmd in $cmds; do
	  IFS="$save_ifs"
	  $show "$cmd"
	  $run eval "$cmd" || exit $?
	done
	IFS="$save_ifs"
      else
	# Just create a symlink.
	$show $rm $libobj
	$run $rm $libobj
	xdir=`$echo "X$libobj" | $Xsed -e 's%/[^/]*$%%'`
	if test "X$xdir" = "X$libobj"; then
	  xdir="."
	else
	  xdir="$xdir"
	fi
	baseobj=`$echo "X$libobj" | $Xsed -e 's%^.*/%%'`
	oldobj=`$echo "X$baseobj" | $Xsed -e "$lo2o"`
	$show "(cd $xdir && $LN_S $oldobj $baseobj)"
	$run eval '(cd $xdir && $LN_S $oldobj $baseobj)' || exit $?
      fi

      if test -n "$gentop"; then
	$show "${rm}r $gentop"
	$run ${rm}r $gentop
      fi

      exit 0
      ;;

    # Anything else should be a program.
    *)
      if test -n "$vinfo"; then
	$echo "$modename: warning: \`-version-info' is ignored for programs" 1>&2
      fi

      if test -n "$release"; then
	$echo "$modename: warning: \`-release' is ignored for programs" 1>&2
      fi

      if test "$preload" = yes; then
	if test "$dlopen" = unknown && test "$dlopen_self" = unknown &&
	   test "$dlopen_self_static" = unknown; then
	  $echo "$modename: warning: \`AC_LIBTOOL_DLOPEN' not used. Assuming no dlopen support."
	fi 
      fi
    
      if test -n "$rpath$xrpath"; then
	# If the user specified any rpath flags, then add them.
	for libdir in $rpath $xrpath; do
	  # This is the magic to use -rpath.
	  case "$compile_rpath " in
	  *" $libdir "*) ;;
	  *) compile_rpath="$compile_rpath $libdir" ;;
	  esac
	  case "$finalize_rpath " in
	  *" $libdir "*) ;;
	  *) finalize_rpath="$finalize_rpath $libdir" ;;
	  esac
	done
      fi

      # Now hardcode the library paths
      rpath=
      hardcode_libdirs=
      for libdir in $compile_rpath $finalize_rpath; do
	if test -n "$hardcode_libdir_flag_spec"; then
	  if test -n "$hardcode_libdir_separator"; then
	    if test -z "$hardcode_libdirs"; then
	      hardcode_libdirs="$libdir"
	    else
	      # Just accumulate the unique libdirs.
	      case "$hardcode_libdir_separator$hardcode_libdirs$hardcode_libdir_separator" in
	      *"$hardcode_libdir_separator$libdir$hardcode_libdir_separator"*)
		;;
	      *)
		hardcode_libdirs="$hardcode_libdirs$hardcode_libdir_separator$libdir"
		;;
	      esac
	    fi
	  else
	    eval flag=\"$hardcode_libdir_flag_spec\"
	    rpath="$rpath $flag"
	  fi
	elif test -n "$runpath_var"; then
	  case "$perm_rpath " in
	  *" $libdir "*) ;;
	  *) perm_rpath="$perm_rpath $libdir" ;;
	  esac
	fi
      done
      # Substitute the hardcoded libdirs into the rpath.
      if test -n "$hardcode_libdir_separator" &&
	 test -n "$hardcode_libdirs"; then
	libdir="$hardcode_libdirs"
	eval rpath=\" $hardcode_libdir_flag_spec\"
      fi
      compile_rpath="$rpath"

      rpath=
      hardcode_libdirs=
      for libdir in $finalize_rpath; do
	if test -n "$hardcode_libdir_flag_spec"; then
	  if test -n "$hardcode_libdir_separator"; then
	    if test -z "$hardcode_libdirs"; then
	      hardcode_libdirs="$libdir"
	    else
	      # Just accumulate the unique libdirs.
	      case "$hardcode_libdir_separator$hardcode_libdirs$hardcode_libdir_separator" in
	      *"$hardcode_libdir_separator$libdir$hardcode_libdir_separator"*)
		;;
	      *)
		hardcode_libdirs="$hardcode_libdirs$hardcode_libdir_separator$libdir"
		;;
	      esac
	    fi
	  else
	    eval flag=\"$hardcode_libdir_flag_spec\"
	    rpath="$rpath $flag"
	  fi
	elif test -n "$runpath_var"; then
	  case "$finalize_perm_rpath " in
	  *" $libdir "*) ;;
	  *) finalize_perm_rpath="$finalize_perm_rpath $libdir" ;;
	  esac
	fi
      done
      # Substitute the hardcoded libdirs into the rpath.
      if test -n "$hardcode_libdir_separator" &&
	 test -n "$hardcode_libdirs"; then
	libdir="$hardcode_libdirs"
	eval rpath=\" $hardcode_libdir_flag_spec\"
      fi
      finalize_rpath="$rpath"

      output_objdir=`$echo "X$output" | $Xsed -e 's%/[^/]*$%%'`
      if test "X$output_objdir" = "X$output"; then
	output_objdir="$objdir"
      else
	output_objdir="$output_objdir/$objdir"
      fi

      # Create the binary in the object directory, then wrap it.
      if test ! -d $output_objdir; then
	$show "$mkdir $output_objdir"
	$run $mkdir $output_objdir
	status=$?
	if test $status -ne 0 && test ! -d $output_objdir; then
	  exit $status
	fi
      fi

      if test -n "$libobjs" && test "$build_old_libs" = yes; then
	# Transform all the library objects into standard objects.
	compile_command=`$echo "X$compile_command" | $SP2NL | $Xsed -e "$lo2o" | $NL2SP`
	finalize_command=`$echo "X$finalize_command" | $SP2NL | $Xsed -e "$lo2o" | $NL2SP`
      fi

      dlsyms=
      if test -n "$dlfiles$dlprefiles" || test "$dlself" != no; then
	if test -n "$NM" && test -n "$global_symbol_pipe"; then
	  dlsyms="${outputname}S.c"
	else
	  $echo "$modename: not configured to extract global symbols from dlpreopened files" 1>&2
	fi
      fi

      if test -n "$dlsyms"; then
	case "$dlsyms" in
	"") ;;
	*.c)
	  # Discover the nlist of each of the dlfiles.
	  nlist="$output_objdir/${outputname}.nm"

	  $show "$rm $nlist ${nlist}S ${nlist}T"
	  $run $rm "$nlist" "${nlist}S" "${nlist}T"

	  # Parse the name list into a source file.
	  $show "creating $output_objdir/$dlsyms"

	  test -z "$run" && $echo > "$output_objdir/$dlsyms" "\
/* $dlsyms - symbol resolution table for \`$outputname' dlsym emulation. */
/* Generated by $PROGRAM - GNU $PACKAGE $VERSION$TIMESTAMP */

#ifdef __cplusplus
extern \"C\" {
#endif

/* Prevent the only kind of declaration conflicts we can make. */
#define lt_preloaded_symbols some_other_symbol

/* External symbol declarations for the compiler. */\
"

	  if test "$dlself" = yes; then
	    $show "generating symbol list for \`$output'"

	    test -z "$run" && $echo ': @PROGRAM@ ' > "$nlist"

	    # Add our own program objects to the symbol list.
	    progfiles=`$echo "X$objs" | $SP2NL | $Xsed -e "$lo2o" | $NL2SP`
	    for arg in $progfiles; do
	      $show "extracting global C symbols from \`$arg'"
	      $run eval "$NM $arg | $global_symbol_pipe >> '$nlist'"
	    done

	    if test -n "$exclude_expsyms"; then
	      $run eval 'egrep -v " ($exclude_expsyms)$" "$nlist" > "$nlist"T'
	      $run eval '$mv "$nlist"T "$nlist"'
	    fi
	    
	    if test -n "$export_symbols_regex"; then
	      $run eval 'egrep -e "$export_symbols_regex" "$nlist" > "$nlist"T'
	      $run eval '$mv "$nlist"T "$nlist"'
	    fi

	    # Prepare the list of exported symbols
	    if test -z "$export_symbols"; then
	      export_symbols="$output_objdir/$output.exp"
	      $run $rm $export_symbols
	      $run eval "sed -n -e '/^: @PROGRAM@$/d' -e 's/^.* \(.*\)$/\1/p' "'< "$nlist" > "$export_symbols"'
	    else
	      $run eval "sed -e 's/\([][.*^$]\)/\\\1/g' -e 's/^/ /' -e 's/$/$/'"' < "$export_symbols" > "$output_objdir/$output.exp"'
	      $run eval 'grep -f "$output_objdir/$output.exp" < "$nlist" > "$nlist"T'
	      $run eval 'mv "$nlist"T "$nlist"'
	    fi
	  fi

	  for arg in $dlprefiles; do
	    $show "extracting global C symbols from \`$arg'"
	    name=`echo "$arg" | sed -e 's%^.*/%%'`
	    $run eval 'echo ": $name " >> "$nlist"'
	    $run eval "$NM $arg | $global_symbol_pipe >> '$nlist'"
	  done

	  if test -z "$run"; then
	    # Make sure we have at least an empty file.
	    test -f "$nlist" || : > "$nlist"

	    if test -n "$exclude_expsyms"; then
	      egrep -v " ($exclude_expsyms)$" "$nlist" > "$nlist"T
	      $mv "$nlist"T "$nlist"
	    fi

	    # Try sorting and uniquifying the output.
	    if grep -v "^: " < "$nlist" | sort +2 | uniq > "$nlist"S; then
	      :
	    else
	      grep -v "^: " < "$nlist" > "$nlist"S
	    fi

	    if test -f "$nlist"S; then
	      eval "$global_symbol_to_cdecl"' < "$nlist"S >> "$output_objdir/$dlsyms"'
	    else
	      echo '/* NONE */' >> "$output_objdir/$dlsyms"
	    fi

	    $echo >> "$output_objdir/$dlsyms" "\

#undef lt_preloaded_symbols

#if defined (__STDC__) && __STDC__
# define lt_ptr_t void *
#else
# define lt_ptr_t char *
# define const
#endif

/* The mapping between symbol names and symbols. */
const struct {
  const char *name;
  lt_ptr_t address;
}
lt_preloaded_symbols[] =
{\
"

	    sed -n -e 's/^: \([^ ]*\) $/  {\"\1\", (lt_ptr_t) 0},/p' \
		-e 's/^. \([^ ]*\) \([^ ]*\)$/  {"\2", (lt_ptr_t) \&\2},/p' \
		  < "$nlist" >> "$output_objdir/$dlsyms"

	    $echo >> "$output_objdir/$dlsyms" "\
  {0, (lt_ptr_t) 0}
};

/* This works around a problem in FreeBSD linker */
#ifdef FREEBSD_WORKAROUND
static const void *lt_preloaded_setup() {
  return lt_preloaded_symbols;
}
#endif

#ifdef __cplusplus
}
#endif\
"
	  fi

	  pic_flag_for_symtable=
	  case "$host" in
	  # compiling the symbol table file with pic_flag works around
	  # a FreeBSD bug that causes programs to crash when -lm is
	  # linked before any other PIC object.  But we must not use
	  # pic_flag when linking with -static.  The problem exists in
	  # FreeBSD 2.2.6 and is fixed in FreeBSD 3.1.
	  *-*-freebsd2*|*-*-freebsd3.0*|*-*-freebsdelf3.0*)
	    case "$compile_command " in
	    *" -static "*) ;;
	    *) pic_flag_for_symtable=" $pic_flag -DPIC -DFREEBSD_WORKAROUND";;
	    esac;;
	  *-*-hpux*)
	    case "$compile_command " in
	    *" -static "*) ;;
	    *) pic_flag_for_symtable=" $pic_flag -DPIC";;
	    esac
	  esac

	  # Now compile the dynamic symbol file.
	  $show "(cd $output_objdir && $CC -c$no_builtin_flag$pic_flag_for_symtable \"$dlsyms\")"
	  $run eval '(cd $output_objdir && $CC -c$no_builtin_flag$pic_flag_for_symtable "$dlsyms")' || exit $?

	  # Clean up the generated files.
	  $show "$rm $output_objdir/$dlsyms $nlist ${nlist}S ${nlist}T"
	  $run $rm "$output_objdir/$dlsyms" "$nlist" "${nlist}S" "${nlist}T"

	  # Transform the symbol file into the correct name.
	  compile_command=`$echo "X$compile_command" | $Xsed -e "s%@SYMFILE@%$output_objdir/${outputname}S.${objext}%"`
	  finalize_command=`$echo "X$finalize_command" | $Xsed -e "s%@SYMFILE@%$output_objdir/${outputname}S.${objext}%"`
	  ;;
	*)
	  $echo "$modename: unknown suffix for \`$dlsyms'" 1>&2
	  exit 1
	  ;;
	esac
      else
	# We keep going just in case the user didn't refer to
	# lt_preloaded_symbols.  The linker will fail if global_symbol_pipe
	# really was required.

	# Nullify the symbol file.
	compile_command=`$echo "X$compile_command" | $Xsed -e "s% @SYMFILE@%%"`
	finalize_command=`$echo "X$finalize_command" | $Xsed -e "s% @SYMFILE@%%"`
      fi

      if test -z "$link_against_libtool_libs" || test "$build_libtool_libs" != yes; then
	# Replace the output file specification.
	compile_command=`$echo "X$compile_command" | $Xsed -e 's%@OUTPUT@%'"$output"'%g'`
	link_command="$compile_command$compile_rpath"

	# We have no uninstalled library dependencies, so finalize right now.
	$show "$link_command"
	$run eval "$link_command"
	status=$?
	
	# Delete the generated files.
	if test -n "$dlsyms"; then
	  $show "$rm $output_objdir/${outputname}S.${objext}"
	  $run $rm "$output_objdir/${outputname}S.${objext}"
	fi

	exit $status
      fi

      if test -n "$shlibpath_var"; then
	# We should set the shlibpath_var
	rpath=
	for dir in $temp_rpath; do
	  case "$dir" in
	  [\\/]* | [A-Za-z]:[\\/]*)
	    # Absolute path.
	    rpath="$rpath$dir:"
	    ;;
	  *)
	    # Relative path: add a thisdir entry.
	    rpath="$rpath\$thisdir/$dir:"
	    ;;
	  esac
	done
	temp_rpath="$rpath"
      fi

      if test -n "$compile_shlibpath$finalize_shlibpath"; then
	compile_command="$shlibpath_var=\"$compile_shlibpath$finalize_shlibpath\$$shlibpath_var\" $compile_command"
      fi
      if test -n "$finalize_shlibpath"; then
	finalize_command="$shlibpath_var=\"$finalize_shlibpath\$$shlibpath_var\" $finalize_command"
      fi

      compile_var=
      finalize_var=
      if test -n "$runpath_var"; then
	if test -n "$perm_rpath"; then
	  # We should set the runpath_var.
	  rpath=
	  for dir in $perm_rpath; do
	    rpath="$rpath$dir:"
	  done
	  compile_var="$runpath_var=\"$rpath\$$runpath_var\" "
	fi
	if test -n "$finalize_perm_rpath"; then
	  # We should set the runpath_var.
	  rpath=
	  for dir in $finalize_perm_rpath; do
	    rpath="$rpath$dir:"
	  done
	  finalize_var="$runpath_var=\"$rpath\$$runpath_var\" "
	fi
      fi

      if test "$hardcode_action" = relink; then
	# Fast installation is not supported
	link_command="$compile_var$compile_command$compile_rpath"
	relink_command="$finalize_var$finalize_command$finalize_rpath"
	
	$echo "$modename: warning: this platform does not like uninstalled shared libraries" 1>&2
	$echo "$modename: \`$output' will be relinked during installation" 1>&2
      else
	if test "$fast_install" != no; then
	  link_command="$finalize_var$compile_command$finalize_rpath"
	  if test "$fast_install" = yes; then
	    relink_command=`$echo "X$compile_var$compile_command$compile_rpath" | $Xsed -e 's%@OUTPUT@%\$progdir/\$file%g'`
	  else
	    # fast_install is set to needless
	    relink_command=
	  fi
	else
	  link_command="$compile_var$compile_command$compile_rpath"
	  relink_command="$finalize_var$finalize_command$finalize_rpath"
	fi
      fi

      # Replace the output file specification.
      link_command=`$echo "X$link_command" | $Xsed -e 's%@OUTPUT@%'"$output_objdir/$outputname"'%g'`
      
      # Delete the old output files.
      $run $rm $output $output_objdir/$outputname $output_objdir/lt-$outputname

      $show "$link_command"
      $run eval "$link_command" || exit $?

      # Now create the wrapper script.
      $show "creating $output"

      # Quote the relink command for shipping.
      if test -n "$relink_command"; then
	relink_command=`$echo "X$relink_command" | $Xsed -e "$sed_quote_subst"`
      fi

      # Quote $echo for shipping.
      if test "X$echo" = "X$SHELL $0 --fallback-echo"; then
	case "$0" in
	[\\/]* | [A-Za-z]:[\\/]*) qecho="$SHELL $0 --fallback-echo";;
	*) qecho="$SHELL `pwd`/$0 --fallback-echo";;
	esac
	qecho=`$echo "X$qecho" | $Xsed -e "$sed_quote_subst"`
      else
	qecho=`$echo "X$echo" | $Xsed -e "$sed_quote_subst"`
      fi

      # Only actually do things if our run command is non-null.
      if test -z "$run"; then
	# win32 will think the script is a binary if it has
	# a .exe suffix, so we strip it off here.
	case $output in
	  *.exe) output=`echo $output|sed 's,.exe$,,'` ;;
	esac
	$rm $output
	trap "$rm $output; exit 1" 1 2 15

	$echo > $output "\
#! $SHELL

# $output - temporary wrapper script for $objdir/$outputname
# Generated by $PROGRAM - GNU $PACKAGE $VERSION$TIMESTAMP
#
# The $output program cannot be directly executed until all the libtool
# libraries that it depends on are installed.
#
# This wrapper script should never be moved out of the build directory.
# If it is, it will not operate correctly.

# Sed substitution that helps us do robust quoting.  It backslashifies
# metacharacters that are still active within double-quoted strings.
Xsed='sed -e 1s/^X//'
sed_quote_subst='$sed_quote_subst'

# The HP-UX ksh and POSIX shell print the target directory to stdout
# if CDPATH is set.
if test \"\${CDPATH+set}\" = set; then CDPATH=:; export CDPATH; fi

relink_command=\"$relink_command\"

# This environment variable determines our operation mode.
if test \"\$libtool_install_magic\" = \"$magic\"; then
  # install mode needs the following variable:
  link_against_libtool_libs='$link_against_libtool_libs'
else
  # When we are sourced in execute mode, \$file and \$echo are already set.
  if test \"\$libtool_execute_magic\" != \"$magic\"; then
    echo=\"$qecho\"
    file=\"\$0\"
    # Make sure echo works.
    if test \"X\$1\" = X--no-reexec; then
      # Discard the --no-reexec flag, and continue.
      shift
    elif test \"X\`(\$echo '\t') 2>/dev/null\`\" = 'X\t'; then
      # Yippee, \$echo works!
      :
    else
      # Restart under the correct shell, and then maybe \$echo will work.
      exec $SHELL \"\$0\" --no-reexec \${1+\"\$@\"}
    fi
  fi\
"
	$echo >> $output "\

  # Find the directory that this script lives in.
  thisdir=\`\$echo \"X\$file\" | \$Xsed -e 's%/[^/]*$%%'\`
  test \"x\$thisdir\" = \"x\$file\" && thisdir=.

  # Follow symbolic links until we get to the real thisdir.
  file=\`ls -ld \"\$file\" | sed -n 's/.*-> //p'\`
  while test -n \"\$file\"; do
    destdir=\`\$echo \"X\$file\" | \$Xsed -e 's%/[^/]*\$%%'\`

    # If there was a directory component, then change thisdir.
    if test \"x\$destdir\" != \"x\$file\"; then
      case \"\$destdir\" in
      [\\/]* | [A-Za-z]:[\\/]*) thisdir=\"\$destdir\" ;;
      *) thisdir=\"\$thisdir/\$destdir\" ;;
      esac
    fi

    file=\`\$echo \"X\$file\" | \$Xsed -e 's%^.*/%%'\`
    file=\`ls -ld \"\$thisdir/\$file\" | sed -n 's/.*-> //p'\`
  done

  # Try to get the absolute directory name.
  absdir=\`cd \"\$thisdir\" && pwd\`
  test -n \"\$absdir\" && thisdir=\"\$absdir\"
"

	if test "$fast_install" = yes; then
	  echo >> $output "\
  program=lt-'$outputname'
  progdir=\"\$thisdir/$objdir\"
  
  if test ! -f \"\$progdir/\$program\" || \\
     { file=\`ls -1dt \"\$progdir/\$program\" \"\$progdir/../\$program\" 2>/dev/null | sed 1q\`; \\
       test \"X\$file\" != \"X\$progdir/\$program\"; }; then

    file=\"\$\$-\$program\"

    if test ! -d \"\$progdir\"; then
      $mkdir \"\$progdir\"
    else
      $rm \"\$progdir/\$file\"
    fi"

	  echo >> $output "\

    # relink executable if necessary
    if test -n \"\$relink_command\"; then
      if (cd \"\$thisdir\" && eval \$relink_command); then :
      else
	$rm \"\$progdir/\$file\"
	exit 1
      fi
    fi

    $mv \"\$progdir/\$file\" \"\$progdir/\$program\" 2>/dev/null ||
    { $rm \"\$progdir/\$program\";
      $mv \"\$progdir/\$file\" \"\$progdir/\$program\"; }
    $rm \"\$progdir/\$file\"
  fi"
	else
	  echo >> $output "\
  program='$outputname'
  progdir=\"\$thisdir/$objdir\"
"
	fi

	echo >> $output "\

  if test -f \"\$progdir/\$program\"; then"

	# Export our shlibpath_var if we have one.
	if test "$shlibpath_overrides_runpath" = yes && test -n "$shlibpath_var" && test -n "$temp_rpath"; then
	  $echo >> $output "\
    # Add our own library path to $shlibpath_var
    $shlibpath_var=\"$temp_rpath\$$shlibpath_var\"

    # Some systems cannot cope with colon-terminated $shlibpath_var
    # The second colon is a workaround for a bug in BeOS R4 sed
    $shlibpath_var=\`\$echo \"X\$$shlibpath_var\" | \$Xsed -e 's/::*\$//'\`

    export $shlibpath_var
"
	fi

	# fixup the dll searchpath if we need to.
	if test -n "$dllsearchpath"; then
	  $echo >> $output "\
    # Add the dll search path components to the executable PATH
    PATH=$dllsearchpath:\$PATH
"
	fi

	$echo >> $output "\
    if test \"\$libtool_execute_magic\" != \"$magic\"; then
      # Run the actual program with our arguments.
"
	case $host in
	  # win32 systems need to use the prog path for dll
	  # lookup to work
	*-*-cygwin*)
	  $echo >> $output "\
      exec \$progdir/\$program \${1+\"\$@\"}
"
	  ;;

	# Backslashes separate directories on plain windows
	*-*-mingw | *-*-os2*)
	  $echo >> $output "\
      exec \$progdir\\\\\$program \${1+\"\$@\"}
"
	  ;;

	*)
	  $echo >> $output "\
      # Export the path to the program.
      PATH=\"\$progdir:\$PATH\"
      export PATH

      exec \$program \${1+\"\$@\"}
"
	  ;;
	esac
	$echo >> $output "\
      \$echo \"\$0: cannot exec \$program \${1+\"\$@\"}\"
      exit 1
    fi
  else
    # The program doesn't exist.
    \$echo \"\$0: error: \$progdir/\$program does not exist\" 1>&2
    \$echo \"This script is just a wrapper for \$program.\" 1>&2
    echo \"See the $PACKAGE documentation for more information.\" 1>&2
    exit 1
  fi
fi\
"
	chmod +x $output
      fi
      exit 0
      ;;
    esac

    # See if we need to build an old-fashioned archive.
    for oldlib in $oldlibs; do

      if test "$build_libtool_libs" = convenience; then
	oldobjs="$libobjs_save"
	addlibs="$convenience"
	build_libtool_libs=no
      else
	if test "$build_libtool_libs" = module; then
	  oldobjs="$libobjs_save"
	  build_libtool_libs=no
	else
	  oldobjs="$objs "`$echo "X$libobjs_save" | $SP2NL | $Xsed -e '/\.'${libext}'$/d' -e '/\.lib$/d' -e "$lo2o" | $NL2SP`
	fi
	addlibs="$old_convenience"
      fi

      if test -n "$addlibs"; then
	gentop="$output_objdir/${outputname}x"
	$show "${rm}r $gentop"
	$run ${rm}r "$gentop"
	$show "mkdir $gentop"
	$run mkdir "$gentop"
	status=$?
	if test $status -ne 0 && test ! -d "$gentop"; then
	  exit $status
	fi
	generated="$generated $gentop"
	  
	# Add in members from convenience archives.
	for xlib in $addlibs; do
	  # Extract the objects.
	  case "$xlib" in
	  [\\/]* | [A-Za-z]:[\\/]*) xabs="$xlib" ;;
	  *) xabs=`pwd`"/$xlib" ;;
	  esac
	  xlib=`$echo "X$xlib" | $Xsed -e 's%^.*/%%'`
	  xdir="$gentop/$xlib"

	  $show "${rm}r $xdir"
	  $run ${rm}r "$xdir"
	  $show "mkdir $xdir"
	  $run mkdir "$xdir"
	  status=$?
	  if test $status -ne 0 && test ! -d "$xdir"; then
	    exit $status
	  fi
	  $show "(cd $xdir && $AR x $xabs)"
	  $run eval "(cd \$xdir && $AR x \$xabs)" || exit $?

	  oldobjs="$oldobjs "`find $xdir -name \*.${objext} -print -o -name \*.lo -print | $NL2SP`
	done
      fi

      # Do each command in the archive commands.
      if test -n "$old_archive_from_new_cmds" && test "$build_libtool_libs" = yes; then
	eval cmds=\"$old_archive_from_new_cmds\"
      else
	# Ensure that we have .o objects in place in case we decided
	# not to build a shared library, and have fallen back to building
	# static libs even though --disable-static was passed!
	for oldobj in $oldobjs; do
	  if test ! -f $oldobj; then
	    xdir=`$echo "X$oldobj" | $Xsed -e 's%/[^/]*$%%'`
	    if test "X$xdir" = "X$oldobj"; then
	      xdir="."
	    else
	      xdir="$xdir"
	    fi
	    baseobj=`$echo "X$oldobj" | $Xsed -e 's%^.*/%%'`
	    obj=`$echo "X$baseobj" | $Xsed -e "$o2lo"`
	    $show "(cd $xdir && ${LN_S} $obj $baseobj)"
	    $run eval '(cd $xdir && ${LN_S} $obj $baseobj)' || exit $?
	  fi
	done

	eval cmds=\"$old_archive_cmds\"
      fi
      IFS="${IFS= 	}"; save_ifs="$IFS"; IFS='~'
      for cmd in $cmds; do
	IFS="$save_ifs"
	$show "$cmd"
	$run eval "$cmd" || exit $?
      done
      IFS="$save_ifs"
    done

    if test -n "$generated"; then
      $show "${rm}r$generated"
      $run ${rm}r$generated
    fi

    # Now create the libtool archive.
    case "$output" in
    *.la)
      old_library=
      test "$build_old_libs" = yes && old_library="$libname.$libext"
      $show "creating $output"

      if test -n "$xrpath"; then
	temp_xrpath=
	for libdir in $xrpath; do
	  temp_xrpath="$temp_xrpath -R$libdir"
	done
	dependency_libs="$temp_xrpath $dependency_libs"
      fi

      # Only create the output if not a dry run.
      if test -z "$run"; then
	for installed in no yes; do
	  if test "$installed" = yes; then
	    if test -z "$install_libdir"; then
	      break
	    fi
	    output="$output_objdir/$outputname"i
	  fi
	  $rm $output
	  $echo > $output "\
# $outputname - a libtool library file
# Generated by $PROGRAM - GNU $PACKAGE $VERSION$TIMESTAMP
#
# Please DO NOT delete this file!
# It is necessary for linking the library.

# The name that we can dlopen(3).
dlname='$dlname'

# Names of this library.
library_names='$library_names'

# The name of the static archive.
old_library='$old_library'

# Libraries that this one depends upon.
dependency_libs='$dependency_libs'

# Version information for $libname.
current=$current
age=$age
revision=$revision

# Is this an already installed library?
installed=$installed

# Directory that this library needs to be installed in:
libdir='$install_libdir'\
"
	done
      fi

      # Do a symbolic link so that the libtool archive can be found in
      # LD_LIBRARY_PATH before the program is installed.
      $show "(cd $output_objdir && $rm $outputname && $LN_S ../$outputname $outputname)"
      $run eval "(cd $output_objdir && $rm $outputname && $LN_S ../$outputname $outputname)" || exit $?
      ;;
    esac
    exit 0
    ;;

  # libtool install mode
  install)
    modename="$modename: install"

    # There may be an optional sh(1) argument at the beginning of
    # install_prog (especially on Windows NT).
    if test "$nonopt" = "$SHELL" || test "$nonopt" = /bin/sh; then
      # Aesthetically quote it.
      arg=`$echo "X$nonopt" | $Xsed -e "$sed_quote_subst"`
      case "$arg" in
      *[\[\~\#\^\&\*\(\)\{\}\|\;\<\>\?\'\ \	]*|*]*)
	arg="\"$arg\""
	;;
      esac
      install_prog="$arg "
      arg="$1"
      shift
    else
      install_prog=
      arg="$nonopt"
    fi

    # The real first argument should be the name of the installation program.
    # Aesthetically quote it.
    arg=`$echo "X$arg" | $Xsed -e "$sed_quote_subst"`
    case "$arg" in
    *[\[\~\#\^\&\*\(\)\{\}\|\;\<\>\?\'\ \	]*|*]*)
      arg="\"$arg\""
      ;;
    esac
    install_prog="$install_prog$arg"

    # We need to accept at least all the BSD install flags.
    dest=
    files=
    opts=
    prev=
    install_type=
    isdir=no
    stripme=
    for arg
    do
      if test -n "$dest"; then
	files="$files $dest"
	dest="$arg"
	continue
      fi

      case "$arg" in
      -d) isdir=yes ;;
      -f) prev="-f" ;;
      -g) prev="-g" ;;
      -m) prev="-m" ;;
      -o) prev="-o" ;;
      -s)
	stripme=" -s"
	continue
	;;
      -*) ;;

      *)
	# If the previous option needed an argument, then skip it.
	if test -n "$prev"; then
	  prev=
	else
	  dest="$arg"
	  continue
	fi
	;;
      esac

      # Aesthetically quote the argument.
      arg=`$echo "X$arg" | $Xsed -e "$sed_quote_subst"`
      case "$arg" in
      *[\[\~\#\^\&\*\(\)\{\}\|\;\<\>\?\'\ \	]*|*]*)
	arg="\"$arg\""
	;;
      esac
      install_prog="$install_prog $arg"
    done

    if test -z "$install_prog"; then
      $echo "$modename: you must specify an install program" 1>&2
      $echo "$help" 1>&2
      exit 1
    fi

    if test -n "$prev"; then
      $echo "$modename: the \`$prev' option requires an argument" 1>&2
      $echo "$help" 1>&2
      exit 1
    fi

    if test -z "$files"; then
      if test -z "$dest"; then
	$echo "$modename: no file or destination specified" 1>&2
      else
	$echo "$modename: you must specify a destination" 1>&2
      fi
      $echo "$help" 1>&2
      exit 1
    fi

    # Strip any trailing slash from the destination.
    dest=`$echo "X$dest" | $Xsed -e 's%/$%%'`

    # Check to see that the destination is a directory.
    test -d "$dest" && isdir=yes
    if test "$isdir" = yes; then
      destdir="$dest"
      destname=
    else
      destdir=`$echo "X$dest" | $Xsed -e 's%/[^/]*$%%'`
      test "X$destdir" = "X$dest" && destdir=.
      destname=`$echo "X$dest" | $Xsed -e 's%^.*/%%'`

      # Not a directory, so check to see that there is only one file specified.
      set dummy $files
      if test $# -gt 2; then
	$echo "$modename: \`$dest' is not a directory" 1>&2
	$echo "$help" 1>&2
	exit 1
      fi
    fi
    case "$destdir" in
    [\\/]* | [A-Za-z]:[\\/]*) ;;
    *)
      for file in $files; do
	case "$file" in
	*.lo) ;;
	*)
	  $echo "$modename: \`$destdir' must be an absolute directory name" 1>&2
	  $echo "$help" 1>&2
	  exit 1
	  ;;
	esac
      done
      ;;
    esac

    # This variable tells wrapper scripts just to set variables rather
    # than running their programs.
    libtool_install_magic="$magic"

    staticlibs=
    future_libdirs=
    current_libdirs=
    for file in $files; do

      # Do each installation.
      case "$file" in
      *.a | *.lib)
	# Do the static libraries later.
	staticlibs="$staticlibs $file"
	;;

      *.la)
	# Check to see that this really is a libtool archive.
	if (sed -e '2q' $file | egrep "^# Generated by .*$PACKAGE") >/dev/null 2>&1; then :
	else
	  $echo "$modename: \`$file' is not a valid libtool archive" 1>&2
	  $echo "$help" 1>&2
	  exit 1
	fi

	library_names=
	old_library=
	# If there is no directory component, then add one.
	case "$file" in
	*/* | *\\*) . $file ;;
	*) . ./$file ;;
	esac

	# Add the libdir to current_libdirs if it is the destination.
	if test "X$destdir" = "X$libdir"; then
	  case "$current_libdirs " in
	  *" $libdir "*) ;;
	  *) current_libdirs="$current_libdirs $libdir" ;;
	  esac
	else
	  # Note the libdir as a future libdir.
	  case "$future_libdirs " in
	  *" $libdir "*) ;;
	  *) future_libdirs="$future_libdirs $libdir" ;;
	  esac
	fi

	dir="`$echo "X$file" | $Xsed -e 's%/[^/]*$%%'`/"
	test "X$dir" = "X$file/" && dir=
	dir="$dir$objdir"

	# See the names of the shared library.
	set dummy $library_names
	if test -n "$2"; then
	  realname="$2"
	  shift
	  shift

	  # Install the shared library and build the symlinks.
	  $show "$install_prog $dir/$realname $destdir/$realname"
	  $run eval "$install_prog $dir/$realname $destdir/$realname" || exit $?

	  if test $# -gt 0; then
	    # Delete the old symlinks, and create new ones.
	    for linkname
	    do
	      if test "$linkname" != "$realname"; then
		$show "(cd $destdir && $rm $linkname && $LN_S $realname $linkname)"
		$run eval "(cd $destdir && $rm $linkname && $LN_S $realname $linkname)"
	      fi
	    done
	  fi

	  # Do each command in the postinstall commands.
	  lib="$destdir/$realname"
	  eval cmds=\"$postinstall_cmds\"
	  IFS="${IFS= 	}"; save_ifs="$IFS"; IFS='~'
	  for cmd in $cmds; do
	    IFS="$save_ifs"
	    $show "$cmd"
	    $run eval "$cmd" || exit $?
	  done
	  IFS="$save_ifs"
	fi

	# Install the pseudo-library for information purposes.
	name=`$echo "X$file" | $Xsed -e 's%^.*/%%'`
	instname="$dir/$name"i
	$show "$install_prog $instname $destdir/$name"
	$run eval "$install_prog $instname $destdir/$name" || exit $?

	# Maybe install the static library, too.
	test -n "$old_library" && staticlibs="$staticlibs $dir/$old_library"
	;;

      *.lo)
	# Install (i.e. copy) a libtool object.

	# Figure out destination file name, if it wasn't already specified.
	if test -n "$destname"; then
	  destfile="$destdir/$destname"
	else
	  destfile=`$echo "X$file" | $Xsed -e 's%^.*/%%'`
	  destfile="$destdir/$destfile"
	fi

	# Deduce the name of the destination old-style object file.
	case "$destfile" in
	*.lo)
	  staticdest=`$echo "X$destfile" | $Xsed -e "$lo2o"`
	  ;;
	*.o | *.obj)
	  staticdest="$destfile"
	  destfile=
	  ;;
	*)
	  $echo "$modename: cannot copy a libtool object to \`$destfile'" 1>&2
	  $echo "$help" 1>&2
	  exit 1
	  ;;
	esac

	# Install the libtool object if requested.
	if test -n "$destfile"; then
	  $show "$install_prog $file $destfile"
	  $run eval "$install_prog $file $destfile" || exit $?
	fi

	# Install the old object if enabled.
	if test "$build_old_libs" = yes; then
	  # Deduce the name of the old-style object file.
	  staticobj=`$echo "X$file" | $Xsed -e "$lo2o"`

	  $show "$install_prog $staticobj $staticdest"
	  $run eval "$install_prog \$staticobj \$staticdest" || exit $?
	fi
	exit 0
	;;

      *)
	# Figure out destination file name, if it wasn't already specified.
	if test -n "$destname"; then
	  destfile="$destdir/$destname"
	else
	  destfile=`$echo "X$file" | $Xsed -e 's%^.*/%%'`
	  destfile="$destdir/$destfile"
	fi

	# Do a test to see if this is really a libtool program.
	if (sed -e '4q' $file | egrep "^# Generated by .*$PACKAGE") >/dev/null 2>&1; then
	  link_against_libtool_libs=
	  relink_command=

	  # If there is no directory component, then add one.
	  case "$file" in
	  */* | *\\*) . $file ;;
	  *) . ./$file ;;
	  esac

	  # Check the variables that should have been set.
	  if test -z "$link_against_libtool_libs"; then
	    $echo "$modename: invalid libtool wrapper script \`$file'" 1>&2
	    exit 1
	  fi

	  finalize=yes
	  for lib in $link_against_libtool_libs; do
	    # Check to see that each library is installed.
	    libdir=
	    if test -f "$lib"; then
	      # If there is no directory component, then add one.
	      case "$lib" in
	      */* | *\\*) . $lib ;;
	      *) . ./$lib ;;
	      esac
	    fi
	    libfile="$libdir/`$echo "X$lib" | $Xsed -e 's%^.*/%%g'`"
	    if test -n "$libdir" && test ! -f "$libfile"; then
	      $echo "$modename: warning: \`$lib' has not been installed in \`$libdir'" 1>&2
	      finalize=no
	    fi
	  done

	  outputname=
	  if test "$fast_install" = no && test -n "$relink_command"; then
	    if test "$finalize" = yes && test -z "$run"; then
	      tmpdir="/tmp"
	      test -n "$TMPDIR" && tmpdir="$TMPDIR"
              tmpdir=`mktemp -d $tmpdir/libtool-XXXXXX 2> /dev/null`
              if test $? = 0 ; then :
              else
                tmpdir="$tmpdir/libtool-$$"
              fi
	      if $mkdir -p "$tmpdir" && chmod 700 "$tmpdir"; then :
	      else
		$echo "$modename: error: cannot create temporary directory \`$tmpdir'" 1>&2
		continue
	      fi
	      outputname="$tmpdir/$file"
	      # Replace the output file specification.
	      relink_command=`$echo "X$relink_command" | $Xsed -e 's%@OUTPUT@%'"$outputname"'%g'`

	      $show "$relink_command"
	      if $run eval "$relink_command"; then :
	      else
		$echo "$modename: error: relink \`$file' with the above command before installing it" 1>&2
		${rm}r "$tmpdir"
		continue
	      fi
	      file="$outputname"
	    else
	      $echo "$modename: warning: cannot relink \`$file'" 1>&2
	    fi
	  else
	    # Install the binary that we compiled earlier.
	    file=`$echo "X$file" | $Xsed -e "s%\([^/]*\)$%$objdir/\1%"`
	  fi
	fi

	$show "$install_prog$stripme $file $destfile"
	$run eval "$install_prog\$stripme \$file \$destfile" || exit $?
	test -n "$outputname" && ${rm}r "$tmpdir"
	;;
      esac
    done

    for file in $staticlibs; do
      name=`$echo "X$file" | $Xsed -e 's%^.*/%%'`

      # Set up the ranlib parameters.
      oldlib="$destdir/$name"

      $show "$install_prog $file $oldlib"
      $run eval "$install_prog \$file \$oldlib" || exit $?

      # Do each command in the postinstall commands.
      eval cmds=\"$old_postinstall_cmds\"
      IFS="${IFS= 	}"; save_ifs="$IFS"; IFS='~'
      for cmd in $cmds; do
	IFS="$save_ifs"
	$show "$cmd"
	$run eval "$cmd" || exit $?
      done
      IFS="$save_ifs"
    done

    if test -n "$future_libdirs"; then
      $echo "$modename: warning: remember to run \`$progname --finish$future_libdirs'" 1>&2
    fi

    if test -n "$current_libdirs"; then
      # Maybe just do a dry run.
      test -n "$run" && current_libdirs=" -n$current_libdirs"
      exec $SHELL $0 --finish$current_libdirs
      exit 1
    fi

    exit 0
    ;;

  # libtool finish mode
  finish)
    modename="$modename: finish"
    libdirs="$nonopt"
    admincmds=

    if test -n "$finish_cmds$finish_eval" && test -n "$libdirs"; then
      for dir
      do
	libdirs="$libdirs $dir"
      done

      for libdir in $libdirs; do
	if test -n "$finish_cmds"; then
	  # Do each command in the finish commands.
	  eval cmds=\"$finish_cmds\"
	  IFS="${IFS= 	}"; save_ifs="$IFS"; IFS='~'
	  for cmd in $cmds; do
	    IFS="$save_ifs"
	    $show "$cmd"
	    $run eval "$cmd" || admincmds="$admincmds
       $cmd"
	  done
	  IFS="$save_ifs"
	fi
	if test -n "$finish_eval"; then
	  # Do the single finish_eval.
	  eval cmds=\"$finish_eval\"
	  $run eval "$cmds" || admincmds="$admincmds
       $cmds"
	fi
      done
    fi

    # Exit here if they wanted silent mode.
    test "$show" = : && exit 0

    echo "----------------------------------------------------------------------"
    echo "Libraries have been installed in:"
    for libdir in $libdirs; do
      echo "   $libdir"
    done
    echo
    echo "If you ever happen to want to link against installed libraries"
    echo "in a given directory, LIBDIR, you must either use libtool, and"
    echo "specify the full pathname of the library, or use \`-LLIBDIR'"
    echo "flag during linking and do at least one of the following:"
    if test -n "$shlibpath_var"; then
      echo "   - add LIBDIR to the \`$shlibpath_var' environment variable"
      echo "     during execution"
    fi
    if test -n "$runpath_var"; then
      echo "   - add LIBDIR to the \`$runpath_var' environment variable"
      echo "     during linking"
    fi
    if test -n "$hardcode_libdir_flag_spec"; then
      libdir=LIBDIR
      eval flag=\"$hardcode_libdir_flag_spec\"

      echo "   - use the \`$flag' linker flag"
    fi
    if test -n "$admincmds"; then
      echo "   - have your system administrator run these commands:$admincmds"
    fi
    if test -f /etc/ld.so.conf; then
      echo "   - have your system administrator add LIBDIR to \`/etc/ld.so.conf'"
    fi
    echo
    echo "See any operating system documentation about shared libraries for"
    echo "more information, such as the ld(1) and ld.so(8) manual pages."
    echo "----------------------------------------------------------------------"
    exit 0
    ;;

  # libtool execute mode
  execute)
    modename="$modename: execute"

    # The first argument is the command name.
    cmd="$nonopt"
    if test -z "$cmd"; then
      $echo "$modename: you must specify a COMMAND" 1>&2
      $echo "$help"
      exit 1
    fi

    # Handle -dlopen flags immediately.
    for file in $execute_dlfiles; do
      if test ! -f "$file"; then
	$echo "$modename: \`$file' is not a file" 1>&2
	$echo "$help" 1>&2
	exit 1
      fi

      dir=
      case "$file" in
      *.la)
	# Check to see that this really is a libtool archive.
	if (sed -e '2q' $file | egrep "^# Generated by .*$PACKAGE") >/dev/null 2>&1; then :
	else
	  $echo "$modename: \`$lib' is not a valid libtool archive" 1>&2
	  $echo "$help" 1>&2
	  exit 1
	fi

	# Read the libtool library.
	dlname=
	library_names=

	# If there is no directory component, then add one.
	case "$file" in
	*/* | *\\*) . $file ;;
	*) . ./$file ;;
	esac

	# Skip this library if it cannot be dlopened.
	if test -z "$dlname"; then
	  # Warn if it was a shared library.
	  test -n "$library_names" && $echo "$modename: warning: \`$file' was not linked with \`-export-dynamic'"
	  continue
	fi

	dir=`$echo "X$file" | $Xsed -e 's%/[^/]*$%%'`
	test "X$dir" = "X$file" && dir=.

	if test -f "$dir/$objdir/$dlname"; then
	  dir="$dir/$objdir"
	else
	  $echo "$modename: cannot find \`$dlname' in \`$dir' or \`$dir/$objdir'" 1>&2
	  exit 1
	fi
	;;

      *.lo)
	# Just add the directory containing the .lo file.
	dir=`$echo "X$file" | $Xsed -e 's%/[^/]*$%%'`
	test "X$dir" = "X$file" && dir=.
	;;

      *)
	$echo "$modename: warning \`-dlopen' is ignored for non-libtool libraries and objects" 1>&2
	continue
	;;
      esac

      # Get the absolute pathname.
      absdir=`cd "$dir" && pwd`
      test -n "$absdir" && dir="$absdir"

      # Now add the directory to shlibpath_var.
      if eval "test -z \"\$$shlibpath_var\""; then
	eval "$shlibpath_var=\"\$dir\""
      else
	eval "$shlibpath_var=\"\$dir:\$$shlibpath_var\""
      fi
    done

    # This variable tells wrapper scripts just to set shlibpath_var
    # rather than running their programs.
    libtool_execute_magic="$magic"

    # Check if any of the arguments is a wrapper script.
    args=
    for file
    do
      case "$file" in
      -*) ;;
      *)
	# Do a test to see if this is really a libtool program.
	if (sed -e '4q' $file | egrep "^# Generated by .*$PACKAGE") >/dev/null 2>&1; then
	  # If there is no directory component, then add one.
	  case "$file" in
	  */* | *\\*) . $file ;;
	  *) . ./$file ;;
	  esac

	  # Transform arg to wrapped name.
	  file="$progdir/$program"
	fi
	;;
      esac
      # Quote arguments (to preserve shell metacharacters).
      file=`$echo "X$file" | $Xsed -e "$sed_quote_subst"`
      args="$args \"$file\""
    done

    if test -z "$run"; then
      if test -n "$shlibpath_var"; then
        # Export the shlibpath_var.
        eval "export $shlibpath_var"
      fi

      # Restore saved enviroment variables
      if test "${save_LC_ALL+set}" = set; then
	LC_ALL="$save_LC_ALL"; export LC_ALL
      fi
      if test "${save_LANG+set}" = set; then
	LANG="$save_LANG"; export LANG
      fi

      # Now actually exec the command.
      eval "exec \$cmd$args"

      $echo "$modename: cannot exec \$cmd$args"
      exit 1
    else
      # Display what would be done.
      if test -n "$shlibpath_var"; then
        eval "\$echo \"\$shlibpath_var=\$$shlibpath_var\""
        $echo "export $shlibpath_var"
      fi
      $echo "$cmd$args"
      exit 0
    fi
    ;;

  # libtool uninstall mode
  uninstall)
    modename="$modename: uninstall"
    rm="$nonopt"
    files=

    for arg
    do
      case "$arg" in
      -*) rm="$rm $arg" ;;
      *) files="$files $arg" ;;
      esac
    done

    if test -z "$rm"; then
      $echo "$modename: you must specify an RM program" 1>&2
      $echo "$help" 1>&2
      exit 1
    fi

    for file in $files; do
      dir=`$echo "X$file" | $Xsed -e 's%/[^/]*$%%'`
      test "X$dir" = "X$file" && dir=.
      name=`$echo "X$file" | $Xsed -e 's%^.*/%%'`

      rmfiles="$file"

      case "$name" in
      *.la)
	# Possibly a libtool archive, so verify it.
	if (sed -e '2q' $file | egrep "^# Generated by .*$PACKAGE") >/dev/null 2>&1; then
	  . $dir/$name

	  # Delete the libtool libraries and symlinks.
	  for n in $library_names; do
	    rmfiles="$rmfiles $dir/$n"
	  done
	  test -n "$old_library" && rmfiles="$rmfiles $dir/$old_library"

	  $show "$rm $rmfiles"
	  $run $rm $rmfiles

	  if test -n "$library_names"; then
	    # Do each command in the postuninstall commands.
	    eval cmds=\"$postuninstall_cmds\"
	    IFS="${IFS= 	}"; save_ifs="$IFS"; IFS='~'
	    for cmd in $cmds; do
	      IFS="$save_ifs"
	      $show "$cmd"
	      $run eval "$cmd"
	    done
	    IFS="$save_ifs"
	  fi

	  if test -n "$old_library"; then
	    # Do each command in the old_postuninstall commands.
	    eval cmds=\"$old_postuninstall_cmds\"
	    IFS="${IFS= 	}"; save_ifs="$IFS"; IFS='~'
	    for cmd in $cmds; do
	      IFS="$save_ifs"
	      $show "$cmd"
	      $run eval "$cmd"
	    done
	    IFS="$save_ifs"
	  fi

	  # FIXME: should reinstall the best remaining shared library.
	fi
	;;

      *.lo)
	if test "$build_old_libs" = yes; then
	  oldobj=`$echo "X$name" | $Xsed -e "$lo2o"`
	  rmfiles="$rmfiles $dir/$oldobj"
	fi
	$show "$rm $rmfiles"
	$run $rm $rmfiles
	;;

      *)
	$show "$rm $rmfiles"
	$run $rm $rmfiles
	;;
      esac
    done
    exit 0
    ;;

  "")
    $echo "$modename: you must specify a MODE" 1>&2
    $echo "$generic_help" 1>&2
    exit 1
    ;;
  esac

  $echo "$modename: invalid operation mode \`$mode'" 1>&2
  $echo "$generic_help" 1>&2
  exit 1
fi # test -z "$show_help"

# We need to display help for each of the modes.
case "$mode" in
"") $echo \
"Usage: $modename [OPTION]... [MODE-ARG]...

Provide generalized library-building support services.

    --config          show all configuration variables
    --debug           enable verbose shell tracing
-n, --dry-run         display commands without modifying any files
    --features        display basic configuration information and exit
    --finish          same as \`--mode=finish'
    --help            display this help message and exit
    --mode=MODE       use operation mode MODE [default=inferred from MODE-ARGS]
    --quiet           same as \`--silent'
    --silent          don't print informational messages
    --version         print version information

MODE must be one of the following:

      compile         compile a source file into a libtool object
      execute         automatically set library path, then run a program
      finish          complete the installation of libtool libraries
      install         install libraries or executables
      link            create a library or an executable
      uninstall       remove libraries from an installed directory

MODE-ARGS vary depending on the MODE.  Try \`$modename --help --mode=MODE' for
a more detailed description of MODE."
  exit 0
  ;;

compile)
  $echo \
"Usage: $modename [OPTION]... --mode=compile COMPILE-COMMAND... SOURCEFILE

Compile a source file into a libtool library object.

This mode accepts the following additional options:

  -o OUTPUT-FILE    set the output file name to OUTPUT-FILE
  -static           always build a \`.o' file suitable for static linking

COMPILE-COMMAND is a command to be used in creating a \`standard' object file
from the given SOURCEFILE.

The output file name is determined by removing the directory component from
SOURCEFILE, then substituting the C source code suffix \`.c' with the
library object suffix, \`.lo'."
  ;;

execute)
  $echo \
"Usage: $modename [OPTION]... --mode=execute COMMAND [ARGS]...

Automatically set library path, then run a program.

This mode accepts the following additional options:

  -dlopen FILE      add the directory containing FILE to the library path

This mode sets the library path environment variable according to \`-dlopen'
flags.

If any of the ARGS are libtool executable wrappers, then they are translated
into their corresponding uninstalled binary, and any of their required library
directories are added to the library path.

Then, COMMAND is executed, with ARGS as arguments."
  ;;

finish)
  $echo \
"Usage: $modename [OPTION]... --mode=finish [LIBDIR]...

Complete the installation of libtool libraries.

Each LIBDIR is a directory that contains libtool libraries.

The commands that this mode executes may require superuser privileges.  Use
the \`--dry-run' option if you just want to see what would be executed."
  ;;

install)
  $echo \
"Usage: $modename [OPTION]... --mode=install INSTALL-COMMAND...

Install executables or libraries.

INSTALL-COMMAND is the installation command.  The first component should be
either the \`install' or \`cp' program.

The rest of the components are interpreted as arguments to that command (only
BSD-compatible install options are recognized)."
  ;;

link)
  $echo \
"Usage: $modename [OPTION]... --mode=link LINK-COMMAND...

Link object files or libraries together to form another library, or to
create an executable program.

LINK-COMMAND is a command using the C compiler that you would use to create
a program from several object files.

The following components of LINK-COMMAND are treated specially:

  -all-static       do not do any dynamic linking at all
  -avoid-version    do not add a version suffix if possible
  -dlopen FILE      \`-dlpreopen' FILE if it cannot be dlopened at runtime
  -dlpreopen FILE   link in FILE and add its symbols to lt_preloaded_symbols
  -export-dynamic   allow symbols from OUTPUT-FILE to be resolved with dlsym(3)
  -export-symbols SYMFILE
		    try to export only the symbols listed in SYMFILE
  -export-symbols-regex REGEX
		    try to export only the symbols matching REGEX
  -LLIBDIR          search LIBDIR for required installed libraries
  -lNAME            OUTPUT-FILE requires the installed library libNAME
  -module           build a library that can dlopened
  -no-undefined     declare that a library does not refer to external symbols
  -o OUTPUT-FILE    create OUTPUT-FILE from the specified objects
  -release RELEASE  specify package release information
  -rpath LIBDIR     the created library will eventually be installed in LIBDIR
  -R[ ]LIBDIR       add LIBDIR to the runtime path of programs and libraries
  -static           do not do any dynamic linking of libtool libraries
  -version-info CURRENT[:REVISION[:AGE]]
		    specify library version info [each variable defaults to 0]

All other options (arguments beginning with \`-') are ignored.

Every other argument is treated as a filename.  Files ending in \`.la' are
treated as uninstalled libtool libraries, other files are standard or library
object files.

If the OUTPUT-FILE ends in \`.la', then a libtool library is created,
only library objects (\`.lo' files) may be specified, and \`-rpath' is
required, except when creating a convenience library.

If OUTPUT-FILE ends in \`.a' or \`.lib', then a standard library is created
using \`ar' and \`ranlib', or on Windows using \`lib'.

If OUTPUT-FILE ends in \`.lo' or \`.${objext}', then a reloadable object file
is created, otherwise an executable program is created."
  ;;

uninstall)
  $echo \
"Usage: $modename [OPTION]... --mode=uninstall RM [RM-OPTION]... FILE...

Remove libraries from an installation directory.

RM is the name of the program to use to delete files associated with each FILE
(typically \`/bin/rm').  RM-OPTIONS are options (such as \`-f') to be passed
to RM.

If FILE is a libtool library, all the files associated with it are deleted.
Otherwise, only FILE itself is deleted using RM."
  ;;

*)
  $echo "$modename: invalid operation mode \`$mode'" 1>&2
  $echo "$help" 1>&2
  exit 1
  ;;
esac

echo
$echo "Try \`$modename --help' for more information about other modes."

exit 0

# Local Variables:
# mode:shell-script
# sh-indentation:2
# End:
