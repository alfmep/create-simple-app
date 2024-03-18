################################################################################
#
# Create a simple autotools project
#
create_configure_ac()
{
    CONFIGURE_AC=$DIR_NAME/configure.ac

    cat >$CONFIGURE_AC <<EOF
AC_INIT([${PROJECT_NAME}], [0.0.1])
AM_INIT_AUTOMAKE([-Wall -Werror foreign dist-bzip2])

LT_INIT()
EOF
    if [ $EXTENSION = cpp ]; then
        echo "AC_PROG_CXX" >>$CONFIGURE_AC
    else
        echo "AC_PROG_CC" >>$CONFIGURE_AC
    fi

    cat >>$CONFIGURE_AC <<EOF
AC_PROG_MKDIR_P
AC_PROG_INSTALL

AC_CONFIG_MACRO_DIR([m4])
AM_SILENT_RULES([yes])
EOF

    # Add lib dependencies
    #
    for lib in $DEPENDENCIES; do
        lib_no_hyphen=`echo $lib | tr "-" "_"`
        echo "" >>$CONFIGURE_AC
        cat >>$CONFIGURE_AC <<EOF
PKG_CHECK_MODULES([${lib_no_hyphen}],
    [${lib}],,
    [AC_MSG_ERROR(Could not find ${lib})])
AC_SUBST([${lib_no_hyphen}_CFLAGS])
AC_SUBST([${lib_no_hyphen}_LIBS])
EOF
    done

    # Add static library flags
    #


    echo "" >>$CONFIGURE_AC
    cat >>$CONFIGURE_AC <<EOF
AC_CONFIG_FILES([
	Makefile
])

AC_OUTPUT
EOF

    # Add configure.ac to the git repository
    #
    cd "$DIR_NAME" && git add configure.ac && cd "$CUR_DIR"
}


create_makefile_am()
{
    MAKEFILE_AM=$DIR_NAME/Makefile.am

    cat >$MAKEFILE_AM <<EOF
ACLOCAL_AMFLAGS=-I m4

AM_CPPFLAGS = -D_GNU_SOURCE -DSYSCONFDIR='"\${sysconfdir}"' -DLOCALSTATEDIR='"\${localstatedir}"'
EOF
    if [ $EXTENSION = cpp ]; then
        echo "AM_CXXFLAGS = -Wall -pipe -O2 -g" >>$MAKEFILE_AM
    else
        echo "AM_CFLAGS = -Wall -pipe -O2 -g" >>$MAKEFILE_AM
    fi
    echo "AM_LDFLAGS =" >>$MAKEFILE_AM
    echo "" >>$MAKEFILE_AM


    # Add dependencies
    #
    for lib in $DEPENDENCIES; do
        lib_no_hyphen=`echo $lib | tr "-" "_"`
        if [ $EXTENSION = cpp ]; then
            echo "AM_CXXFLAGS += \$(${lib_no_hyphen}_CFLAGS)" >>$MAKEFILE_AM
        else
            echo "AM_CFLAGS += \$(${lib_no_hyphen}_CFLAGS)" >>$MAKEFILE_AM
        fi
    done
    echo "" >>$MAKEFILE_AM
    for lib in $DEPENDENCIES; do
        lib_no_hyphen=`echo $lib | tr "-" "_"`
        echo "AM_LDFLAGS += \$(${lib_no_hyphen}_LIBS)" >>$MAKEFILE_AM
    done
    for lib in $EXTRA_LIBS; do
        echo "AM_LDFLAGS += -l${lib}" >>$MAKEFILE_AM
    done

    echo "" >>$MAKEFILE_AM


    # Add application(s)
    #
    echo "" >>$MAKEFILE_AM
    echo "bin_PROGRAMS = " >>$MAKEFILE_AM
    for app in $APPS; do
        app_no_hyphen=`echo $app | tr "-" "_"`
        echo "" >>$MAKEFILE_AM
        echo "bin_PROGRAMS += $app" >>$MAKEFILE_AM
        echo "${app_no_hyphen}_SOURCES  =" >>$MAKEFILE_AM
        echo "${app_no_hyphen}_SOURCES += ${app}.$EXTENSION" >>$MAKEFILE_AM
    done



    # Add Makefile.am to the git repository
    #
    cd "$DIR_NAME" && git add Makefile.am && cd "$CUR_DIR"
}


populate_gitignore()
{
    echo "/Makefile.in" >>$DIR_NAME/.gitignore
    echo "/aclocal.m4" >>$DIR_NAME/.gitignore
    echo "/autom4te.cache" >>$DIR_NAME/.gitignore
    echo "/compile" >>$DIR_NAME/.gitignore
    echo "/config.guess" >>$DIR_NAME/.gitignore
    echo "/config.sub" >>$DIR_NAME/.gitignore
    echo "/configure" >>$DIR_NAME/.gitignore
    echo "/depcomp" >>$DIR_NAME/.gitignore
    echo "/install-sh" >>$DIR_NAME/.gitignore
    echo "/ltmain.sh" >>$DIR_NAME/.gitignore
    echo "/m4" >>$DIR_NAME/.gitignore
    echo "/missing" >>$DIR_NAME/.gitignore

    cd "$DIR_NAME" && git add .gitignore && cd "$CUR_DIR"
}



create_autotools()
{
    create_configure_ac
    create_makefile_am
    populate_gitignore

    cp $TEMPLATE_BASE_DIR/autogen.sh $DIR_NAME/
    chmod +x $DIR_NAME/autogen.sh
    cd "$DIR_NAME" && git add autogen.sh && cd "$CUR_DIR"
}
