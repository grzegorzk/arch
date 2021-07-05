ARG ARCH_BOOTSTRAP_YEAR="$(date +%Y)"
ARG ARCH_BOOTSTRAP_MONTH="$(date +%m)"
ARG ARCH_BOOTSTRAP_DAY=01


FROM alpine:3 AS downloader

RUN apk update \
    && apk add --no-cache \
        curl \
        gnupg \
        procps

ARG ARCH_BOOTSTRAP_YEAR
ARG ARCH_BOOTSTRAP_MONTH
ARG ARCH_BOOTSTRAP_DAY
ARG ARCH_BOOTSTRAP_VERSION=${ARCH_BOOTSTRAP_YEAR}.${ARCH_BOOTSTRAP_MONTH}.${ARCH_BOOTSTRAP_DAY}

# Nameserver seems to improve stability of gpg
RUN ARCH_BOOTSTRAP_URL=http://pkg.adfinis-sygroup.ch/archlinux/iso/${ARCH_BOOTSTRAP_VERSION}/archlinux-bootstrap-${ARCH_BOOTSTRAP_VERSION}-x86_64.tar.gz \
    && echo "Downloading bootstrap from ${ARCH_BOOTSTRAP_URL}" \
    && cd /tmp \
    && curl -0 --insecure --connect-timeout 600 --expect100-timeout 600 ${ARCH_BOOTSTRAP_URL} > image.tar.gz \
    && curl -0 --insecure --connect-timeout 600 --expect100-timeout 600 ${ARCH_BOOTSTRAP_URL}.sig > image.tar.gz.sig

# Split signing so if anything fails on gpg end we don't have to download bootstrap image again
# If pgp.mit.edu fails then try pool.sks-keyservers.net
RUN mkdir -p ~/.gnupg \
    && echo standard-resolver > ~/.gnupg/dirmngr.conf \
    && chmod go= ~/.gnupg -R \
    && pkill -i -e dirmngr || true \
    && cd /tmp \
    && gpg -v --keyserver pgp.mit.edu --recv-keys 9741E8AC \
    && gpg -v --verify image.tar.gz.sig \
    && tar -xzf image.tar.gz \
    && rm image.tar.gz && rm image.tar.gz.sig

FROM scratch AS archbootstrap

COPY --from=downloader /tmp/root.x86_64 /
COPY docker_files/skim.sh /build/root/skim.sh

ARG ARCH_BOOTSTRAP_YEAR
ARG ARCH_BOOTSTRAP_MONTH
ARG ARCH_BOOTSTRAP_DAY
ARG ARCH_ARCHIVE_VERSION_FOR_BOOTSTRAP=${ARCH_BOOTSTRAP_YEAR}/${ARCH_BOOTSTRAP_MONTH}/${ARCH_BOOTSTRAP_DAY}
ARG ARCH_ARCHIVE_MIRROR=https://archive.archlinux.org/repos/${ARCH_ARCHIVE_VERSION_FOR_BOOTSTRAP}/\$repo/os/\$arch

RUN echo "Using packages mirror '${ARCH_ARCHIVE_MIRROR}' for installing packages in boostrap system" \
    && echo "Server = ${ARCH_ARCHIVE_MIRROR}" > /etc/pacman.d/mirrorlist \
    && cp /etc/pacman.conf /etc/pacman.conf.bak \
    && awk '{gsub(/SigLevel.*= Required DatabaseOptional/,"SigLevel = Never");gsub(/\[community\]/,"\[community\]\nSigLevel = Never");}1' /etc/pacman.conf.bak > /etc/pacman.conf \
    && pacman -Sy --noconfirm haveged wget sed \
    && cp /etc/pacman.conf.bak /etc/pacman.conf \
    && haveged -w 1024 \
    && pacman-key --init \
    && pacman-key --populate archlinux \
    && mkdir -p /build/var/lib/pacman \
    && sed -i -- 's/#\(XferCommand = \/usr\/bin\/wget \-\-passive\-ftp \-c \-O %o %u\)/\1/g' /etc/pacman.conf \
    && echo "Using packages mirror '${ARCH_ARCHIVE_MIRROR}' for installing packages in final system" \
    && echo "Server = ${ARCH_ARCHIVE_MIRROR}" > /etc/pacman.d/mirrorlist \
    && pacman -Sy --noconfirm archlinux-keyring ca-certificates \
    && pacman -r /build -Sy --disable-download-timeout --noconfirm \
        bash \
        bzip2 \
        gzip \
        grep \
        sed \
        haveged \
        pacman \
        nano \
        wget \
    && rm -rf /var/cache/pacman/pkg/* \
    && /bin/bash /build/root/skim.sh --root=/build \
    && sed -i -- 's/#\(XferCommand = \/usr\/bin\/wget \-\-passive\-ftp \-c \-O %o %u\)/\1/g' /build/etc/pacman.conf \
    && echo "Server = ${ARCH_ARCHIVE_MIRROR}" >> /build/etc/pacman.d/mirrorlist

FROM scratch AS arch

COPY --from=archbootstrap /build /

RUN haveged -w 1024 \
    && pacman-key --init \
    && pacman-key --populate archlinux

COPY docker_files/locale.gen /etc/locale.gen
COPY docker_files/locale.conf /etc/locale.conf

RUN locale-gen
