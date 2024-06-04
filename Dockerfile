FROM quay.io/centos/centos:stream8

USER root
WORKDIR /root

ENV LC_ALL=C.UTF-8

COPY pyproject.toml /root/pyproject.toml
COPY dnf-setup.cfg /root/dnf-setup.cfg
COPY libdnf-setup.cfg /root/libdnf-setup.cfg
COPY cmake-setup.py /root/cmake-setup.py
COPY build.sh /root/build.sh

WORKDIR /root/rpmbuild/SOURCES/

CMD ["/bin/bash", "/root/build.sh"]
