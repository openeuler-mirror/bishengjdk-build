# bishengjdk-build

#### 介绍

BiSheng JDK build and test scripts - common across all releases/versions

#### 软件架构

目前主要用于毕昇jdk的门禁工程、版本构建工程自动化脚本使用。支持Linux aarch64、Linux X64架构的二进制版本构建。

#### 使用说明

1、拉取代码
   注意：默认使用代码仓最新的tag作为构建代码点，如果最新的tag不是最新代码提交点，你需要重新打tag.
```
mkdir -p /home/bishengjdk/
cd /home/bishengjdk/
git clone https://gitee.com/openeuler/bishengjdk-8.git
```

2、下载bootjdk并解压（以OpenJDK8u392为例）

```
wget https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u392-b08/OpenJDK8U-jdk_x64_linux_hotspot_8u392b08.tar.gz

mkdir bootjdk_dir
mv OpenJDK8U-jdk_x64_linux_hotspot_8u392b08.tar.gz bootjdk_dir/
cd bootjdk_dir
tar -xf OpenJDK8U-jdk_x64_linux_hotspot_8u392b08.tar.gz
```

3、在于bootjdk_dir同目录下，创建脚本run.sh

```
#boot_jdk17=/home/wangkun/bootjdk_dir/jdk-17.0.9+9
boot_jdk8=/home/wangkun/bootjdk_dir/jdk8u392-b08

for i in jdk8
do
rm -rm bishengjdk-build
git clone https://gitee.com/openeuler/bishengjdk-build.git
cd bishengjdk-build
jdk_name=boot_${i}
bash build.sh --build-type release --build-variant "$i" --boot-jdk-dir "${!jdk_name}" --create-jre-image --build-number 13

cd ..
rm -rf results/${i}
mkdir -p results/${i}
mv bishengjdk-build/output/* results/${i}/
done
```

4、执行构建

```
bash run.sh
```

5、获取tar.gz的软件包

```
cd results
里面是构建出来的jdk的软件包
```

#### 参与贡献
1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request


#### 特技

1.  使用 Readme\_XXX.md 来支持不同的语言，例如 Readme\_en.md, Readme\_zh.md
2.  Gitee 官方博客 [blog.gitee.com](https://blog.gitee.com)
3.  你可以 [https://gitee.com/explore](https://gitee.com/explore) 这个地址来了解 Gitee 上的优秀开源项目
4.  [GVP](https://gitee.com/gvp) 全称是 Gitee 最有价值开源项目，是综合评定出的优秀开源项目
5.  Gitee 官方提供的使用手册 [https://gitee.com/help](https://gitee.com/help)
6.  Gitee 封面人物是一档用来展示 Gitee 会员风采的栏目 [https://gitee.com/gitee-stars/](https://gitee.com/gitee-stars/)
