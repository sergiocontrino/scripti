#!/bin/bash
#
# usage: getData.sh          batch mode NB: builds flymine by default
#        getData.sh -H       batch mode, builds humanmine
#        getData.sh -i       interactive (crude step by step) mode
#

# TODO: exit if wrong switchs combination
#
#       add switch for BDGP
#       NCBIfasta: - mirror?
#                  - gzip must check files integrity first/retry in case 
#       transform this into a get sources script (to be called by a 
#       buildmine one), remove switches (NB GETDATA)
#       prot2Dom: mirror?


# default settings: edit with care
INTERACT=n       # y: step by step interaction
GETDATA=n        # y: run the download script?
FLYBASE=n        # y: get FB files and build FB db


MINE="na"
REL=""
  

# tmp until we fix .bashrc
#export JAVA_HOME=""

progname=$0

function usage () {
	cat <<EOF

Usage:
$progname [-F] [-H] [-S] [-i]
  -F: just get flymine sources
  -H: just get humanmine sources
  -i: interactive mode
  -v: verbode mode

examples:

$progname			do the release without asking for permission..
$progname -i      		interactive version (for step by step release)
$progname -is      		interactive version without swapping

EOF
	exit 0
}


while getopts "FHSMdisfr:" opt; do
   case $opt in
        F )  echo "- just FLYMINE sources" ; MINE=flymine;;
        H )  echo "- just HUMANMINE sources" ; MINE=humanmine;;
	    i )  echo "- Interactive mode" ; INTERACT=y;;
        d )  echo "- Run DataDownloader"; GETDATA=y;;
        f )  echo "- Build FLYBASE"; FLYBASE=y;;
      	r )  REL=$OPTARG; echo "- Using release $REL";;
        h )  usage ;;
	    \?)  usage ;;
   esac
done

shift $(($OPTIND - 1))


DATADIR=/micklem/data

#CODEDIR=/data/code
CODEDIR=$DATADIR/thalemine/git
MINEDIR=$CODEDIR/$MINE
SHDIR=$CODEDIR/intermine-scripts

DBHOST=mega2

# TODO: check user? not for getting sources


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



function getSources {
#
# get sources not in the DataDownloader
# 

if [ $INTERACT = "y" ]
then
  interacts "Get human FASTA please"
  
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "running getNCBIfasta.."
		getNCBIfasta
	else
		echo "skipping.."
	fi
else
  echo "running getNCBIfasta.."
  getNCBIfasta
fi

if [ $INTERACT = "y" ]
then
  interacts "Get human GFF please"
  
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "running getNCBIgff.."
		getNCBIgff
	else
		echo "skipping.."
	fi
else
  echo "running getNCBIgff.."
  getNCBIgff
fi


if [ $INTERACT = "y" ]
then
  interacts "Update NCBI (add ensembl IDs)"
  
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "running updateNCBI.."
		updateNCBI
	else
		echo "skipping.."
	fi
else
  echo "running updateNCBI.."
  updateNCBI
fi

if [ $INTERACT = "y" ]
then
  interacts "Get gene summaries"
  
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "running get_refseq_summaries.py.."
		getGeneSummaries
	else
		echo "skipping.."
	fi
else
		echo "running get_refseq_summaries.py.."
		getGeneSummaries

fi

if [ $INTERACT = "y" ]
then
  interacts "Get protein to domain data, takes a long time!"
  
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "getting data.."
		getProt2Dom
	else
		echo "skipping.."
	fi
else
		echo "getting data.."
		getProt2Dom
fi


if [ $INTERACT = "y" ]
then
  interacts "Get phenotype annotation (HPO)"
  
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "getting HPO.."
		getHPO
	else
		echo "skipping.."
	fi
else
        echo "getting HPO.."
		getHPO
fi

echo "-----------------------------------------------------"
echo

}

function getFlySources {
# get the data for flymine
# 
#

if [ $INTERACT = "y" ]
then
  interacts "Get FlyBase please"
  
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "running getFB.."
		getFB
	else
		echo "skipping.."
	fi
else
  echo "running getFB.."
  getFB
fi


if [ $INTERACT = "y" ]
then
  interacts "Get BDGP please"
  
  if [ $REPLY -a $REPLY != 's' ]
	then
		echo "running getBDGP.."
		getBDGP
	else
		echo "skipping.."
	fi
else
  echo "running getBDGP.."
  getBDGP
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

function getGeneSummaries { 

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
# using wget -t 0 to set retry number to no limit
# TODO: add a wget -c -t 0 if interruption happens

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
wget -t 0 $F1

echo "Getting protein2ipr file from interpro..."
wget -t 0 $F2

echo "Expanding files.."
gzip -d *.gz

ls -la

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

NOW=`date "+%Y-%m-%d"`
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



function getBDGP { 
# WORKING on modalone
# TODO mv to mega3 (setup mysql)

BDGPDIR=/micklem/data/flymine/bdgp-insitu

cd $BDGPDIR/mysql

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
# TODO: change mysql conf to allow dumping of files in BDGP dir

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
# cp and expand

NOW=`date "+%Y%m%d"`
mkdir $NOW
cp $FILE $NOW
gzip -d $NOW/$FILE

rm current

ln -s $NOW current

echo "HPO: gene updated!"
else
echo "HPO: gene has not been updated."
fi
}

function getFB { 
# TODO check you are on mega2

FBDIR=/data/fb

cd $FBDIR

# saving previous download for the moment
NOW=`date "+%Y-%m-%d"`
mkdir $NOW

mv FB* $NOW
mv md5sum.txt $NOW
mv README $NOW

# ~15 mins
wget ftp://ftp.flybase.net/releases/current/psql/*

# check md5?

# old version, keeping FB version number in postgres 
#FB=`grep createdb README | cut -d' ' -f5`
#createdb -h localhost -U flymine $FB
#cat FB* | gunzip | psql -h mega2 -U flymine -d $FB

# create new fb db 
# keeping a constant name (flybase) for the build properties

echo "Dropping old flybase.."
dropdb -h  $DBHOST -U flymine flybaseprevious

echo "Renaming last flybase.."
psql -h $DBHOST -d items-flymine -U flymine -c "alter database flybase rename to flybaseprevious;"

echo "Creating new flybase.."
createdb -h $DBHOST -U flymine flybase

echo "..and loading it (long, ~10h)"

# load - long ~10h?
cat FB* | gunzip | psql -h $DBHOST -U flymine -d flybase

# do the vacuum (analyse) (new step, check if it improves build times)
# it increases db size (then get back again) check if worth it. long: 9h!
#vacuumdb -f -z -v -h mega2 -U flymine -d $FB

}


function donothing {
echo "Just printing..."
}


#
# main..
#

# to test bgdp
if [ $FLYBASE = "y" ]
then
  interact "Update BDGP"
  getBDGP
echo "bye!"
  exit
fi




if [ $MINE != "flymine" ]
then
  interact "Update sources (NCBI, protein domanins, HPO)"
  getSources
fi

if [ $MINE != "humanmine" ]
then
  interact "Update FlyBase and BDGP"
  getFlySources
fi

echo "bye!"

exit;


if [ $GETDATA = "y" ]
then
   interact "Getting sources"
echo "Add datadownloader here.."
   
fi

