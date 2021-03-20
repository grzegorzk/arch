ARG ARCH_ARCHIVE_YEAR=2021
ARG ARCH_ARCHIVE_MONTH=03
ARG ARCH_ARCHIVE_DAY=01

FROM alpine:3 AS downloader

RUN apk update \
    && apk add --no-cache \
        curl \
        gnupg

ARG ARCH_ARCHIVE_YEAR
ARG ARCH_ARCHIVE_MONTH
ARG ARCH_ARCHIVE_DAY
ARG ARCH_BOOTSTRAP_VERSION=${ARCH_ARCHIVE_YEAR}.${ARCH_ARCHIVE_MONTH}.${ARCH_ARCHIVE_DAY}
ARG ARCH_BOOTSTRAP_URL=http://pkg.adfinis-sygroup.ch/archlinux/iso/${ARCH_BOOTSTRAP_VERSION}/archlinux-bootstrap-${ARCH_BOOTSTRAP_VERSION}-x86_64.tar.gz

# Nameserver seems to improve stability of gpg
RUN echo "Downloading bootstrap from ${ARCH_BOOTSTRAP_URL}" \
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

ARG ARCH_ARCHIVE_YEAR
ARG ARCH_ARCHIVE_MONTH
ARG ARCH_ARCHIVE_DAY
ARG ARCH_ARCHIVE_VERSION=${ARCH_ARCHIVE_YEAR}/${ARCH_ARCHIVE_MONTH}/${ARCH_ARCHIVE_DAY}
ARG ARCH_ARCHIVE_MIRROR=https://archive.archlinux.org/repos/${ARCH_ARCHIVE_VERSION}/\$repo/os/\$arch

RUN echo "Using packages mirror: ${ARCH_ARCHIVE_MIRROR}" \
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
    && echo "Removing unused locale, leaving only en_US locale" \
    && mv -vf /build/usr/share/locale/{en_US,locale.alias} /tmp \
    && rm -r /build/usr/share/locale/* \
    && mv -vf /tmp/{en_US,locale.alias} /build/usr/share/locale/ \
    && mv -vf /build/usr/share/i18n/locales/{en_US,en_GB,i18n,i18n_ctype,iso14651_t1,iso14651_t1_common,translit_*} /tmp \
    && rm -r /build/usr/share/i18n/locales/* \
    && mv -vf /tmp/{en_US,en_GB,i18n,i18n_ctype,iso14651_t1,iso14651_t1_common,translit_*} /build/usr/share/i18n/locales/ \
    && echo "Removing unused timezones, leaving only UTC timezone" \
    && mv -vf /build/usr/share/zoneinfo/UTC /tmp \
    && rm -r /build/usr/share/zoneinfo/* \
    && mv -vf /tmp/UTC /build/usr/share/zoneinfo \
    && echo "Removing man pages" \
    && rm -r /build/usr/share/man/* \
    && rm -r /build/usr/share/info/* \
    && rm -r /build/usr/share/doc/* \
    && echo "Removing include and *.a files" \
    && rm /build/usr/lib/*.a \
    && rm -r /build/usr/include/* \
    && echo "Not planning to use programs written in GO" \
    && rm /build/usr/lib/libgo.so* \
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
