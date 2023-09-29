#!/bin/bash

# Copyright (C) 2022,2023 Dan Arrhenius <dan@ultramarin.se>
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
    echo "       -d <project_dir>   Project directory to create. Default is the name of the first app."
    echo "       -c                 Project language: C"
    echo "       -p                 Project language: C++ (default)"
    echo "       -l <libname>       Add a library dependency. It moust be found with pkg-config"
    echo "       -L <libname>       Add a hard coded library to link with, not including the prefix 'lib' in the name"
    echo "       -a <git author>    Specify the git author name"
    echo "       -e <author email>  Specify the git author email address"
    echo "       -h                 Print this help and exit"
    echo ""
}

CUR_DIR=`pwd`
TEMPLATE_DIR=$(dirname $(readlink -f "$0"))/create-simple-app

APPS=""
DIR_NAME=""
EXTENSION=cpp
HDR_EXTENSION=hpp
GIT_AUTHOR=""
GIT_EMAIL=""
DEPENDENCIES=""
EXTRA_LIBS=""

if [ -z $PKG_CONFIG ]; then
    PKG_CONFIG=${CROSS_COMPILE}pkg-config
fi

while getopts ":d:cpga:e:l:L:h" opt; do
    case $opt in
	d) DIR_NAME=$OPTARG ;;
	c) EXTENSION=c; HDR_EXTENSION=h ;;
	p) EXTENSION=cpp; HDR_EXTENSION=hpp ;;
	a) GIT_AUTHOR=$OPTARG ;;
	e) GIT_EMAIL=$OPTARG ;;
	l) DEPENDENCIES="$DEPENDENCIES $OPTARG"
	   if ! $PKG_CONFIG --exists $OPTARG >/dev/null 2>&1; then
	       echo "Warning: Can't find library '$OPTARG' using $PKG_CONFIG" >&2
	   fi
	   ;;
	L) EXTRA_LIBS="$EXTRA_LIBS $OPTARG"
	   ;;
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
# Set project directory name if not already set
#
if [ -z "$DIR_NAME" ]; then
    DIR_NAME="$1"
fi
MAKEFILE="$DIR_NAME"/Makefile


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



#
# Init git
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


#
# Create source files and add them to the git repository
#
HDR_EXTENSION_UPPER=`echo $HDR_EXTENSION | tr [a-z] [A-Z]`
for app in $APPS; do
    app_upper=`echo $app | tr [a-z] [A-Z] | tr "-" "_"`
    if ! cp "$TEMPLATE_DIR"/app-template.$EXTENSION "$DIR_NAME"/"$app".$EXTENSION; then
	exit 1
    fi
    if [ $EXTENSION = cpp ]; then
	if ! cp "$TEMPLATE_DIR"/appargs-template.$EXTENSION "$DIR_NAME"/"$app"-appargs.$EXTENSION; then
	    exit 1
	fi
	if ! cp "$TEMPLATE_DIR"/appargs-template.$HDR_EXTENSION "$DIR_NAME"/"$app"-appargs.$HDR_EXTENSION; then
	    exit 1
	fi
	sed -i s/APPARGS_H/"$app_upper"_APPARGS_$HDR_EXTENSION_UPPER/g "$DIR_NAME"/"$app"-appargs.$HDR_EXTENSION
	sed -i s/APPARGS_H/"$app"-appargs.$HDR_EXTENSION/g             "$DIR_NAME"/"$app"-appargs.$EXTENSION
	sed -i s/APPARGS_H/"$app"-appargs.$HDR_EXTENSION/g             "$DIR_NAME"/"$app".$EXTENSION
    fi
    cd "$DIR_NAME" && git add "$app".$EXTENSION && cd "$CUR_DIR"
    if [ $EXTENSION = cpp ]; then
        cd "$DIR_NAME" && git add "$app"-appargs.$EXTENSION && cd "$CUR_DIR"
        cd "$DIR_NAME" && git add "$app"-appargs.$HDR_EXTENSION && cd "$CUR_DIR"
    fi
    echo "$app" >>"$DIR_NAME"/.gitignore
done
cd "$DIR_NAME" && git add .gitignore && cd "$CUR_DIR"



######################################################################
# Create makefile
#

# Add application target(s)
#
touch "$MAKEFILE"
echo "APPS=" >>"$MAKEFILE"
for app in $APPS; do
    echo "APPS+=$app" >>"$MAKEFILE"
done
echo "" >>"$MAKEFILE"
for app in $APPS; do
    app_no_hyphen=`echo $app | tr "-" "_"`
    echo "APP_OBJS_$app_no_hyphen=${app}.o" >>"$MAKEFILE"
    if [ $EXTENSION = cpp ]; then
        echo "APP_OBJS_$app_no_hyphen+=${app}-appargs.o" >>"$MAKEFILE"
    fi
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
CFLAGS=-pipe -Wall -O2 -g -I.
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


echo "" >>"$MAKEFILE"
echo "CXXFLAGS=\$(CFLAGS)" >>"$MAKEFILE"


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
