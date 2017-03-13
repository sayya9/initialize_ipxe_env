#!/bin/bash -ex

grep -E "gcr|quay" prod-images > push_images.for_china
mkdir -p /var/www/html/images/docker
while read -r line
do
    temp_name=henryrao/${line##*/}
    docker tag $line $temp_name
    docker push $temp_name
done < "./push_images.for_china"
