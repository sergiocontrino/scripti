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
VERBOSE=""       # --stacktrace

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
USER=`whoami`  

# tmp until we fix .bashrc
#export JAVA_HOME=""

progname=$0

function usage () {
	cat <<EOF

Usage:
$progname [-F] [-H] [-m] [-i] [-v] [-r release]
  -F: flymine
  -H: humanmine
  -m: just do the sitemap
  -r: the release number
  -i: interactive mode
  -v: verbose mode


Notes:
- By default build flymine, batch  mode. 
- Release is a required parameter, can be entered as a flag (-r) or as the first argument

examples:

$progname 66            release flymine rel 66, no questions..
$progname -r 66         release flymine rel 66, no questions..
$progname -iv 66        interactive (step by step) and verbose (stacktrace)
$progname -Hir 18       release humanmine release 18, interactive


EOF
	exit 0
}

echo
while getopts "FHmir:v" opt; do
   case $opt in
        F )  echo "> releasing FLYMINE        " ; MINE=flymine; HOST=mine-prod-1;;
        H )  echo "> releasing HUMANMINE      " ; MINE=humanmine; HOST=mine-prod-0;;        
        m )  echo "> Just do the sitemap      " ; MAPONLY=y;;
	    i )  echo "> Interactive mode         " ; INTERACT=y;;
	    v )  echo "> Verbose mode             " ; VERBOSE='-- stacktrace';;
      	r )  REL=$OPTARG; echo "> Release $REL               ";;
        h )  usage ;;
	    \?)  usage ;;
   esac
done

#REL=${@:$OPTIND:1}

shift $(($OPTIND - 1))


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

function checkUser {
	
if [ $MINE = "flymine" -a $USER != "flymine" ] 
then
echo
echo "ERROR: wrong user. You should be $MINE, not $USER"
echo
exit;
fi

if [ $MINE = "humanmine" -a $USER != "humanmine" ] 
then
echo
echo "ERROR: wrong user. You should be $MINE, not $USER"
echo
exit;
fi

}

checkUser

checkHost


# 2 more settings
let PREL=$REL-1
MINEDIR=$CODEDIR/$MINE

echo
echo "============================================="
echo 
echo "    Releasing $MINE v$REL on $HOST"
echo 
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
  if [ $REPLY -a $REPLY != 's' ]
	then
		$2
	else
		echo "skipping this step.."
	fi
else
  $2
fi
}


function restore {
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


function writeProps {

DD=`date "+%B %Y"`
echo "Setting release to $REL and date to $DD..."
echo
cd $PDIR
cp $MINE.properties.$PREL $MINE.properties.$REL

sed -i 's/releaseVersion=.*/releaseVersion='"$REL  $DD"'/' $MINE.properties.$REL
sed -i 's/databaseName='"$MINE$PREL"'/databaseName='"$MINE$REL"'/' $MINE.properties.$REL

rm $MINE.properties
ln -s $MINE.properties.$REL $MINE.properties
}


function deploy {

cd $MINEDIR

echo "Redeployng $MINE webapp with release $REL.."
echo
echo "Running gradlew clean.."
echo
./gradlew clean $VERBOSE

echo
echo "Redeploying.."
echo
./gradlew cargoRedeployRemote $VERBOSE

echo
echo "Updating lucene indexes.."
echo "- autocomplete..."
./gradlew postprocess -Pprocess=create-autocomplete-index $VERBOSE
echo
echo "- search index..."
./gradlew postprocess -Pprocess=create-search-index $VERBOSE

echo "==========================================================="
echo "Please check the release at https://www.flymine.org/flymine"
echo "and at https://legacy.flymine.org/flymine/begin.do"
echo "==========================================================="
}



####################
#                  #
#       MAIN       #
#                  #
####################

if [ $MAPONLY = "y" ]
then
  interact "Just make the sitemaps please"
  makeSitemaps
  exit;
fi


#interacts "Building $MINE" buildmine

interacts "Building (restoring) $MINE$REL on $HOST" restore

interacts "Write $MINE.properties.$REL in $PDIR" writeProps 

interacts "Release $MINE$REL:  NB THIS STEP WILL INTERRUPT CURRENT RELEASE" deploy

#TODO?
#makeSitemaps
# arkive!

echo
echo "bye!"


# ---------------- TO IMPLEMENT (?) ----------------


function archive {

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

