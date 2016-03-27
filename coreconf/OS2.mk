#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

MOZ_WIDGET_TOOLKIT = os2

# XP_PC is for Window and OS2 on Intel X86
# XP_OS2 is strictly for OS2 only
XP_DEFINE  += -DXP_PC=1  -DXP_OS2=1

# Override prefix
LIB_PREFIX  = $(NULL)

# Override suffix in suffix.mk
LIB_SUFFIX  = a
# the DLL_SUFFIX must be uppercase for FIPS mode to work. bugzilla 240784
DLL_SUFFIX  = dll
PROG_SUFFIX = .exe


CCC			= gcc
LINK			= gcc
AR                      = ar r $@
# Keep AR_FLAGS blank so that we do not have to change rules.mk
AR_FLAGS                = 
RANLIB 			= @echo OS2 RANLIB
BSDECHO 		= @echo OS2 BSDECHO
IMPLIB			= emximp -o
FILTER			= emxexp -o

# GCC for OS/2 currently predefines these, but we don't want them
DEFINES 		+= -Uunix -U__unix -U__unix__

ifeq ($(MOZ_OS2_HIGH_MEMORY),1)
HIGHMEM_LDFLAG          = -Zhigh-mem
endif

ifndef NO_SHARED_LIB
WRAP_MALLOC_LIB         = 
WRAP_MALLOC_CFLAGS      = 
DSO_CFLAGS              = 
DSO_PIC_CFLAGS          = 
MKSHLIB                 = $(CXX) $(CXXFLAGS) $(DSO_LDOPTS) -o $@
MKCSHLIB                = $(CC) $(CFLAGS) $(DSO_LDOPTS) -o $@
MKSHLIB_FORCE_ALL       = 
MKSHLIB_UNFORCE_ALL     = 
DSO_LDOPTS              = -Zomf -Zdll -Zmap $(HIGHMEM_LDFLAG)
SHLIB_LDSTARTFILE	= 
SHLIB_LDENDFILE		= 
ifdef MAPFILE
MKSHLIB += $(MAPFILE)
endif
PROCESS_MAP_FILE = \
	echo LIBRARY $(LIBRARY_NAME)$(LIBRARY_VERSION) INITINSTANCE TERMINSTANCE > $@; \
	echo PROTMODE >> $@; \
	echo CODE    LOADONCALL MOVEABLE DISCARDABLE >> $@; \
	echo DATA    PRELOAD MOVEABLE MULTIPLE NONSHARED >> $@; \
	echo EXPORTS >> $@; \
	grep -v ';+' $< | grep -v ';-' | \
	sed -e 's; DATA ;;' -e 's,;;,,' -e 's,;.*,,' -e 's,\([\t ]*\),\1_,' | \
	awk 'BEGIN {ord=1;} { print($$0 " @" ord " RESIDENTNAME"); ord++;}' >> $@

endif   #NO_SHARED_LIB

OS_CFLAGS          = -Wall -Wno-unused -Wpointer-arith -Wcast-align -Wno-switch

ifdef BUILD_OPT
ifeq (11,$(ALLOW_OPT_CODE_SIZE)$(OPT_CODE_SIZE))
	OPTIMIZER += -Os
else
	OPTIMIZER += -O2
endif
DEFINES 		+= -UDEBUG -U_DEBUG -DNDEBUG
else    # BUILD_OPT
DEFINES 		+= -DDEBUG -D_DEBUG -DDEBUGPRINTS     #HCT Need += to avoid overidding manifest.mn 
endif   # BUILD_OPT

LDFLAGS 		= -Zomf -Zmap $(HIGHMEM_LDFLAG)

ifdef MOZ_DEBUG_SYMBOLS
DSO_LDOPTS      += -g
LDFLAGS         += -g
else
DSO_LDOPTS      += -s
LDFLAGS         += -s
endif

ifdef BUILD_TREE
NSINSTALL_DIR  = $(BUILD_TREE)/nss
NSINSTALL      = $(BUILD_TREE)/nss/nsinstall.exe
else
NSINSTALL_DIR  = $(CORE_DEPTH)/coreconf/nsinstall
NSINSTALL      = $(NSINSTALL_DIR)/$(OBJDIR_NAME)/nsinstall.exe
endif

MKDEPEND_DIR    = $(CORE_DEPTH)/coreconf/mkdepend
MKDEPEND        = $(MKDEPEND_DIR)/$(OBJDIR_NAME)/mkdepend
MKDEPENDENCIES  = $(OBJDIR_NAME)/depend.mk

####################################################################
#
# One can define the makefile variable NSDISTMODE to control
# how files are published to the 'dist' directory.  If not
# defined, the default is "install using relative symbolic
# links".  The two possible values are "copy", which copies files
# but preserves source mtime, and "absolute_symlink", which
# installs using absolute symbolic links.
#   - THIS IS NOT PART OF THE NEW BINARY RELEASE PLAN for 9/30/97
#   - WE'RE KEEPING IT ONLY FOR BACKWARDS COMPATIBILITY
####################################################################

ifeq ($(NSDISTMODE),copy)
	# copy files, but preserve source mtime
	INSTALL  = $(NSINSTALL)
	INSTALL += -t
else
	ifeq ($(NSDISTMODE),absolute_symlink)
		# install using absolute symbolic links
		INSTALL  = $(NSINSTALL)
		INSTALL += -L `pwd`
	else
		# install using relative symbolic links
		INSTALL  = $(NSINSTALL)
		INSTALL += -R
	endif
endif

define MAKE_OBJDIR
if test ! -d $(@D); then rm -rf $(@D); $(NSINSTALL) -D $(@D); fi
endef

#
# override the definition of DLL_PREFIX in prefix.mk
#

ifndef DLL_PREFIX
    DLL_PREFIX = $(NULL)
endif

#
# override the TARGETS defined in ruleset.mk, adding IMPORT_LIBRARY
#
ifndef TARGETS
    TARGETS = $(LIBRARY) $(SHARED_LIBRARY) $(IMPORT_LIBRARY) $(PROGRAM)
endif


ifdef LIBRARY_NAME
    IMPORT_LIBRARY = $(OBJDIR)/$(LIBRARY_NAME)$(LIBRARY_VERSION)$(JDK_DEBUG_SUFFIX).$(LIB_SUFFIX)
endif


DEBUG_SYMFILE =
DEBUG_SYMFILE_GEN =

ifndef MOZ_DEBUG
ifdef MOZ_DEBUG_SYMBOLS
ifneq ($(filter WLINK wlink,$(EMXOMFLD_TYPE)),)
DEBUG_SYMFILE = $(basename $(1)).dbg
DSO_LDOPTS += -Zlinker 'option symfile=$(basename $(@)).dbg'
LDFLAGS += -Zlinker 'option symfile=$(basename $(@)).dbg'
endif
endif
ifndef DEBUG_SYMFILE
DEBUG_SYMFILE = $(basename $(1)).xqs
DEBUG_SYMFILE_GEN = mapxqs $(basename $(1)).map -o $(basename $(1)).xqs
endif
endif
