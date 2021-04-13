#!/bin/bash
#
# usage: minebuilder.sh          batch mode NB: builds flymine by default
#        minebuilder.sh -H     batch mode, builds humanmine
#        minebuilder.sh -i       interactive (crude step by step) mode
#

# TODO: exit if wrong switchs combination
#
#       add switch for BDGP
#       NCBIfasta: - mirror?
#                  - gzip must check files integrity first/retry in case 
#       transform this into a get sources script (to be called by a 
#       buildmine one), remove switches (NB GETDATA)


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


PDIR=$HOME/.intermine

DATADIR=/micklem/data

#CODEDIR=/data/code
CODEDIR=$DATADIR/thalemine/git

MINEDIR=$CODEDIR/$MINE
SMSDIR=$CODEDIR/intermine-sitemaps
SHDIR=$CODEDIR/intermine-scripts

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

if [ $DSONLY = "y" ]
then
  interacts "Get human FASTA please"
  
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "running getNCBIfasta.."
		getNCBIfasta
	else
		echo "skipping.."
	fi
fi

if [ $DSONLY = "y" ]
then
  interacts "Get human GFF please"
  
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "running getNCBIgff.."
		getNCBIgff
	else
		echo "skipping.."
	fi
fi


if [ $DSONLY = "y" ]
then
  interacts "Update NCBI (add ensembl IDs)"
  
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "running updateNCBI.."
		updateNCBI
	else
		echo "skipping.."
	fi
fi

if [ $DSONLY = "y" ]
then
  interacts "Get gene summaries"
  
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "running get_refseq_summaries.py.."
		geneSummaries
	else
		echo "skipping.."
	fi
fi

if [ $DSONLY = "y" ]
then
  interacts "Get protein to domain data"
  
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "getting data.."
		getProt2Dom
	else
		echo "skipping.."
	fi
fi



echo "bye!"

}


function getSourcesInBatch {

if [ $DSONLY = "y" ]
then
  interact "Get Human FASTA please"
  getNCBIfasta
else
  continue
fi

if [ $DSONLY = "y" ]
then
  interact "Get Human GFF please"
  getNCBIgff
else
  continue
fi

if [ $DSONLY = "y" ]
then
  interact "Update NCBI (add ensembl IDs)"
  updateNCBI
else
  continue
fi

}

function updateNCBI { 

cd $SHDIR

echo "Running perl script adding ensembl ids..."
./bio/humanmine/ncbi-update.pl

WDIR=$DATADIR/ncbi/current

if [ -s "/tmp/renamed-ncbi.txt" ]
then
mv "/tmp/renamed-ncbi.txt" "$WDIR/All_Data.gene_info"
echo "NCBI Gene updated!"
else
echo "ERROR, please check $WDIR"
fi
}

function geneSummaries { 

WDIR=$DATADIR/ncbi/gene-summaries

cd $WDIR

NOW=`date "+%Y-%m-%d"`
mkdir $NOW

rm current
ln -s $NOW current

cd $SHDIR

FIN=$DATADIR/ncbi/gene-info-human/current/Homo_sapiens.gene_info
FOUT=$WDIR/current/gene_summaries.txt

echo "Running python script getting gene summaries..."
./bio/get_refseq_summaries.py $FIN $FOUT 

}


function getProt2Dom { 

WDIR=$DATADIR/interpro/match_complete

cd $WDIR

NOW=`date "+%Y-%m-%d"`
mkdir $NOW

rm current
ln -s $NOW current

cd current

F1=ftp.ebi.ac.uk/pub/databases/interpro/current/match_complete.xml.gz
F2=ftp.ebi.ac.uk/pub/databases/interpro/current/protein2ipr.dat.gz

echo "Getting match_complete file from interpro..."
wget $F1

echo "Getting protein2ipr file from interpro..."
wget $F2

echo "Expanding files.."
gzip -d *.gz

ls -la

}


function donothing {
echo "Just printing..."
}


