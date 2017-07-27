#!/bin/bash

web_url="https://github.com/kevinthesun/mxnet.git"
web_folder="VersionedWeb"
local_build="latest"
web_branch="static_web"
git clone $web_url $web_folder
cd $web_folder
git checkout -b $web_branch "origin/$web_branch"
cd ..
mkdir "$local_build"

tag_list_file="docs/build_version_doc/tag_list.txt"
cp "$web_folder/tag.txt" "$tag_list_file"
tag_list=()
while read -r line 
do
    tag_list+=("$line")
done < "$tag_list_file"
latest_tag=${tag_list[0]}
echo "latest_tag is: $latest_tag"
commit_id=$(git rev-parse HEAD)
if [[ -z "${TAG}" ]]
then
    curr_tag=''
else
    curr_tag='${TAG:4}'
if [[ "$curr_tag" != '' ]] && [ $curr_tag != $latest_tag ]
then
    latest_tag=$curr_tag
fi
if [ $latest_tag != ${tag_list[0]} ]
then
    make docs || exit 1
    echo -e "$latest_tag\n$(cat $tag_list_file)" > "$tag_list_file"
    cat $tag_list_file
    cd "docs/build_version_doc"
    python AddVersion.py --file_path "$mxnet_folder/docs/_build/html/"
    cd ../..
    cp -a "docs/_build/html/." "$local_build"
    cp $tag_list_file "$local_build/tag.txt"
    cp -a "$web_folder/versions/." "$local_build/versions"
    mkdir "$local_build/versions/${tag_list[0]}"
    cp -a "$web_folder/." "$local_build/versions/${tag_list[0]}"
    rm -rf "$local_build/versions/${tag_list[0]}/versions"
    rm -rf "$web_folder/*"
    cp -a "$local_build/." "$web_folder"
fi

git checkout master
git submodule update
make docs || exit 1

rm -rfv "$web_folder/versions/master/*"
cp -a "docs/_build/html/." "$web_folder/versions/master"

if [ $latest_tag != ${tag_list[0]} ]
then
    total=${#tag_list[*]}
    cd "docs/build_version_doc"
    for (( i=0; i<=$(( $total -1 )); i++ ))
    do
        python AddVersion.py --file_path "$web_folder/versions/${tag_list[$i]}" \
                             --current_version "${tag_list[$i]}"
    done
fi
