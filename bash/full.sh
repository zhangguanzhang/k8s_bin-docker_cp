#!/bin/bash

# need to run,don't change the sort
sync_class_list=(
    full
    single
    kube
    base
    )

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
        echo zhangguanzhang/$img_name:$1-full > $CUR_DIR/tag/$tag
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
            echo zhangguanzhang/$img_name:$1-$file > $CUR_DIR/tag/$1-$file
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
        ls -l 
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
        echo zhangguanzhang/$img_name:$tag > $CUR_DIR/tag/$tag
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
        echo zhangguanzhang/$img_name:$tag > $CUR_DIR/tag/$tag
        rm -f $save_name
    } || :
}


main(){
    : ${save_name:=kubernetes-server-linux-amd64.tar.gz}

    cd $CUR_DIR/temp
    while read version;do
        printf -v version_url_download "$url_format" $version
        save_name=${version_url_download##*/}
        sudo wget $version_url_download -O /$save_name &>/dev/null
        
        for run in ${sync_class_list[@]};do
            $run::sync $version
            [[ $(df -h| awk  '$NF=="/"{print +$5}') -ge "$max_per" ]] && docker image prune -f || :
            [ $(( (`date +%s` - start_time)/60 )) -gt 47 ] && git_commit
        done
        sudo rm -rf $save_name /$save_name kubernetes/ 

    done < $CUR_DIR/$version_file

    cd $CUR_DIR
    rm -rf temp/* 
}

main