function getBDGP { 
# TODO check you are on mega2

BDGPDIR=/micklem/data/flymine/bdgp-insitu

cd $BDGP/mysql

# to check if there is change
B4=`stat insitu.sql.gz | grep Change`

wget -N https://insitu.fruitfly.org/insitu-mysql-dump/insitu.sql.gz

A3=`stat insitu.sql.gz | grep Change`

if [ "$B4" != "$A3" ]
then
# cp, expand and load into mysql, query and update annotation file

NOW=`date "+%Y%m%d"`
mkdir $NOW
cp insitu.sql.gz $NOW
gzip -d $NOW/insitu.sql.gz

#create db
mysql -u flymine -p -e "CREATE DATABASE bdgp$NOW;"

# load 30 mins?
mysql -u flymine bdgp$NOW < $BDGPDIR/$NOW/insitu.sql

# run query
# TODO: change mysql conf to allow dumpiong of files in BDGP dir

EXPDIR="/var/lib/mysql-files/" 

QUERY="select distinct g.gene_id, a.stage, i.image_path, t.go_term \
from main g, image i, annot a, annot_term j, term t \
where g.id = a.main_id and a.id = i.annot_id and g.gene_id LIKE 'CG%' \
and a.id = j.annot_id and j.term_id = t.id \
into outfile '$EXPDIR/bdgp-mysql.out';"

# a few secs
mysql -u flymine -d bdgp$NOW -e "$QUERY"

mkdir $BDGPDIR/$NOW

cp $EXPDIR/bdgp-mysql.out $BDGPDIR/$NOW

cd $BDGPDIR
rm current

ln -s $NOW current

echo "$BDGPDIR/$NOW updated!"

else
echo "BDGP has not been updated."
fi
}

function getNCBIgff { 

WDIR=/micklem/data/human/gff

cd $WDIR

URI1="ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/vertebrate_mammalian/"
URI2="Homo_sapiens/reference/GCF_000001405.39_GRCh38.p13/"
FILE="GCF_000001405.39_GRCh38.p13_genomic.gff.gz"

# to check if there is change
B4=`stat $FILE | grep Change`

wget -N "$URI1$URI2$FILE"

A3=`stat $FILE | grep Change`

if [ "$B4" != "$A3" ]
then

NOW=`date "+%Y%m%d"`
mkdir $NOW
cp $FILE $NOW
gzip -d $NOW/$FILE

rm current

ln -s $NOW current

echo "NCBI Gene updated!"
else
echo "NCBI Gene was already up to date, not retrieved."
fi
}


function getHPO { 

WDIR=/micklem/data/hpo
CFLAG="n"

cd $WDIR

URI1="http://compbio.charite.de/jenkins/job/hpo.annotations"
URI2="/lastStableBuild/artifact/misc"

cd mirror

# to check if there is change
B4=`stat phenotype_annotation.tab | grep Change`
wget -N $URI1$URI2/phenotype_annotation.tab
A3=`stat phenotype_annotation.tab | grep Change`

if [ "$B4" != "$A3" ]
then
CFLAG="y"
fi

B4=`stat phenotype_annotation_negated.tab | grep Change`
wget -N $URI1$URI2/phenotype_annotation.tab
A3=`stat phenotype_annotation_negated.tab | grep Change`

if [ "$B4" != "$A3" ]
then
CFLAG="y"
fi


if [ "$CFLAG" = "y" ]
then
# cp, expand and load into mysql, query and update annotation file

NOW=`date "+%Y%m%d"`
mkdir $NOW
cp $FILE $NOW
gzip -d $NOW/$FILE

rm current

ln -s $NOW current

echo "NCBI Gene updated!"
else
echo "NCBI Gene has not been updated."
fi
}



function getNCBIfasta { 

WDIR=/micklem/data/human/fasta

cd $WDIR

URI1="ftp://ftp.ncbi.nlm.nih.gov/genomes/refseq/vertebrate_mammalian/"
URI2="Homo_sapiens/reference/GCF_000001405.39_GRCh38.p13/"
URI3="GCF_000001405.39_GRCh38.p13_assembly_structure/Primary_Assembly"

# we assume these always change

NOW=`date "+%Y-%m-%d"`
mkdir $NOW
cd $NOW
wget "$URI1$URI2$URI3"/assembled_chromosomes/FASTA/*
gzip -d *

cd $WDIR

rm current

ln -s $NOW current

echo "NCBI fasta updated!"
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
# TODO: actually keep a constant name (flybase) for the build properties

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
   echo "Starting with BDGP.."
   getBDGP
   echo "Human gff (NCBI gene)"
   getNCBIgene
   echo "Human fasta (NCBI fasta)"
   getNCBIfasta
   
   echo "Phenotypes HPO"
   getHPO
   
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
