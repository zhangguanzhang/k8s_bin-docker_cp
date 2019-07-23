#!/bin/bash
sync_record_dir=$CUR_DIR/sync/${1}/   # 存放根目录的 ./bash/$own/的$own
sync_record_tag_dir=${sync_record_dir}/tag/
sync_record_file=${sync_record_dir}/synced


domain=docker.elastic.co

mkdir -p $sync_record_tag_dir $sync_record_dir


# tag
hub_tag_exist(){
    curl -s https://hub.docker.com/v2/repositories/${MY_REPO}/${img_name}/tags/$1/ | jq -r .name
}

es_pull(){
    docker pull $@
    read null ns img < <(tr / ' ' <<<$@)
    newName=$MY_REPO/$ns-$img
    docker tag $@  $newName
    docker push $newName
}



main(){

    cd $CUR_DIR
    while read img;do
        grep -qw "$img" $sync_record_file && continue
        es_pull $img
        [[ $(df -h| awk  '$NF=="/"{print +$5}') -ge "$max_per" ]] && docker image prune -f || :

        echo $img >> $sync_record_file

        [ $(( (`date +%s` - start_time)/60 )) -gt 47 ] && git_commit

    done < <( curl -s 'https://www.docker.elastic.co/#' | perl -lne 'if(/docker pull/){s/<\/?strong>//g;/docker pull \K[^<]+/;print $&}')
    
    cd $CUR_DIR
    rm -rf temp/*
}

main
