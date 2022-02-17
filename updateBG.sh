#!/bin/bash
#
# usage
#
# updateBG.sh releaseNr
#
# e.g. ./updateBG.sh 1.4.1
#
# sc
#

if [ -z "$1" ]
then
echo 
echo "Press enter release tag (e.g. 1.5.3 ) to continue (^C to exit).."
echo -n "->"
read REL 
else
REL="$1"
fi

echo; echo "Upgrading BG instance to release $REL"

echo; echo "docker process running now: "
sudo docker ps -aq

echo; echo "update docker"
sudo docker pull intermine/bluegenes:"$REL"

echo; echo "remove current container"
sudo docker container rm -f $(sudo docker ps -aq)

echo; echo "restart"
sudo docker run -p 5000:5000 --env-file bluegenes.env -v "$(pwd)"/tools:/tools -d --restart unless-stopped intermine/bluegenes:"$REL"

echo; echo "bye!"
