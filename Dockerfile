ARG ARCH_BOOTSTRAP_YEAR="$(date +%Y)"
ARG ARCH_BOOTSTRAP_MONTH="$(date +%m)"
ARG ARCH_BOOTSTRAP_DAY=01

ARG PACMAN_ARCHIVES_YEAR="$(date +%Y)"
ARG PACMAN_ARCHIVES_MONTH="$(date +%m)"
ARG PACMAN_ARCHIVES_DAY=01


FROM alpine:3 AS downloader

# Busybox tar does not support all features
RUN apk update \
    && apk add --no-cache \
        curl \
        gnupg \
        procps \
        tar \
        zstd

ARG ARCH_BOOTSTRAP_YEAR
ARG ARCH_BOOTSTRAP_MONTH
ARG ARCH_BOOTSTRAP_DAY
ARG ARCH_BOOTSTRAP_VERSION=${ARCH_BOOTSTRAP_YEAR}.${ARCH_BOOTSTRAP_MONTH}.${ARCH_BOOTSTRAP_DAY}
ARG ARCH_MIRROR

RUN ARCH_BOOTSTRAP_URL=${ARCH_MIRROR}/archlinux/iso/${ARCH_BOOTSTRAP_VERSION}/archlinux-bootstrap-x86_64.tar.zst \
    && ARCH_BOOTSTRAP_SIG_URL=https://archlinux.org/iso/${ARCH_BOOTSTRAP_VERSION}/archlinux-bootstrap-x86_64.tar.zst.sig \
    && echo "Downloading bootstrap from ${ARCH_BOOTSTRAP_URL}" \
    && cd /tmp \
    && curl -f -0 --insecure --connect-timeout 600 --expect100-timeout 600 ${ARCH_BOOTSTRAP_URL} > image.tar.zst \
    && echo "Downloading bootstrap .sig from ${ARCH_BOOTSTRAP_SIG_URL}" \
    && curl -f -0 --insecure --connect-timeout 600 --expect100-timeout 600 ${ARCH_BOOTSTRAP_SIG_URL} > image.tar.zst.sig

# Arch master keys: https://archlinux.org/master-keys/
RUN mkdir -p ~/.gnupg \
    && echo standard-resolver > ~/.gnupg/dirmngr.conf \
    && chmod go= ~/.gnupg -R \
    && pkill -i -e dirmngr || true \
    && cd /tmp \
    && echo "Obtaining the key from keyserver" \
    && curl -f -0 --insecure --connect-timeout 600 --expect100-timeout 600 -X GET 'https://pierre-schmitz.com/gpg-keys/pierre-packager-key.asc' > /tmp/pierre-packager-key.asc \
    && gpg --import /tmp/pierre-packager-key.asc \
    && echo "Verifying arch image" \
    && gpg -v --verify image.tar.zst.sig image.tar.zst \
    && tar -xf image.tar.zst \
    && rm image.tar.zst && rm image.tar.zst.sig

FROM scratch AS archbootstrap

COPY --from=downloader /tmp/root.x86_64 /
COPY docker_files/skim.sh /build/root/skim.sh

ARG PACMAN_ARCHIVES_YEAR
ARG PACMAN_ARCHIVES_MONTH
ARG PACMAN_ARCHIVES_DAY
ARG PACMAN_ARCHIVES_VERSION=${PACMAN_ARCHIVES_YEAR}/${PACMAN_ARCHIVES_MONTH}/${PACMAN_ARCHIVES_DAY}
ARG ARCH_ARCHIVE_MIRROR=https://archive.archlinux.org/repos/${PACMAN_ARCHIVES_VERSION}/\$repo/os/\$arch

RUN echo "Using packages mirror '${ARCH_ARCHIVE_MIRROR}' for installing packages in boostrap system" \
    && echo "Server = ${ARCH_ARCHIVE_MIRROR}" > /etc/pacman.d/mirrorlist \
    && cp /etc/pacman.conf /etc/pacman.conf.bak \
    && awk '{gsub(/SigLevel.*= Required DatabaseOptional/,"SigLevel = Never");gsub(/\[community\]/,"\[community\]\nSigLevel = Never");gsub(/DownloadUser.*=.*alpm/,"DownloadUser = alpm\nDisableSandbox");}1' /etc/pacman.conf.bak > /etc/pacman.conf \
    && pacman -Sy --noconfirm archlinux-keyring haveged sed wget \
    && cp /etc/pacman.conf.bak /etc/pacman.conf \
    && sed -i '/DownloadUser/a DisableSandbox' /etc/pacman.conf \
    && haveged -w 1024 \
    && pacman-key --init \
    && pacman-key --populate archlinux \
    && mkdir -p /build/var/lib/pacman \
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
        archlinux-keyring \
        nano \
        wget \
    && rm -rf /var/cache/pacman/pkg/* \
    && /bin/bash /build/root/skim.sh --root=/build \
    && sed -i '/DownloadUser/a DisableSandbox' /build/etc/pacman.conf \
    && echo "Server = ${ARCH_ARCHIVE_MIRROR}" >> /build/etc/pacman.d/mirrorlist

FROM scratch AS arch

COPY --from=archbootstrap /build /

RUN haveged -w 1024 \
    && pacman-key --init \
    && pacman-key --populate archlinux

COPY docker_files/locale.gen /etc/locale.gen
COPY docker_files/locale.conf /etc/locale.conf

RUN locale-gen
