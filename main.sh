#!/bin/bash

# MINISHIFT_GITHUB_API_TOKEN=f62950fc041df6f8788a7d23157a39936a0af440


[ -n "$DEBUG" ] && set -x
export CUR_DIR version_file MY_REPO img_name max_per url_format

readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
max_per=70
shell_dir='bash'
export MY_REPO=zhangguanzhang
url_format='https://dl.k8s.io/%s/kubernetes-server-linux-amd64.tar.gz'
[ -n "$ALI_DOCKER_PASS" ] && {
    docker login -u zhangguanzhang@qq.com registry.aliyuncs.com -p ${ALI_DOCKER_PASS}
}

git_init(){
    git config --global user.name "zhangguanzhang"
    git config --global user.email zhangguanzhang@qq.com
    git remote rm origin
    git remote add origin git@github.com:zhangguanzhang/k8s_bin-docker_cp.git
    git pull
    if git branch -a |grep 'origin/develop' &> /dev/null ;then
        git checkout develop
        git pull origin develop
        git branch --set-upstream-to=origin/develop develop
    else
        git checkout -b develop
        git pull origin develop
    fi
}

git_commit(){
     local COMMIT_FILES_COUNT=$(git status -s|wc -l)
     local TODAY=$(date +%F)
     if [ "$COMMIT_FILES_COUNT" -ne 0 ];then
        git add -A
        git commit -m "Synchronizing completion at $TODAY"
        git push -u origin develop
     fi
}


main(){
    [ -z "$start_time" ] && start_time=$(date +%s)
    sudo cp -r bash /
    git_init
    mkdir -p temp sync
    sudo  rm -rf bash  README.md ;yes|sudo  cp -r /bash .  # 确保master分支的README和脚步文件修改后会被此处逻辑带到develop分之下
    wget https://raw.githubusercontent.com/zhangguanzhang/k8s_bin-docker_cp/master/README.md
    ls -l;ls -l temp
#     while true;do
#         curl -sX GET https://api.github.com/repos/zhangguanzhang/gcr.io/contents/gcr.io/google_containers/kube-apiserver-amd64?ref=develop |
#             jq -r '.[].name' | grep -P 'v[\d.]+$' | sort -t '.' -n -k 2 &> $version_file
#         [ "$(perl -nle 'END{print $.}'l $version_file)" -eq 10 ] && break
#     done
    while read shell_file;do
        source $shell_file $(awk -F'/' '{print $2}'<<<$shell_file)
    done < <(find $shell_dir -type f -name '*.sh')
    rm -rf temp
    git_commit
}

main

