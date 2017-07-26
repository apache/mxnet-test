#!/bin/bash

web_url="https://github.com/kevinthesun/mxnet.git"
mxnet_url="https://github.com/kevinthesun/mxnet.git"
web_folder="VersionedWeb"
mxnet_folder="mxnet"
local_build="latest"
web_branch="static_web"
git clone $web_url $web_folder
git clone $mxnet_url --recursive $mxnet_folder
cd $web_folder
git checkout -b $web_branch "origin/$web_branch"
cd ..
mkdir "$local_build"
cp "$web_folder/tag.txt" tag_list.txt
input="tag_list.txt"
tag_list=()
while read -r line 
do
    tag_list+=("$line")
done < "$input"
latest_tag=${tag_list[0]}
echo "latest_tag is: $latest_tag"

mkdir master
cd "$mxnet_folder"
git checkout VersionedDoc
commit_id=$(git rev-parse HEAD)
curr_tag=$(git describe --exact-match --tags "$commit_id")
if [[ "$curr_tag" != fatal* ]] && [ $curr_tag != $latest_tag ]
then
    latest_tag=$curr_tag
fi
make docs || exit 1
cd ..
if [ $latest_tag != ${tag_list[0]} ]
then
    echo -e "$latest_tag\n$(cat tag_list.txt)" > tag_list.txt
    cat tag_list.txt
fi
python AddVersion.py --file_path "$mxnet_folder/docs/_build/html/"
cp -a "$mxnet_folder/docs/_build/html/." master

if [ $latest_tag != ${tag_list[0]} ]
then
    python AddVersion.py --file_path "$mxnet_folder/docs/_build/html/" --current_version "$latest_tag"
    cp -a "$mxnet_folder/docs/_build/html/." "$local_build"
    cp tag_list.txt "$local_build/tag.txt"
    cp -a "$web_folder/versions/." "$local_build/versions"
    mkdir "$local_build/versions/${tag_list[0]}"
    cp -a "$web_folder/." "$local_build/versions/${tag_list[0]}"
    rm -rf "$local_build/versions/${tag_list[0]}/versions"
    rm -rf "$web_folder/*"
    cp -a "$local_build/." "$web_folder"
fi

rm -rf "$web_folder/versions/master"
cp -R master "$web_folder/versions/master"

if [ $latest_tag != ${tag_list[0]} ]
then
    total=${#tag_list[*]}
    for (( i=0; i<=$(( $total -1 )); i++ ))
    do
        python AddVersion.py --file_path "$web_folder/versions/${tag_list[$i]}" \
                             --current_version "${tag_list[$i]}"
    done
fi