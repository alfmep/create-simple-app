#!/bin/bash

# Copyright (C) 2022-2024 Dan Arrhenius <dan@ultramarin.se>
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



function print_help() {
    echo ""
    echo "Usage: create-simple-app.sh [OPTIONS] <app_name1> [app_name2 ...]"
    echo "       -m                 Create a simple Makefile project. This is the default."
    echo "       -k                 Create a simple CMake project instead of a simple Makefile project."
    echo "       -t                 Create a simple autotools project instead of a simple Makefile project."
    echo "       -p                 Project language: C++ (default)"
    echo "       -c                 Project language: C"
    echo "       -l <libname>       Add a library dependency. It moust be found with pkg-config"
    echo "       -L <libname>       Add a hard coded library to link with, not including the prefix 'lib' in the name"
    echo "       -d <project_dir>   Project directory to create. Default is the name of the first app."
    echo "                          This will also be the name of the project."
    echo "       -a <git author>    Specify the git author name"
    echo "       -e <author email>  Specify the git author email address"
    echo "       -h                 Print this help and exit"
    echo ""
}

CUR_DIR=`pwd`
TEMPLATE_BASE_DIR=$(dirname $(readlink -f "$0"))
TEMPLATE_DIR=$TEMPLATE_BASE_DIR/app-template

APPS=""
DIR_NAME=""
EXTENSION=cpp
HDR_EXTENSION=hpp
DEPENDENCIES=""
EXTRA_LIBS=""
USE_CMAKE=no
PROJECT_TYPE=makefile
GIT_AUTHOR=""
GIT_EMAIL=""

if [ -z $PKG_CONFIG ]; then
    PKG_CONFIG=${CROSS_COMPILE}pkg-config
fi

while getopts "mktpcl:L:d:a:e:h" opt; do
    case $opt in
	m) PROJECT_TYPE=makefile ;;
	k) PROJECT_TYPE=cmake ;;
	t) PROJECT_TYPE=autotools ;;
	p) EXTENSION=cpp; HDR_EXTENSION=hpp ;;
	c) EXTENSION=c; HDR_EXTENSION=h ;;
	l) DEPENDENCIES="$DEPENDENCIES $OPTARG"
	   if ! $PKG_CONFIG --exists $OPTARG >/dev/null 2>&1; then
	       echo "Warning: Can't find library '$OPTARG' using $PKG_CONFIG" >&2
	   fi
	   ;;
	L) EXTRA_LIBS="$EXTRA_LIBS $OPTARG"
	   ;;
	d) DIR_NAME=$OPTARG ;;
	a) GIT_AUTHOR=$OPTARG ;;
	e) GIT_EMAIL=$OPTARG ;;
	h) print_help; exit 0 ;;
	:)
	    echo "Missing directory name for option -$OPTARG" >&2
	    echo "Use option -h for help" >&2
	    exit 1
	;;

	\?)
	    echo "Invalid option: -$OPTARG" >&2
	    echo "Use option -h for help" >&2
	    exit 1
	;;
    esac
done
shift $((OPTIND-1))


#
# Check for missing application name(s)
#
if [ -z "$1" ]; then
    echo "Missing application name" >&2
    echo "Use option -h for help" >&2
    exit 1
fi


#
# Set project and directory name if not already set
#
if [ -z "$DIR_NAME" ]; then
    DIR_NAME="$1"
fi
PROJECT_NAME=$DIR_NAME


#
# Create project directory
#
if [ -d "$DIR_NAME" ]; then
    echo "Error: directory '$DIR_NAME' already exits" >&2
    exit 1
fi
if ! mkdir -p "$DIR_NAME"; then
    exit 1
fi


#
# Get the application name(s)
#
while ! [ -z "$1" ]; do
    APPS="$APPS $1"
    shift 1
done



initialize_git()
{
    #
    # Initialize git
    #
    git init "$DIR_NAME"
    if ! [ -z "$GIT_AUTHOR" ]; then
        cd "$DIR_NAME" && git config user.name "$GIT_AUTHOR" && cd "$CUR_DIR"
    fi
    if ! [ -z "$GIT_EMAIL" ]; then
        cd "$DIR_NAME" && git config user.email "$GIT_EMAIL" && cd "$CUR_DIR"
    fi
    echo "*.o" >"$DIR_NAME"/.gitignore
    echo "*.d" >>"$DIR_NAME"/.gitignore
}


create_source_files()
{
    #
    # Create source files and add them to the git repository
    #
    HDR_EXTENSION_UPPER=`echo $HDR_EXTENSION | tr [a-z] [A-Z]`
    for app in $APPS; do
        app_upper=`echo $app | tr [a-z] [A-Z] | tr "-" "_"`
        if ! cp "$TEMPLATE_DIR"/app-template.$EXTENSION "$DIR_NAME"/"$app".$EXTENSION; then
	    exit 1
        fi
        cd "$DIR_NAME" && git add "$app".$EXTENSION && cd "$CUR_DIR"
        if [ "$PROJECT_TYPE" = makefile ]; then
            echo "$app" >>"$DIR_NAME"/.gitignore
        fi
    done
    cd "$DIR_NAME" && git add .gitignore && cd "$CUR_DIR"
}



initialize_git
create_source_files

case $PROJECT_TYPE in
    makefile)
        source $TEMPLATE_BASE_DIR/create-makefile.inc.sh
        create_makefile
        ;;
    autotools)
        source $TEMPLATE_BASE_DIR/create-autotools.inc.sh
        create_autotools
        ;;
    cmake)
        source $TEMPLATE_BASE_DIR/create-cmakefiles.inc.sh
        create_cmakefiles
        ;;
esac
