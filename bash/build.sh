#!/bin/bash

set -e


# ---------
# VARIABLES
# ---------
DIR=`dirname $BASH_SOURCE`
VERSION="master" # version. can be overriden using --version
RELEASE="1" # release. can be override using --release
TARGET=$DIR/../target  #output directory for RPMS and TARGZ
RPMTARGET=$TARGET/rpm
TARTARGET=$TARGET/tar
MODE="build"
PROJECT_NAME=""
SOURCEDIR=""
SPECFILE=""

# ------------
# EXIT HANDLER
# ------------
clean_exit() {
    local exit_status=${1:-$?}
    echo rpmbuild helper exiting $0 with $exit_status
    exit $exit_status    
}

trap 'clean_exit 1' TERM HUP QUIT INT


# ------------
# HELP MESSAGE
# ------------
message() {
  cat << EOF
usage: build [ -m | -p | -s | -t | -v | -r ]
options:

-m, --mode (build | clean)
-p, --project (project name. becomes RPM name)
-s, --specfile (path to spec file)
-t, --sourcedir (path to directory containing either unbuilt source or built stuff)
-v, --version (becomes RPM version)
-r, --release (becomes RPM release) 

EOF

  clean_exit 1
}


# -------------
# OPTION PARSER
# -------------
parse_options() {

  while [[ -n "$1" ]]; do

    case "$1" in
      -h|--help) message ;;
      --) break ;;
      -m|--mode) shift;         MODE="$1" ;;
      -p|--project) shift;      PROJECT_NAME="$1";; 
      -s|--specfile) shift;     SPECFILE="$1";; 
      -f|--sourcedir) shift;    SOURCEDIR="$1" ;;
      -v|--version) shift;      VERSION="$1" ;;
      -r|--release) shift;      RELEASE="$1" ;;
      -*) echo "invalid argument '$1'"; message ;;
    esac
    shift
  done

  # check arguments

 }

# ------------------
# CORE BUILD ROUTINE
# ------------------
build() {

    # project can't be empty
    if [ "$PROJECT_NAME" = "" ]; then
        echo "--project required"
        message
    fi

    # specfile can't be empty
    if [ "$SPECFILE" = "" ]; then
        echo "--specfile required"
        message
    fi

    # tarfile can't be empty
    if [ "$SOURCEDIR" = "" ]; then
        echo "--sourcedir required"
        message
    fi

    # make output dir
    mkdir -p $TARGET
    mkdir -p $RPMTARGET
    mkdir -p $TARTARGET

    VERSIONED_SRC_DIRNAME=$PROJECT_NAME-$VERSION

    # create properly named directory to use in tar'ing
    mkdir -p $TARTARGET/$VERSIONED_SRC_DIRNAME

    # copy contents of source dir to this tarrable directory
    cp -r $SOURCEDIR $TARTARGET/$VERSIONED_SRC_DIRNAME
    
    # tar it up
    pushd $TARTARGET
        tar -czf $PROJECT_NAME-$VERSION-$RELEASE.tar.gz $VERSIONED_SRC_DIRNAME
    popd
    
    # set up standard rpmbuild directory structure
    rpmdev-setuptree

    # mv properly-formatted tar to rpmbuild standard location
    mv $TARTARGET/$PROJECT_NAME-$VERSION-$RELEASE.tar.gz ~/rpmbuild/SOURCES
   
    # copy specfile to rpmbuild standard location
    cp $SPECFILE ~/rpmbuild/SPECS/$PROJECT_NAME.spec

    # build rpm
    rpmbuild-md5 -ba ~/rpmbuild/SPECS/$PROJECT_NAME.spec --define="project_release $RELEASE" --define="project_version $VERSION" --define="project_name $PROJECT_NAME"
    
    # pull out rpm
    mv ~/rpmbuild/RPMS/**/$PROJECT_NAME*.rpm $RPMTARGET
}

# ------------------
# CORE CLEAN ROUTINE
# ------------------
clean()
{
    rm -rf $TARGET
}

if [[ $EUID -eq 0 ]]; then
	echo "You can not be root to package"
	exit 1
fi

parse_options "$@"

if [ "$MODE" = "build" ]; then
    build
elif [ "$MODE" = "clean" ]; then
    clean
else
    echo "unknown mode. must be 'build' or 'clean'"
    message
fi

clean_exit
