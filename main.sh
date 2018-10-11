#!/bin/bash

export CUR_DIR version_file MY_REPO img_name

readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

shell_dir='bash'
version_file='version_file'
MY_REPO=zhangguanzhang
img_name=k8s_bin



git_init(){
    git config --global user.name "zhangguanzhang"
    git config --global user.email zhangguanzhang@qq.com
    git remote rm origin
    git remote add origin git@github.com:zhangguanzhang/k8s_bin-docker_cp.io.git
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
    mkdir -p temp

    git_init

    while read shell_file;do
        source $shell_file
    done < <(find shell_dir -type f -name '*.sh')
    rm -rf temp
    git_commit
}

main
