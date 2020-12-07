#!/bin/bash
#
# usage: minebuilder.sh          batch mode NB: builds flymine by default
#        mk=inebuilder.sh -H     batch mode, builds humanmine
#        minebuilder.sh -i       interactive (crude step by step) mode
#

# TODO: exit if wrong switchs combination
#

# default settings: edit with care
INTERACT=n       # y: step by step interaction
SWAP=n           # y: swap db
GETDATA=n        # y: run the download script?
DSONLY=n         # y: just update the sources (don't build)
MAPONLY=n        # y: just do the sitemap (just that!)
BUILD=y          # n: don't run the build
FLYBASE=n        # y: get FB files and build FB db


MINE=flymine
REL=""
  

# tmp until we fix .bashrc
#export JAVA_HOME=""

progname=$0

function usage () {
	cat <<EOF

Usage:
$progname [-F] [-H] [-S] [-M] [-d] [-i] [-s] [-r release]
  -F: build flymine
  -H: build humanmine
  -M: just do the sitemap
  -S: just get the sources (no build)
  -d: no checking of sources for update
  -r: the release number
	-i: interactive mode
	-s: no swapping of build db (for example after a build fail)
	-v: verbode mode

examples:

$progname			do the release without asking for permission..
$progname -i      		interactive version (for step by step release)
$progname -s      		do the release without swapping db
$progname -is      		interactive version without swapping

EOF
	exit 0
}


while getopts "FHSMdisnfr:" opt; do
   case $opt in
        F )  echo "- building FLYMINE" ; MINE=flymine;;
        H )  echo "- building HUMANMINE" ; MINE=humanmine;;        
        S )  echo "- Just updating sources (no build)" ; DSONLY=y;;
        M )  echo "- Just do the sitemap" ; MAPONLY=y;;
	    d )  echo "- Don't mirror sources" ; GETDATA=n;;
	    i )  echo "- Interactive mode" ; INTERACT=y;;
        s )  echo "- Don't swap db" ; SWAP=n;;
        n )  echo "- Don't build the mine"; BUILD=n;;
        f )  echo "- Build FLYBASE"; FLYBASE=y;;
      	r )  REL=$OPTARG; echo "- Using release $REL";;
        h )  usage ;;
	    \?)  usage ;;
   esac
done

shift $(($OPTIND - 1))


CODEDIR=/data/code
PDIR=$HOME/.intermine
MINEDIR=$CODEDIR/$MINE
DATADIR=/micklem/data
SMSDIR=/code/intermine-sitemaps
DUMPDIR=/micklem/dumps/humanmine

# TODO: check you are the rigth (humanbuild) user




function interact {
# if testing, wait here before continuing
if [ $INTERACT = "y" ]
then
echo "$1"
echo "Press return to continue (^C to exit).."
echo -n "->"
read 
fi
}

function swap {
# to change build db
#
# not needed until we add the webapp release
# see docovid
#

echo "NOT IMPLEMENTED YET"

}

function getSources {
# get the data
# 
# run datadownloader...
# or should we change to use wget and a mirroring system?
#

echo "NOT IMPLEMENTED YET"

}

function donothing {
echo "Just printing..."
}


function getFB { 
# TODO check you are on mega2

FBDIR=/data/fb

cd $FBDIR

rm FB*
rm md5sum.txt
rm README

# ~15 mins
wget ftp://ftp.flybase.net/releases/current/psql/*

# check md5?

# create new fb db (TODO: remove old one?)
FB=`grep createdb README | cut -d' ' -f5`
createdb -h localhost -U flymine $FB

# load - long ~10h?
cat FB* | gunzip | psql -h mega2 -U flymine -d $FB

# do the vacuum (analyse) (new step, check if it improves build times)
# it increases db size (then get back again) check if worth it. long: 9h!
#vacuumdb -f -z -v -h mega2 -U flymine -d $FB

}


function buildmine { 
# TODO check you are on mega2

cd $MINEDIR

# TODO mv all logs in a dir $MINEDIR/ark/$PREVREL
#export JAVA_HOME=""

# check if success
./project_build -b -v localhost $DUMPDIR/$MINE$REL\
|| { printf "%b" "\n  build FAILED!\n" ; exit 1 ; }

# if not on production machine you don't need: 
#./gradlew postProcess -Pprocess=create-autocomplete-index
#./gradlew postProcess -Pprocess=create-search-index
#
# TODO rm from build project.xml?
}



function makeSitemaps {
# build and position the sitemaps
#
# possibly needed? only after adding webapp release..
# check docovid
#

echo "NOT IMPLEMENTED YET"

}


#
# main..
#

if [ $DSONLY = "y" ]
then
  interact "Just update sources please"
  getSources
  exit;
fi

if [ $MAPONLY = "y" ]
then
  interact "Just make the sitemaps please"
  makeSitemaps
  exit;
fi

if [ $SWAP = "y" ]
then
   interact "Swapping build db"
   swap
fi

if [ $GETDATA = "y" ]
then
   interact "Getting sources"
   getSources
fi


if [ $FLYBASE = "y" ]
then
interact "Building FLYBASE db.."
#donothing
getFB
fi


if [ $BUILD = "y" ]
then
interact "Building $MINE $REL .."
#donothing
buildmine
fi



#interact "Deploying"

#./gradlew cargoRedeployRemote

#interact "Making the sitemaps"

#makeSitemaps
