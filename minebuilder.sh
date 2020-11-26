#!/bin/bash
#
# usage: minebuilder.sh          batch mode
#        minebuilder.sh -i       interactive (crude step by step) mode
#
# TODO: exit if wrong switchs combination
#

# default settings: edit with care
INTERACT=n       # y: step by step interaction
SWAP=y           # n: don't swap db
GETDATA=y        # n: don't update uniprot and gff
DSONLY=n         # y: just update the sources (don't build)
MAPONLY=n        # y: just do the sitemap (just that!)
MINE=flymine     

# tmp until we fix .bashrc
#export JAVA_HOME=""

progname=$0

function usage () {
	cat <<EOF

Usage:
$progname [-S] [-M] [-d] [-i] [-s]
  -M: just do the sitemap
  -S: just get the sources (no build)
  -d: no checking of sources for update
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


while getopts "FHSMdis" opt; do
   case $opt in
        F )  echo "- building FLYMINE" ; MINE=flymine;;
        H )  echo "- building HUMANMINE" ; MINE=humanmine;;        
        S )  echo "- Just updating sources (no build)" ; DSONLY=y;;
        M )  echo "- Just do the sitemap" ; MAPONLY=y;;
	      d )  echo "- Don't mirror sources" ; GETDATA=n;;
	      i )  echo "- Interactive mode" ; INTERACT=y;;
        s )  echo "- Don't swap db" ; SWAP=n;;
        h )  usage ;;
	      \?)  usage ;;
   esac
done

shift $(($OPTIND - 1))

#COV=covidmine.properties

PDIR=$HOME/.intermine
MINEDIR=/code/flymine
DATADIR=/micklem/data
SMSDIR=/code/intermine-sitemaps

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

function getFB { # ~15 mins
# check you are on mega2
# TODO
FBDIR=/data/fb

rm FB*
rm md5sum.txt
rm README

wget ftp://ftp.flybase.net/releases/current/psql/*

# check md5?

# create new fb db (TODO: remove old one?)
FB=`grep createdb README | cut -d' ' -f5`
createdb -h localhost -U flymine $FB

# load - ~
cat FB* | gunzip | psql -h mega2 -U flymine -d $FB

# do the vacuum (analyse) (new step, check if it improves build times)
vacuumdb -f -z -v -h mega2 -U flymine -d $FB

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


cd $COVDIR

interact "Building.."

#export JAVA_HOME=""
rm $DATADIR/dumps/cov*

# check if success
./project_build -b -v localhost $DATADIR/dumps/cov\
|| { printf "%b" "\n  build FAILED!\n" ; exit 1 ; }

# if not on production machine you don't need: 
#./gradlew postProcess -Pprocess=create-autocomplete-index
#./gradlew postProcess -Pprocess=create-search-index

#interact "Deploying"

#./gradlew cargoRedeployRemote

#interact "Making the sitemaps"

#makeSitemaps
