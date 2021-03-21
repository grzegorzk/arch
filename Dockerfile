ARG ARCH_BOOTSTRAP_YEAR="$(date +%Y)"
ARG ARCH_BOOTSTRAP_MONTH="$(date +%m)"
ARG ARCH_BOOTSTRAP_DAY=01

ARG MIRROR='http://pkg.adfinis-sygroup.ch/archlinux/$repo/os/$arch'


FROM alpine:3 AS downloader

RUN apk update \
    && apk add --no-cache \
        curl \
        gnupg

ARG ARCH_BOOTSTRAP_YEAR
ARG ARCH_BOOTSTRAP_MONTH
ARG ARCH_BOOTSTRAP_DAY
ARG ARCH_BOOTSTRAP_VERSION=${ARCH_BOOTSTRAP_YEAR}.${ARCH_BOOTSTRAP_MONTH}.${ARCH_BOOTSTRAP_DAY}

# Nameserver seems to improve stability of gpg
RUN ARCH_BOOTSTRAP_URL=http://pkg.adfinis-sygroup.ch/archlinux/iso/${ARCH_BOOTSTRAP_VERSION}/archlinux-bootstrap-${ARCH_BOOTSTRAP_VERSION}-x86_64.tar.gz \
    && echo "Downloading bootstrap from ${ARCH_BOOTSTRAP_URL}" \
    && echo "nameserver 84.200.69.80" > /etc/resolv.conf \
    && cd /tmp \
    && curl -0 --insecure ${ARCH_BOOTSTRAP_URL} > image.tar.gz \
    && curl -0 --insecure ${ARCH_BOOTSTRAP_URL}.sig > image.tar.gz.sig \
    && gpg -v --keyserver pool.sks-keyservers.net --recv-keys 9741E8AC \
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
ARG ARCH_ARCHIVE_MIRROR_FOR_BOOTSTRAP=https://archive.archlinux.org/repos/${ARCH_ARCHIVE_VERSION_FOR_BOOTSTRAP}/\$repo/os/\$arch
ARG MIRROR

RUN echo "Using packages mirror '${ARCH_ARCHIVE_MIRROR_FOR_BOOTSTRAP}' for installing packages in boostrap system" \
    && echo "Server = ${ARCH_ARCHIVE_MIRROR_FOR_BOOTSTRAP}" > /etc/pacman.d/mirrorlist \
    && cp /etc/pacman.conf /etc/pacman.conf.bak \
    && awk '{gsub(/SigLevel.*= Required DatabaseOptional/,"SigLevel = Never");gsub(/\[community\]/,"\[community\]\nSigLevel = Never");}1' /etc/pacman.conf.bak > /etc/pacman.conf \
    && pacman -Sy --noconfirm haveged wget sed \
    && cp /etc/pacman.conf.bak /etc/pacman.conf \
    && haveged -w 1024 \
    && pacman-key --init \
    && pacman-key --populate archlinux \
    && mkdir -p /build/var/lib/pacman \
    && sed -i -- 's/#\(XferCommand = \/usr\/bin\/wget \-\-passive\-ftp \-c \-O %o %u\)/\1/g' /etc/pacman.conf \
    && echo "Using packages mirror '${MIRROR}' for installing packages in final system" \
    && echo "Server = ${MIRROR}" > /etc/pacman.d/mirrorlist \
    && pacman -Sy --noconfirm archlinux-keyring ca-certificates \
    && rm -rf /etc/pacman.d/gnupg \
    && pacman-key --init \
    && pacman-key --populate archlinux \
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
    && echo "Server = ${MIRROR}" >> /build/etc/pacman.d/mirrorlist

FROM scratch AS arch

COPY --from=archbootstrap /build /

RUN haveged -w 1024 \
    && pacman-key --init \
    && pacman-key --populate archlinux

COPY docker_files/locale.gen /etc/locale.gen
COPY docker_files/locale.conf /etc/locale.conf

RUN locale-gen
