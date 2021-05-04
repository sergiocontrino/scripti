#!/bin/bash
#
# usage: runGrabber.sh          batch mode
#        runGrabber.sh -i       interactive mode
#
# TODO: exit if wrong switchs combination
#

# default settings: edit with care
INTERACT=n       # y: step by step interaction

# tmp until we fix .bashrc
export JAVA_HOME=""

progname=$0

function usage () {
	cat <<EOF

Usage:
$progname [-i]
	-i: interactive mode

examples:

$progname			do the release without asking for permission..
$progname -i      		interactive version (for step by step release)

EOF
	exit 0
}


while getopts "i" opt; do
   case $opt in
        i )  echo "- Interactive mode" ; INTERACT=y;;
        h )  usage ;;
	    \?)  usage ;;
   esac
done

shift $(($OPTIND - 1))

DATADIR=/micklem/data/covid
#COVIDIR=/micklem/data/thalemine/git/ncbi-sequence-grabber
COVIDIR=/data/code/ncbi-sequence-grabber
SEQFILE=sequences.fasta


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


#
# main..
#


cd "$COVIDIR"

pwd
ls -la

interact "Running ncbi grabber.."

source ~flymine/.profile

npm start

if [ -s "./$SEQFILE" ]
then
interact "Moving sequence file in place"

mv $SEQFILE $DATADIR/fasta/ncbi.fasta
else
echo "ERROR running grabber, please try again"
fi

# check if success
#./project_build -b -v localhost $DATADIR/dumps/cov\
#|| { printf "%b" "\n  build FAILED!\n" ; exit 1 ; }

