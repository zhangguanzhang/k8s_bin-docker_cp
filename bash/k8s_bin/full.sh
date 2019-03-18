#!/bin/bash
sync_record_dir=$CUR_DIR/${1}/   # 存放根目录的 ./bash/$own/
sync_record_tag_dir=${sync_record_dir}/tag/
sync_record_file=${sync_record_dir}/synced
img_name=k8s_bin

mkdir -p $sync_record_tag_dir

# need to run,don't change the sort
sync_class_list=(
    full
    single
    kube
    base
    )



# tag
hub_tag_exist(){
    curl -s https://hub.docker.com/v2/repositories/${MY_REPO}/${img_name}/tags/$1/ | jq -r .name
}



# version
full::sync(){
    local tag=$1-full
    [ "$( hub_tag_exist $tag )" == null ] && {
        sudo cp /$save_name .
        cat>Dockerfile<<-EOF
        FROM zhangguanzhang/alpine
        COPY $save_name /
EOF
        docker build -t zhangguanzhang/$img_name:$tag .
        docker push zhangguanzhang/$img_name:$tag
        echo zhangguanzhang/$img_name:$1-full > $sync_record_tag_dir/$tag
        rm -f $save_name
    } || :
}

# version
single::sync(){
    du -shx *
    files=(
        $(sudo tar ztf /$save_name | grep -Po 'kubernetes/server/bin/\K[^.]+$')
    )
    for file in ${files[@]};do
        [ "$( hub_tag_exist $1-$file )" == null ] && {
            sudo tar -zxvf /$save_name  --strip-components=3  kubernetes/server/bin/$file
            cat>Dockerfile<<-EOF
            FROM zhangguanzhang/alpine
            COPY $file /
EOF
            sudo docker build -t zhangguanzhang/$img_name:$1-$file .
            docker push zhangguanzhang/$img_name:$1-$file
            echo zhangguanzhang/$img_name:$1-$file > $sync_record_tag_dir/$1-$file
            rm -f $file
        } || :
    done
}

# version
kube::sync(){
    local tag=$1-kube local_kube_file=()
    files=(
        kube-apiserver
        kube-controller-manager
        kube-proxy
        kube-scheduler
        kubectl
        kubelet
        hyperkube
        kubeadm
        )
    [ "$( hub_tag_exist $tag )" == null ] && {
        
        sudo tar -zxvf /$save_name  --strip-components=3  kubernetes/server/bin/
        for file in ${files[@]};do
            [ -f $file ] && local_kube_file+=($file)
        done
        sudo tar zcvf $save_name "${local_kube_file[@]}"
        rm -f $(ls -1I $save_name)
        cat>Dockerfile<<-EOF
        FROM zhangguanzhang/alpine
        COPY $save_name /
EOF
        docker build -t zhangguanzhang/$img_name:$tag .
        docker push zhangguanzhang/$img_name:$tag
        echo zhangguanzhang/$img_name:$tag > $sync_record_tag_dir/$tag
        rm -f $save_name 
    } || :
}

base::sync(){
    local tag=$1-base
    files=(
        kube-apiserver
        kube-controller-manager
        kube-proxy
        kube-scheduler
        kubectl
        kubelet
        )
    [ "$( hub_tag_exist $tag )" == null ] && {
        sudo tar -zxvf /$save_name  --strip-components=3  $( sed 's#^#kubernetes/server/bin/#' <(xargs -n1<<<"${files[@]}") )
        sudo tar zcvf $save_name "${files[@]}"
        rm -f ${files[@]}
        cat>Dockerfile<<-EOF
        FROM zhangguanzhang/alpine
        COPY $save_name /
EOF
        docker build -t zhangguanzhang/$img_name:$tag .
        docker push zhangguanzhang/$img_name:$tag
        echo zhangguanzhang/$img_name:$tag > $sync_record_tag_dir/$tag
        rm -f $save_name
    } || :
}

stable_tag(){
    curl -ks -XGET https://gcr.io/v2/${@#*/}/tags/list | jq -r .tags[] | grep -P 'v[\d.]+$' | sort -t '.' -n -k 2
}

main(){
    : ${save_name:=kubernetes-server-linux-amd64.tar.gz}

    cd $CUR_DIR/temp
    while read version;do
        grep -qP '\Q'"$version"'\E' $sync_record_file && continue
        printf -v version_url_download "$url_format" $version
        save_name=${version_url_download##*/}
        sudo wget $version_url_download -O /$save_name &>/dev/null
        
        for run in ${sync_class_list[@]};do
            $run::sync $version
            [[ $(df -h| awk  '$NF=="/"{print +$5}') -ge "$max_per" ]] && docker image prune -f || :
            [ $(( (`date +%s` - start_time)/60 )) -gt 47 ] && git_commit
        done
        echo $version >> $sync_record_file

        sudo rm -rf $save_name /$save_name kubernetes/ 
        [ $(( (`date +%s` - start_time)/60 )) -gt 47 ] && git_commit

    done < <(stable_tag gcr.io/google_containers/kube-apiserver-amd64)
    
    cd $CUR_DIR
    rm -rf temp/*
}

main
