# ==============================
# Stage 1: Builder
# ==============================
ARG ARCH=x86_64
ARG OPENWRT_TAG=x86-64-24.10.2
ARG VERSION=0.9.1

FROM --platform=linux/${ARCH} openwrt/rootfs:${OPENWRT_TAG} AS builder

ARG ARCH
ARG VERSION

# ------------------------------
# 1️⃣ 安装基本工具
# ------------------------------
RUN set -eux \
    && mkdir -p /var/lock /var/run \
    && opkg update \
    && opkg install curl

# ------------------------------
# 2️⃣ 构建 sysroot 目录结构
# ------------------------------
RUN set -eux \
    && SYSROOT="/sysroot" \
    && mkdir -p \
        "$SYSROOT/bin" \
        "$SYSROOT/dev" \
        "$SYSROOT/etc" \
        "$SYSROOT/lib" \
        "$SYSROOT/mnt" \
        "$SYSROOT/proc" \
        "$SYSROOT/root" \
        "$SYSROOT/sbin" \
        "$SYSROOT/sys" \
        "$SYSROOT/tmp/lib" \
        "$SYSROOT/tmp/lock" \
        "$SYSROOT/tmp/log" \
        "$SYSROOT/tmp/run" \
        "$SYSROOT/tmp/tmp" \
        "$SYSROOT/usr" \
    && ln -s tmp "$SYSROOT/var" \
    && ln -s /var/run "$SYSROOT/run" \
    && { if [ -e /lib64 ]; then ln -s lib "$SYSROOT/lib64"; fi; } \
    && cp -a \
        /etc/fstab \
        /etc/group \
        /etc/hosts \
        /etc/mtab \
        /etc/opkg \
        /etc/passwd \
        /etc/shadow \
        /etc/shells \
        "$SYSROOT/etc"

# ------------------------------
# 3️⃣ 安装核心包到 sysroot
# ------------------------------
RUN set -eux \
    && core_url=$(grep " openwrt_core " /etc/opkg/distfeeds.conf | cut -d" " -f3) \
    && echo "core_url=$core_url" \
    && libc_info=$(opkg info libc) \
    && kern_info=$(opkg info kernel) \
    && libc_ver=$(echo "$libc_info" | grep "^Version: " | cut -d" " -f2) \
    && kern_ver=$(echo "$kern_info" | grep "^Version: " | cut -d" " -f2) \
    && libc_arch=$(echo "$libc_info" | grep "^Architecture: " | cut -d" " -f2) \
    && kern_arch=$(echo "$kern_info" | grep "^Architecture: " | cut -d" " -f2) \
    && libc_pkg="$core_url/libc""_$libc_ver""_$libc_arch"".ipk" \
    && kern_pkg="$core_url/kernel""_$kern_ver""_$kern_arch"".ipk" \
    && opkg --offline-root "$SYSROOT" update \
    && opkg --offline-root "$SYSROOT" install \
        "$libc_pkg" \
        "$kern_pkg" \
        busybox \
        ip6tables-zz-legacy \
        iptables-zz-legacy \
        iptables-mod-conntrack-extra \
        iptables-mod-nfqueue \
        nftables-nojson

# ------------------------------
# 4️⃣ 下载并安装 fakesip
# ------------------------------
RUN set -eux \
    && cd /root \
    && curl -Lfo "fakesip-linux-x86_64.tar.gz" \
       "https://github.com/MikeWang000000/FakeSIP/releases/download/${VERSION}/fakesip-linux-x86_64.tar.gz" \
    && tar xzf "fakesip-linux-x86_64.tar.gz" \
    && cp "fakesip-linux-x86_64/fakesip" "$SYSROOT/usr/sbin/fakesip" \
    && rm -rf \
        "$SYSROOT/etc/modules.d" \
        "$SYSROOT/etc/modules-boot.d" \
        "$SYSROOT/etc/opkg" \
        "$SYSROOT/etc/sysctl.d" \
        "$SYSROOT/lib/modules" \
        "$SYSROOT/usr/lib/opkg"

# ==============================
# Stage 2: Scratch
# ==============================
FROM scratch

COPY --from=builder /sysroot /

ENV HOME=/root
ENV PATH=/usr/sbin:/usr/bin:/sbin:/bin
ENV LANG=C.UTF-8
ENV LANGUAGE=C.UTF-8
ENV LC_ALL=C.UTF-8

ENTRYPOINT ["/usr/sbin/fakesip"]
