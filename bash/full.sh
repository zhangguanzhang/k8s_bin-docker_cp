#!/bin/bash

# need to run,don't change the sort
sync_class_list=(
    full
    single
    kube
    base
    )

tag_list=(
    kube-apiserver
    kube-controller-manager
    kube-proxy
    kube-scheduler
    kubectl
    kubelet
    apiextensions-apiserver
    cloud-controller-manager
    hyperkube
    kubeadm
    mounter
    full
    kube
    base
    )

# version
full::sync(){
    local tag=$1-full
    [ "$( hub_tag_exist $tag )" == null ] && {
        cat>Dockerfile<<-EOF
        FROM zhangguanzhang/alpine
        COPY $save_name /
EOF
        docker build -t zhangguanzhang/$img_name:$tag .
        docker push zhangguanzhang/$img_name:$tag
        echo zhangguanzhang/$img_name:$1-full > $CUR_DIR/tag/$tag
    } || :
}

# version
single::sync(){
    files=(
        kube-apiserver
        kube-controller-manager
        kube-proxy
        kube-scheduler
        kubectl
        kubelet
        apiextensions-apiserver
        cloud-controller-manager
        hyperkube
        kubeadm
        mounter
        )
    for file in ${files[@]};do
        [[ "$( hub_tag_exist $1-$file )" == null && -f kubernetes/server/bin/$file ] && {
            cat>Dockerfile<<-EOF
            FROM zhangguanzhang/alpine
            COPY kubernetes/server/bin/$file /
EOF
            docker build -t zhangguanzhang/$img_name:$1-$file .
            docker push zhangguanzhang/$img_name:$1-$file
            echo zhangguanzhang/$img_name:$1-$file > $CUR_DIR/tag/$1-$file
        } || :
    done
}

# version
kube::sync(){
    local tag=$1-kube
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
        rm -f $save_name
        tar zcvf $save_name kubernetes/server/bin/{$( paste -sd ','< <(xargs -n1<<<"${files[@]}") )}
        cat>Dockerfile<<-EOF
        FROM zhangguanzhang/alpine
        COPY $save_name /
EOF
        docker build -t zhangguanzhang/$img_name:$tag .
        docker push zhangguanzhang/$img_name:$tag
        echo zhangguanzhang/$img_name:$tag > $CUR_DIR/tag/$tag
        rm -f $save_name && cp zhangguanzhang $save_name
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
        rm -f $save_name
        tar zcvf $save_name kubernetes/server/bin/{$( paste -sd ','< <(xargs -n1<<<"${files[@]}") )}
        cat>Dockerfile<<-EOF
        FROM zhangguanzhang/alpine
        COPY $save_name /
EOF
        docker build -t zhangguanzhang/$img_name:$tag .
        docker push zhangguanzhang/$img_name:$tag
        echo zhangguanzhang/$img_name:$tag > $CUR_DIR/tag/$tag
        rm -f $save_name && cp zhangguanzhang $save_name
    } || :
}


main(){
    cd $CUR_DIR/temp
    while read version;do
        for list in "${tag_list[@]}";do
            [ "$( hub_tag_exist $version-$list )" == null ] && {
                printf -v version_url_download "$url_format" $version
                save_name=${version_url_download##*/}
                wget $version_url_download -O $save_name &>/dev/null
                tar -zxvf $save_name
                break
            }
        done
        [ -n "version_url_download" ] && {
            cp $save_name zhangguanzhang
            for run in ${sync_class_list[@]};do
                $run::sync $version
                [[ $(df -h| awk  '$NF=="/"{print +$5}') -ge "$max_per" ]] && docker image prune -f || :
            done
            rm -rf $save_name kubernetes/ zhangguanzhang
        }
    done < $version_file

    cd $CUR_DIR
    rm -rf temp/*
}

main
