#!/bin/bash
#
# usage: release.sh          batch mode NB: builds flymine by default
#        release.sh -H       batch mode, builds humanmine
#        release.sh -i       interactive (crude step by step) mode
#

# TODO: exit if wrong switchs combination
#

# default settings: edit with care
INTERACT=n       # y: step by step interaction
MAPONLY=n        # y: just do the sitemap (just that!)
DOPROPS=n        # y: update properties file for the mine


MINE=flymine   # default mine
REL=""         # the new release
PREL=""        # current release

FHOST=mine-prod-1
HHOST=mine-prod-0

DUMPDIR=/micklem/dumps/humanbuild
RELDIR=/micklem/releases
DATADIR=/micklem/data
CODEDIR=/data/code
SMSDIR=/code/intermine-sitemaps
PDIR=$HOME/.intermine

HOST=`hostname | cut -d. -f1`
  

# tmp until we fix .bashrc
#export JAVA_HOME=""

progname=$0

function usage () {
	cat <<EOF

Usage:
$progname [-F] [-H] [-m] [-i] [-r release]
  -F: flymine
  -H: humanmine
  -m: just do the sitemap
  -r: the release number
  -i: interactive mode

examples:

$progname 66            release flymine rel 66, no questions..
$progname -r 66         release flymine rel 66, no questions..
$progname -ir 66        interactive version (for step by step release)
$progname -Hir 18       release humanmine release 18, interactive

EOF
	exit 0
}

echo "----------------------------"

while getopts "FHmir:" opt; do
   case $opt in
        F )  echo "| - building FLYMINE        |" ; MINE=flymine; HOST=mine-prod-1;;
        H )  echo "| - building HUMANMINE      |" ; MINE=humanmine; HOST=mine-prod-0;;        
        m )  echo "| - Just do the sitemap     |" ; MAPONLY=y;;
	    i )  echo "| - Interactive mode        |" ; INTERACT=y;;
      	r )  REL=$OPTARG; echo "| - Releasing $MINE$REL     |";;
        h )  usage ;;
	    \?)  usage ;;
   esac
done

#REL=${@:$OPTIND:1}

shift $(($OPTIND - 1))

echo "----------------------------"


if [ -z $REL ] 
then
REL=$1
fi

if [ -z $REL ] 
then
echo
echo "ERROR: Please enter the new release number."
echo
exit;
fi


function checkHost {
	
if [ $MINE = "flymine" -a $HOST != $FHOST ] 
then
echo
echo "ERROR: wrong machine. You should be on $FHOST, not $HOST"
echo
exit;
fi

if [ $MINE = "humanmine" -a $HOST != $HHOST ] 
then
echo
echo "ERROR: wrong machine. You should be on $HHOST, not $HOST"
echo
exit;
fi

}


checkHost


# 2 more settings
let PREL=$REL-1
MINEDIR=$CODEDIR/$MINE

echo "============================================="
echo "|"
echo "|    Releasing $MINE v$REL on $HOST"
echo "|"
echo "============================================="





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

function interacts {
# s will skip current step and go to the next
if [ $INTERACT = "y" ]
then
echo; echo "$1"
echo "Press s to skip this step, return to continue (^C to exit).."
echo -n "->"
read 
fi
}


function donothing {
echo "Just printing..."
}


function restorel {
# drop previous?
# dropdb -h localhost -U $MINE $MINE$PREL

echo "Creating $MINE$REL database.."
createdb -h localhost -U $MINE $MINE$REL
if [ -s $DUMPDIR/$MINE$REL.final ]
then
echo "Restoring data from the build dump $DUMPDIR/$MINE$REL.final: "
pg_restore -h localhost -U $MINE -d $MINE$REL $DUMPDIR/$MINE$REL.final
else
echo "dump file -- $DUMPDIR/$MINE$REL.final -- not found! exiting.."
exit;
fi
	
}


function dodb {

if [ $INTERACT = "y" ]
then 
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "running release db setup.."
		restorel
	else
		echo "skipping.."
	fi
else
  echo "running release db setup.."
  restorel
fi
}

function doprops {

if [ $INTERACT = "y" ]
then 
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "Writing $MINE.properties.$REL.."
		writeProps
	else
		echo "skipping.."
	fi
else
  echo "Writing $MINE.properties.$REL.."
  writeProps
fi
}


function dorel {

if [ $INTERACT = "y" ]
then 
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "Releasing $MINE$REL.."
		deploy
	else
		echo "skipping.."
	fi
else
  echo "Releasing $MINE$REL.."
  deploy
fi
}



function buildmine { 
echo "not now.."
exit;

cd $MINEDIR

if [ $REPLY -a $REPLY != 's' ]
	then
	echo "building $MINE.."


# TODO mv all logs in a dir $MINEDIR/ark/$PREVREL
#export JAVA_HOME=""


# check if success
./project_build -b -v localhost $DUMPDIR/$MINE$REL\
|| { printf "%b" "\n  build FAILED!\n" ; exit 1 ; }

#./project_build -b -v localhost /micklem/dumps/humanbuild/humanmine10
		
	else
		echo "skipping.."
	fi

# if not on production machine you don't need: 
#./gradlew postProcess -Pprocess=create-autocomplete-index
#./gradlew postProcess -Pprocess=create-search-index
#
# TODO rm from build project.xml?
}


function writeProps {
# 
#
#

echo $PDIR

cd $PDIR
cp $MINE.properties.$PREL $MINE.properties.$REL

DD=`date "+%B %Y"`
sed -i bup 's/releaseVersion=.*/releaseVersion='"$REL  $DD"'/' $MINE.properties.$REL
echo $DD
sed -i bup 's/databaseName='"$MINE$PREL"'/databaseName='"$MINE$REL"'/' $MINE.properties.$REL

rm $MINE.properties
ln -s $MINE.properties.$REL $MINE.properties
}


function deploy {

cd $MINEDIR

echo "Redeployng $MINE webapp with release $REL.."

#./gradlew clean --stacktrace
#./gradlew cargoRedeployRemote --stacktrace


echo "Updating lucene indexes.."
echo "autocomplete..."
#./gradlew postprocess -Pprocess=create-autocomplete-index --stacktrace
echo "search index..."
#./gradlew postprocess -Pprocess=create-search-index --stacktrace


}

function archive {
# 
#
#

echo "NOT IMPLEMENTED YET"
exit;

cd $RELDIR/$MINE

mkdir r$REL

mv ....

}


function makeSitemaps {
# build and position the sitemaps
#
# check docovid
#

echo "NOT IMPLEMENTED YET"

}


#
# main..
#


if [ $MAPONLY = "y" ]
then
  interact "Just make the sitemaps please"
  makeSitemaps
  exit;
fi


#interacts "Building $MINE"
#buildmine

interacts "Building (restoring) $MINE$REL on $HOST" 
dodb

interacts "Write $MINE rel$REL properties" 
doprops

interacts "Release $MINE$REL:    NB THIS STEP WILL INTERRUPT CURRENT RELEASE"
dorel


#interact "Making the sitemaps"

#makeSitemaps

# arkive!

echo "bye!"
