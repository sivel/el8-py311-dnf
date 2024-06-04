#!/bin/bash

set -eux

sed -i 's/^mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Stream-*
sed -i 's/^#baseurl/baseurl/g' /etc/yum.repos.d/CentOS-Stream-*
sed -i 's/mirror.centos.org/vault.centos.org/g' /etc/yum.repos.d/CentOS-Stream-*

dnf install -y dnf-plugins-core python3.12-devel python3.12-pip python3.12-wheel bzip2 nss-devel diffutils
dnf builddep --enablerepo=powertools -y rpm dnf libdnf libcomps gpgme
dnf download --source rpm libdnf dnf libcomps gpgme
rpm -ivh *.src.rpm 2>/dev/null
pushd /root/rpmbuild/SOURCES/
    find . -type f -name "*.tar.*" -exec tar xaf {} \;
popd

pushd rpm*/
    sed -i 's/python2/python3.12/' configure.ac
    autoreconf -i -f
    ./configure
    pushd python
        python3.12 -m pip wheel -w /root/wheels .
    popd
popd

pushd libdnf*/
    echo '@LIBDNF_VERSION@' > VERSION.in
    echo 'configure_file("VERSION.in" "VERSION")' >> CMakeLists.txt
    cmake . -DWITH_GIR=0 -DWITH_MAN=0 -Dgtkdoc=0 -DWITH_ZCHUNK=OFF
    pushd bindings/python
        make preinstall
    popd
    pushd python/hawkey
        make preinstall
    popd
    cp /root/cmake-setup.py setup.py
    cp /root/pyproject.toml .
    cat /root/libdnf-setup.cfg >> setup.cfg
    python3.12 -m pip wheel -w /root/wheels .
popd

pushd dnf*/
    cmake .
    cp /root/cmake-setup.py setup.py
    cp /root/pyproject.toml .
    cat /root/dnf-setup.cfg >> setup.cfg
    python3.12 -m pip wheel -w /root/wheels .
popd

pushd libcomps*/
    python3.12 -m pip wheel -w /root/wheels .
popd

pushd gpgme*/
    ./configure --disable-static --disable-silent-rules --enable-languages=python
    pushd lang/python/
        ln -sf "../../src/data.h" .
        ln -sf "../../conf/config.h" .
        ln -sf "./src" gpg
        ln -sf "../../src/gpgme.h" .
        python3.12 -m pip wheel -w /root/wheels .
    popd
popd
