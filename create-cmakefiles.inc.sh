# Copyright (C) 2024 Dan Arrhenius <dan@ultramarin.se>
#
# This file is part of create-simple-app
#
# create-simple-app is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

################################################################################
#
# Create a simple CMakeLists.txt
#
create_cmakefiles()
{
    CMAKEFILE="$DIR_NAME"/CMakeLists.txt

    touch $CMAKEFILE

    # The project name will be the same as the directory name
    if [ $EXTENSION = cpp ]; then
        CMAKE_LANG=CXX
    else
        CMAKE_LANG=C
    fi

    # Project name and installation directories
    #
    cat >>"$CMAKEFILE" <<EOF
cmake_minimum_required (VERSION 3.22)

# Project name and info
#
project ($PROJECT_NAME
    VERSION 0.0.1
    LANGUAGES $CMAKE_LANG
    DESCRIPTION "Enter a useful description here."
)

# Default GNU installation directories
#
include (GNUInstallDirs)
EOF

    # Add libraries
    #
    if [ -n "$DEPENDENCIES" ]; then
        echo "" >>$CMAKEFILE
        echo "# Dependencies" >>$CMAKEFILE
        echo "#" >>$CMAKEFILE
        echo "set (CMAKE_SKIP_RPATH True)" >>$CMAKEFILE
        echo "find_package(PkgConfig REQUIRED)" >>$CMAKEFILE
        for lib in $DEPENDENCIES; do
            lib_no_hyphen=`echo $lib | tr "-" "_"`
            echo "pkg_check_modules(${lib_no_hyphen} REQUIRED IMPORTED_TARGET ${lib})" >>$CMAKEFILE
        done
        echo "link_libraries (" >>$CMAKEFILE
        for lib in $DEPENDENCIES; do
            lib_no_hyphen=`echo $lib | tr "-" "_"`
            echo "    PkgConfig::${lib_no_hyphen}" >>$CMAKEFILE
        done
        for lib in $EXTRA_LIBS; do
            echo "    ${lib}" >>$CMAKEFILE
        done
        echo ")" >>$CMAKEFILE

    fi

    echo "" >>$CMAKEFILE
    echo "# Compiler flags" >>$CMAKEFILE
    echo "#" >>$CMAKEFILE
    echo "add_compile_options (-Wall -D_GNU_SOURCE)" >>$CMAKEFILE
    echo "" >>$CMAKEFILE


    # Apps
    #
    for app in $APPS; do
        app_no_hyphen=`echo $app | tr "-" "_"`

        echo "" >>$CMAKEFILE
        echo "add_executable ($app"  >>$CMAKEFILE
        echo "    ${app}.$EXTENSION" >>$CMAKEFILE
        echo ")" >>$CMAKEFILE
    done

    # Installation
    #
    echo "" >>$CMAKEFILE
    echo "" >>$CMAKEFILE
    echo "# Installation" >>$CMAKEFILE
    echo "#" >>$CMAKEFILE
    for app in $APPS; do
        echo "install (TARGETS $app)" >>$CMAKEFILE
    done


    #
    # Add CMakeLists.txt to the git repository
    #
    cd "$DIR_NAME" && git add CMakeLists.txt && cd "$CUR_DIR"


    #
    # Populate .gitignore
    #
    echo "CMakeCache.txt" >>"$DIR_NAME"/.gitignore
    echo "CMakeFiles/" >>"$DIR_NAME"/.gitignore
    echo "CPackConfig.cmake" >>"$DIR_NAME"/.gitignore
    echo "CPackSourceConfig.cmake" >>"$DIR_NAME"/.gitignore
    echo "Makefile" >>"$DIR_NAME"/.gitignore
    echo "cmake_install.cmake" >>"$DIR_NAME"/.gitignore
    cd "$DIR_NAME" && git add .gitignore && cd "$CUR_DIR"
}
