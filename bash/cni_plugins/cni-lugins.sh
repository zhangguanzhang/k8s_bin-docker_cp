#!/bin/bash

readonly sh_CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

sync_record_dir=$CUR_DIR/sync/${1}/   # 存放分支develop的根目录的 ./sync/$own/
sync_record_tag_dir=${sync_record_dir}/tag/
sync_record_file=${sync_record_dir}/synced
img_name=cni-plugins

mkdir -p $sync_record_tag_dir


# img_tag
hub_tag_exist(){
    curl -s https://hub.docker.com/v2/repositories/${MY_REPO}/${img_name}/tags/$1/ | jq -r .name
}

# $arch $version
cni::sync(){
    local tag=$1
#    [ "$( hub_tag_exist $tag )" == null ] && {
     [ ! -f "$sync_record_tag_dir/$tag" ] && {
        [ -n "$DEBUG" ] && ls -l
        cat>Dockerfile<<-EOF
        FROM zhangguanzhang/alpine
        COPY cni-plugins-$tag.* /
EOF
        docker build -t zhangguanzhang/$img_name:$tag .
        docker push zhangguanzhang/$img_name:$tag
        echo zhangguanzhang/$img_name:$tag > $sync_record_tag_dir/$tag
    } || :
}

# return all the tags
stable_tag(){
    curl -s https://api.github.com/repos/containernetworking/plugins/git/refs/tags | jq -r '.[].url | match("(?<=/)[^/]+$").string'
}

# $1 tag
get_download_url(){
    curl -s https://api.github.com/repos/containernetworking/plugins/releases/tags/$1 | jq -r .assets[].browser_download_url
}

main(){
    local url version;
    cd $CUR_DIR/temp
    while read version;do

        grep -qP '\Q'"$version"'\E' $sync_record_file && continue
            while read  url;do
                wget $url
            done < <(get_download_url $version)      

            while read hub_tag;do
                cni::sync $hub_tag 
                [[ $(df -h| awk  '$NF=="/"{print +$5}') -ge "$max_per" ]] && docker image prune -f || :
                [ $(( (`date +%s` - start_time)/60 )) -gt 47 ] && git_commit
            done < <(ls *$version* |sed "s@cni-plugins-@@;s@\(-${version}\).*@\1@" | sort -u )

            echo $version >> $sync_record_file

            rm -rf $CUR_DIR/temp/*$version*
        [ $(( (`date +%s` - start_time)/60 )) -gt 47 ] && git_commit

    done < <(grep -Pv '^\s*$|^\s*#' $sh_CUR_DIR/tags )
    
    cd $CUR_DIR
    rm -rf temp/*
}

main
