#!/bin/bash
#

echo; echo "update docker"
sudo docker pull intermine/bluegenes:latest

echo; echo "remove current container"
sudo docker container rm -f $(sudo docker ps -aq)

echo; echo "restart"
sudo docker run -p 5000:5000 --env-file bluegenes.env -v "$(pwd)"/tools:/tools -d --restart unless-stopped intermine/bluegenes
