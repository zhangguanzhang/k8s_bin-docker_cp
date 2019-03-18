#!/bin/bash
sync_record_dir=$CUR_DIR/sync/${1}/   # 存放根目录的 ./bash/$own/
sync_record_tag_dir=${sync_record_dir}/tag/
sync_record_file=${sync_record_dir}/synced
img_name=cni-plugins

mkdir -p $sync_record_tag_dir

arch=(
    amd64
    arm
    arm64
    ppc64le
    s390x
)



# img_tag
hub_tag_exist(){
    curl -s https://hub.docker.com/v2/repositories/${MY_REPO}/${img_name}/tags/$1/ | jq -r .name
}

# $arch $version
cni::sync(){
    local tag=$1-$2
    [ "$( hub_tag_exist $tag )" == null ] && {
        cat>Dockerfile<<-EOF
        FROM zhangguanzhang/alpine
        COPY cni-plugins-$1-$2.* /
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
    curl -s https://api.github.com/repos/containernetworking/plugins/releases/tags/$1 | jq .assets[].browser_download_url
}

main(){
    local url tag;
    cd $CUR_DIR/temp
    while read tag;do
        grep -qP '\Q'"$tag"'\E' $sync_record_file && continue
        err=`curl -s https://api.github.com/repos/containernetworking/plugins/releases/tags/$tag | jq .message`
        [ "$err" != 'null' ] && continue # Not Found
        if [ "$(get_download_url $tag | awk 'END{print NR}')" -ge 2 ];then
            while read  url;do
                wget $url
            done < <(get_download_url $tag)      

            for archfile in ${arch[@]};do
                ls *$archfile* &>/dev/null && {
                    cni::sync $archfile $tag
                } || continue
                [[ $(df -h| awk  '$NF=="/"{print +$5}') -ge "$max_per" ]] && docker image prune -f || :
                [ $(( (`date +%s` - start_time)/60 )) -gt 47 ] && git_commit
            done
            echo $tag >> $sync_record_file

            rm -rf $CUR_DIR/temp/*$tag*
        fi
        [ $(( (`date +%s` - start_time)/60 )) -gt 47 ] && git_commit

    done < <(stable_tag)
    
    cd $CUR_DIR
    rm -rf temp/*
}

main
