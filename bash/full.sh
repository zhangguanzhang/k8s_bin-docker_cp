#!/bin/bash

cd $CUR_DIR/temp

version_file='version_file'
url_format='https://dl.k8s.io/%s/kubernetes-server-linux-amd64.tar.gz'

# tag
hub_tag_exist(){
    curl -s https://hub.docker.com/v2/repositories/${MY_REPO}/${img_name}/tags/$1/ | jq -r .name
}

curl -s https://www.zhangguanzhang.com/pull | bash -s search gcr.io/google_containers/kube-apiserver-amd64/ | 
    grep -P 'v[\d.]+$' | sort -t '.' -n -k 2 > $version_file

while read version;do
    tag=$version-full
    [ "$( hub_tag_exist $tag )" != null ] && continue
    printf -v version_url_download "$url_format" $version
    wget $version_url_download -O ${version_url_download##*/}
    cat>Dockerfile<<-EOF
	FROM　zhangguanzhang/alpine
	COPY ${version_url_download##*/} /
EOF
    docker build -t zhangguanzhang/k8s_bin:$tag .
    docker push zhangguanzhang/$img_name:$tag
done < $version_file


cd $CUR_DIR
rm -rf temp/*
