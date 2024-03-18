################################################################################
#
# Create a simple makefile
#
create_makefile()
{
    MAKEFILE="$DIR_NAME"/Makefile
    touch "$MAKEFILE"

    # Add application target(s)
    #
    echo "APPS=" >>"$MAKEFILE"
    for app in $APPS; do
        echo "APPS+=$app" >>"$MAKEFILE"
    done
    echo "" >>"$MAKEFILE"
    for app in $APPS; do
        app_no_hyphen=`echo $app | tr "-" "_"`
        echo "APP_OBJS_$app_no_hyphen=${app}.o" >>"$MAKEFILE"
#        if [ $EXTENSION = cpp ]; then
#            echo "APP_OBJS_$app_no_hyphen+=${app}-appargs.o" >>"$MAKEFILE"
#        fi
        echo "DEP_FILES_${app_no_hyphen}=\$(addsuffix .d,\$(basename \$(APP_OBJS_${app_no_hyphen})))" >>"$MAKEFILE"
        echo "" >>"$MAKEFILE"
    done

    # Add compiler tools and common flags
    #
    echo "" >>"$MAKEFILE"
    cat >>"$MAKEFILE" <<EOF
#
# Tools
#
CC=\$(CROSS_COMPILE)gcc
CXX=\$(CROSS_COMPILE)g++
LD=\$(CROSS_COMPILE)ld
STRIP=\$(CROSS_COMPILE)strip
PKG_CONFIG=\$(CROSS_COMPILE)pkg-config


#
# Flags
#
DEFINES=-D_GNU_SOURCE
CPPFLAGS=-MMD \$(DEFINES)
CFLAGS=-pipe -Wall -I.
#
# By default, use debug flags.
# For release flags, run 'make RELEASE=1'
#
ifneq (\$(RELEASE),1)
CFLAGS+=-Og -g
else
CFLAGS+=-O3
endif
EOF


    # Add lib dependencies
    #
    for lib in $DEPENDENCIES; do
        echo "CFLAGS+=\$(shell \$(PKG_CONFIG) --cflags $lib)" >>"$MAKEFILE"
    done
    if ! [ -z "$DEPENDENCIES" ]; then
        echo "" >>"$MAKEFILE"
    fi
    echo "LDFLAGS=" >>"$MAKEFILE"
    for lib in $DEPENDENCIES; do
        echo "LDFLAGS+=\$(shell \$(PKG_CONFIG) --libs $lib)" >>"$MAKEFILE"
    done
    for lib in $EXTRA_LIBS; do
        echo "LDFLAGS+=-l$lib" >>"$MAKEFILE"
    done


    # Add C++ flags (same as CFLAGS)
    #
    cat >>"$MAKEFILE" <<EOF

#
# C++ flags are by default the same as C flags
#
CXXFLAGS=\$(CFLAGS)
EOF


    # Add check for SYSROOT_DIR
    #
    cat >>"$MAKEFILE" <<EOF

#
# Check for specific sysroot
#
ifneq (\$(SYSROOT_DIR),)
CFLAGS+=--sysroot=\$(SYSROOT_DIR)
LDFLAGS+=--sysroot=\$(SYSROOT_DIR)
endif
EOF



    # Add rules
    #
    echo "" >>"$MAKEFILE"
    echo "" >>"$MAKEFILE"
    cat >>"$MAKEFILE" <<EOF
#
# Rules
#
all:	\$(APPS)
EOF

    echo "" >>"$MAKEFILE"
    for app in $APPS; do
        app_no_hyphen=`echo $app | tr "-" "_"`
        echo "" >>"$MAKEFILE"
        if [ "$EXTENSION" == "cpp" ];then
	   cat >>"$MAKEFILE" <<EOF
$app:	\$(APP_OBJS_$app_no_hyphen)
	\$(CXX) \$(CXXFLAGS) -o \$@ \$^ \$(LDFLAGS)
EOF
           else
	       cat >>"$MAKEFILE" <<EOF
$app:	\$(APP_OBJS_$app_no_hyphen)
	\$(CC) \$(CFLAGS) -o \$@ \$^ \$(LDFLAGS)
EOF
        fi
    done


    echo "" >>"$MAKEFILE"
    echo "" >>"$MAKEFILE"
    cat >>"$MAKEFILE" <<EOF
clean:
	rm -f \$(APPS) *.o *.d
EOF

    echo "" >>"$MAKEFILE"
    cat >>"$MAKEFILE" <<EOF
#
# Dependencies
#
EOF
    for app in $APPS; do
        app_no_hyphen=`echo $app | tr "-" "_"`
        echo "-include \$(DEP_FILES_${app_no_hyphen})" >>"$MAKEFILE"
    done


    #
    # Add makefile to the git repository
    #
    cd "$DIR_NAME" && git add Makefile && cd "$CUR_DIR"
}
