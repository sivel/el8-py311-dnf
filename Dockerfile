FROM quay.io/centos/centos:stream8 as build

USER root
WORKDIR /root

ENV LC_ALL=C.UTF-8

RUN set -eux && \
    dnf install -y dnf-plugins-core python3.11-devel python3.11-pip python3.11-wheel bzip2 nss-devel diffutils && \
    dnf builddep --enablerepo=powertools -y rpm dnf libdnf libcomps gpgme && \
    dnf download --source rpm libdnf dnf libcomps gpgme && \
    rpm -ivh *.src.rpm && \
    pushd /root/rpmbuild/SOURCES/ && \
        find . -type f -name "*.tar.*" -exec tar xaf {} \; && \
    popd

COPY pyproject.toml /root/pyproject.toml
COPY dnf-setup.cfg /root/dnf-setup.cfg
COPY libdnf-setup.cfg /root/libdnf-setup.cfg
COPY cmake-setup.py /root/cmake-setup.py

WORKDIR /root/rpmbuild/SOURCES/

RUN set -eux && \
    pushd rpm*/ && \
        sed -i 's/python2/python3.11/' configure.ac && \
        autoreconf -i -f && \
        ./configure && \
        pushd python && \
            python3.11 -m pip wheel -w /root/wheels . && \
        popd && \
    popd

RUN set -eux && \
    pushd libdnf*/ && \
        echo '@LIBDNF_VERSION@' > VERSION.in && \
        echo 'configure_file("VERSION.in" "VERSION")' >> CMakeLists.txt && \
        cmake . -DWITH_GIR=0 -DWITH_MAN=0 -Dgtkdoc=0 -DWITH_ZCHUNK=OFF && \
        pushd bindings/python && \
            make preinstall && \
        popd && \
        pushd python/hawkey && \
            make preinstall && \
        popd && \
        cp /root/cmake-setup.py setup.py && \
        cp /root/pyproject.toml . && \
        cat /root/libdnf-setup.cfg >> setup.cfg && \
        python3.11 -m pip wheel -w /root/wheels . && \
    popd

RUN set -eux && \
    pushd dnf*/ && \
        cmake . && \
        cp /root/cmake-setup.py setup.py && \
        cp /root/pyproject.toml . && \
        cat /root/dnf-setup.cfg >> setup.cfg && \
        python3.11 -m pip wheel -w /root/wheels . && \
    popd

RUN set -eux && \
    pushd libcomps*/ && \
        python3.11 -m pip wheel -w /root/wheels . && \
    popd

RUN set -eux && \
    pushd gpgme*/ && \
        ./configure --disable-static --disable-silent-rules --enable-languages=python && \
        pushd lang/python/ && \
            ln -sf "../../src/data.h" . && \
            ln -sf "../../conf/config.h" . && \
            ln -sf "./src" gpg && \
            ln -sf "../../src/gpgme.h" . && \
            python3.11 -m pip wheel -w /root/wheels . && \
        popd && \
    popd

FROM quay.io/centos/centos:stream8
COPY --from=build /root/wheels /root/wheels
WORKDIR /root/wheels
