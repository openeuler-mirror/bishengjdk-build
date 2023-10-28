# bishengjdk-build

#### Description
BiSheng JDK build and test scripts - common across all releases/versions

#### Software Architecture description

Currently,It is mainly used in the access control PR project and version building project automation script of BiSheng JDK. Supports software construction of the Linux aarch64 and Linux X64 architectures.

#### Instructions

1、download bishengjdk code
   Note: By default, the latest tag in the code repository is used as the build. If the latest tag is not the latest code submission point, you need to re-tag it.

```
mkdir -p /home/bishengjdk/
cd /home/bishengjdk/
git clone https://gitee.com/openeuler/bishengjdk-8.git
```

2、Download and decompress bootjdk(eg: OpenJDK8u392)

```
wget https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u392-b08/OpenJDK8U-jdk_x64_linux_hotspot_8u392b08.tar.gz

mkdir bootjdk_dir
mv OpenJDK8U-jdk_x64_linux_hotspot_8u392b08.tar.gz bootjdk_dir/
cd bootjdk_dir
tar -xf OpenJDK8U-jdk_x64_linux_hotspot_8u392b08.tar.gz
```

3、Create the run.sh script in the same directory as bootjdk_dir

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

4、Execute the build

```
bash run.sh
```

5、Obtaining the "tar.gz" software package

```
cd results
```

#### Contribution

1.  Fork the repository
2.  Create Feat_xxx branch
3.  Commit your code
4.  Create Pull Request


#### Gitee Feature

1.  You can use Readme\_XXX.md to support different languages, such as Readme\_en.md, Readme\_zh.md
2.  Gitee blog [blog.gitee.com](https://blog.gitee.com)
3.  Explore open source project [https://gitee.com/explore](https://gitee.com/explore)
4.  The most valuable open source project [GVP](https://gitee.com/gvp)
5.  The manual of Gitee [https://gitee.com/help](https://gitee.com/help)
6.  The most popular members  [https://gitee.com/gitee-stars/](https://gitee.com/gitee-stars/)
