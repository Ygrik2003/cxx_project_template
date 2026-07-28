FROM archlinux:latest AS archlinux-nodeps

# Toolchain
RUN pacman -Suy --noconfirm \
    cmake \
    clang \
    gcc \
    ninja \
    mold \
    libc++ \
    git \
    sudo \
    pkgconf \
    # GUI/GPU runtime for SDL3: wayland, x11, GL/Vulkan, audio, input
    wayland \
    wayland-protocols \
    libxkbcommon \
    libdecor \
    libx11 \
    libxext \
    libxcursor \
    libxi \
    libxrandr \
    libxfixes \
    libxss \
    libxtst \
    libxrender \
    libxkbcommon-x11 \
    mesa \
    libglvnd \
    libdrm \
    vulkan-icd-loader \
    vulkan-intel \
    pipewire \
    alsa-lib \
    dbus \
    libinput \
    libusb

# HACK: On archlinux in /usr/lib/gcc/x86_64-pc-linux-gnu/16/libstdc++.modules.json wrong path to std.cc and std.compat.cc
RUN sed -i 's#\.\./include/c++/16/#/usr/include/c++/16/#g' /usr/lib/gcc/x86_64-pc-linux-gnu/16/libstdc++.modules.json

ARG USER_NAME=dev
ARG USER_UID=1369002843
ARG USER_GID=1369000513
ARG RENDER_GID=988
ARG VIDEO_GID=984

RUN set -eux; \
    for gid in "${USER_GID}" "${RENDER_GID}" "${VIDEO_GID}"; do \
    getent group "${gid}" >/dev/null || groupadd --gid "${gid}" "hostgrp${gid}"; \
    done; \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USER_NAME}"; \
    usermod --append --groups "${RENDER_GID},${VIDEO_GID}" "${USER_NAME}"; \
    printf '%s ALL=(ALL) NOPASSWD: ALL\n' "${USER_NAME}" > "/etc/sudoers.d/${USER_NAME}"; \
    chmod 0440 "/etc/sudoers.d/${USER_NAME}"

FROM archlinux-nodeps AS archlinux-withdeps

RUN pacman -Suy --noconfirm \
    sdl3


FROM gradle:jdk26-corretto-al2023 AS android-nodeps
# TODO NOT TEST
RUN mkdir "$TLT_ANDROID_HOME" .android \
    && cd "$TLT_ANDROID_HOME" \
    && curl -o sdk.zip $TLT_SDK_URL \
    && unzip sdk.zip \
    && rm sdk.zip \
    # В следующих строчках мы создаем папку и текстовые файлы 
    # с лицензиями. На оф. сайте Android написано что мы 
    # можем копировать эти файлы с машин где вручную эти 
    # лицензии подтвердили и что автоматически 
    # их сгенерировать нельзя
    && mkdir "$TLT_ANDROID_HOME/licenses" || true \
    && echo "24333f8a63b6825ea9c5514f83c2829b004d1" > "$TLT_ANDROID_HOME/licenses/android-sdk-license" \
    && echo "84831b9409646a918e30573bab4c9c91346d8" > "$TLT_ANDROID_HOME/licenses/android-sdk-preview-license" \   
    # Запускаем обновление SDK и установку build-tools, platform-tools
    && $TLT_ANDROID_HOME/tools/bin/sdkmanager --update \
    && $TLT_ANDROID_HOME/tools/bin/sdkmanager "build-tools;${TLT_ANDROID_BUILD_TOOLS_VERSION}" \
    "platforms;android-${TLT_ANDROID_VERSION}" \
    "platform-tools"