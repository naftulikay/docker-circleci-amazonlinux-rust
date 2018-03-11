FROM centos:7

MAINTAINER Naftuli Kay <me@naftuli.wtf>

ENV RUST_USER=rust
ENV RUST_HOME=/home/${RUST_USER}

# upgrade all packages, install epel, then install build requirements
RUN yum upgrade -y > /dev/null && \
  yum install -y epel-release >/dev/null && \
  yum install -y sudo unzip git openssl-devel kernel-devel which make gcc python-devel python34-devel python-pip \
    curl file autoconf automake cmake libtool libcurl-devel binutils-devel zlib-devel wget xz-devel pkgconfig \
    bash-completion man-pages tree jq zip && \
  yum clean all

# install and upgrade pip and utils
RUN pip install --upgrade pip && pip install awscli ansible

# add ldconfig for /usr/local
RUN echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf

# create sudo group and add sudoers config
COPY conf/sudoers.d/50-sudo /etc/sudoers.d/
RUN groupadd sudo && adduser -G sudo -m ${RUST_USER}

# deploy our ansible
RUN mkdir /tmp/docker
COPY ansible.cfg docker.yml requirements-docker.yml /tmp/docker/
RUN ( cd /tmp/docker && ansible-galaxy install --force -r requirements-docker.yml && \
  ansible-playbook -c local -i 127.0.0.1, -e rust_user=${RUST_USER} docker.yml ) && \
  rm -r /tmp/docker

# deploy our tfenv command
RUN install -o ${RUST_USER} -g ${RUST_USER} -m 0700 -d ${RUST_HOME}/.local ${RUST_HOME}/.local/bin
COPY bin/tfenv ${RUST_HOME}/.local/bin
RUN chmod 0755 ${RUST_HOME}/.local/bin/tfenv && \
  chown ${RUST_USER}:${RUST_USER} ${RUST_HOME}/.local/bin/tfenv

USER ${RUST_USER}
WORKDIR ${RUST_HOME}

CMD ["/bin/bash", "-l"]
