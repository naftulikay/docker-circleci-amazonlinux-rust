FROM amazonlinux:2017.03.1.20170812

MAINTAINER Naftuli Kay <me@naftuli.wtf>

ENV RUST_USER=circleci
ENV RUST_HOME=/home/${RUST_USER}

ENV _TOOL_PACKAGES="\
  autoconf \
  automake \
  bash-completion \
  cmake \
  curl \
  file \
  gcc \
  git \
  jq \
  libtool \
  make \
  man \
  man-pages \
  pcre-tools \
  pkgconfig \
  python-pip \
  python34-pip \
  sudo \
  tree \
  unzip \
  wget \
  which \
  zip \
  "
ENV _STATIC_PACKAGES="\
  glibc-static \
  openssl-static \
  pcre-static \
  zlib-static \
  "

ENV _DEVEL_PACKAGES="\
  binutils-devel \
  openssl-devel \
  kernel-devel \
  libcurl-devel \
  libffi-devel \
  pcre-devel \
  python-devel \
  python34-devel \
  xz-devel \
  zlib-devel \
  "

# upgrade all packages, install epel, then install build requirements
RUN yum upgrade -y > /dev/null && \
  yum install -y epel-release >/dev/null && \
  yum install -y ${_TOOL_PACKAGES} ${_STATIC_PACKAGES} ${_DEVEL_PACKAGES} && \
  yum clean all

# install and upgrade pip and utils
RUN pip-3.4 install --upgrade pip setuptools && pip-3.4 install awscli

# add ldconfig for /usr/local
RUN echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf

# create sudo group and add sudoers config
COPY conf/sudoers.d/50-sudo /etc/sudoers.d/
RUN groupadd sudo && useradd -G sudo -u 1000 -U ${RUST_USER}

# add rust profile setup
COPY conf/profile.d/base.sh conf/profile.d/rust.sh /etc/profile.d/

# deploy our tfenv command
RUN install -o ${RUST_USER} -g ${RUST_USER} -m 0700 -d ${RUST_HOME}/.local ${RUST_HOME}/.local/bin
COPY bin/tfenv ${RUST_HOME}/.local/bin
RUN chmod 0755 ${RUST_HOME}/.local/bin/tfenv && \
  chown ${RUST_USER}:${RUST_USER} ${RUST_HOME}/.local/bin/tfenv

# install rustup
RUN curl https://sh.rustup.rs -sSf | sudo -u ${RUST_USER} sh -s -- -y && \
  ${RUST_HOME}/.cargo/bin/rustup completions bash | tee /etc/bash_completion.d/rust >/dev/null && \
  chmod 0755 /etc/bash_completion.d/rust && \
  rsync -a ${RUST_HOME}/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/share/man/man1/ /usr/local/share/man/man1/

# degoss the image
COPY bin/degoss goss.yml /tmp/
RUN /tmp/degoss /tmp/goss.yml

USER ${RUST_USER}
WORKDIR ${RUST_HOME}
ENV ["PATH", "/home/${RUST_USER}/.cargo/bin:/home/${RUST_USER}/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"]

CMD ["/bin/bash", "-l"]
