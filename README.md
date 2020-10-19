# k8s_bin
此仓库是`travis-ci`同步k8s相关的二进制文件(缺省架构为amd64)到dockerhub上的`zhangguanzhang/k8s_bin`镜像和阿里云仓库`registry.aliyuncs.com/zhangguanzhang/k8s_bin`
tag规则为`$version-$type`

type为下面几种
 * full: 官方的包
 * 压缩包里kubernetes/server/bin/下所有二进制文件,例如`v1.12.1-kubectl`
 * kube: k8s的kubeadm+hyperkube+k8s基础的二进制文件
 * base: 最基础的k8s二进制文件,包含`kube-apiserver,kube-controller-manager,kube-proxy,kube-scheduler,kubectl,kubelet`
 
 例如下载1.12.1的官方包
 ```
 VERSION=v1.12.1
 TYPE=full
 ```

除了es的镜像，都可以用阿里的镜像仓库地址下载，`docker pull registry.aliyuncs.com/zhangguanzhang/k8s_bin:$VERSION-$TYPE`

 ```bash
 docker pull zhangguanzhang/k8s_bin:$VERSION-$TYPE
 docker run --rm -d --name temp zhangguanzhang/k8s_bin:$VERSION-$TYPE sleep 12
 docker cp temp:/kubernetes-server-linux-amd64.tar.gz .
 ```
 例如下载1.12.1的基础二进制文件
 VERSION=v1.12.1
 TYPE=base
 ```bash
 docker pull registry.aliyuncs.com/zhangguanzhang/k8s_bin:$VERSION-$TYPE
 docker run --rm -d --name temp registry.aliyuncs.com/zhangguanzhang/k8s_bin:$VERSION-$TYPE sleep 12
 docker cp temp:/kubernetes-server-linux-amd64.tar.gz .
 ```
 
 例如下载1.12.1的kubelet
 ```bash
 VERSION=v1.12.1
 TYPE=kubelet
 docker pull registry.aliyuncs.com/zhangguanzhang/k8s_bin:$VERSION-$TYPE
 docker run --rm -d --name temp registry.aliyuncs.com/zhangguanzhang/k8s_bin:$VERSION-$TYPE sleep 12
 docker cp temp:/kubelet .
 ```

docker.elastic.co镜像
```
curl -s 'https://www.docker.elastic.co/#' | perl -lne 'if(/docker pull/){s/<\/?strong>//g;/docker pull \K[^<]+/;print $&}' | grep -w 你镜像名
# 重命名规则
es_pull(){
    docker pull $@
    read null ns img < <(tr / ' ' <<<$@)
    newName=zhangguanzhang/$ns-$img
    sh_name=zhangguanzhang/$(tr / .<<<$@) # 镜像名的/换成.然后前面zhangguanzhang/
    docker tag $@  $newName
    docker tag $@  $sh_name
    docker push $newName
    docker push $sh_name
}
zhangguanzhang/
```
