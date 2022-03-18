# Copyright 2022 James Pace
# SPDX-License-Identifier: Apache-2.0
FROM docker.io/library/ros:galactic-ros-base AS base

# Prelude.
ENV DEBIAN_FRONTEND noninteractive
RUN apt update -y && \
    apt upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# Set up user.
# Touch file in home directory so we don't get bothered first call to sudo
RUN useradd -m -G sudo -s /bin/bash -u 1000 j7s && \
    bash -c 'echo "%sudo  ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/container' && \
    chmod 0440 /etc/sudoers.d/container && \
    touch /home/j7s/.sudo_as_admin_successful

# Switch user.
USER j7s

# Set up rosdep
RUN rosdep update

# Do the build.
FROM base AS builder

COPY --chown=1000:1000 workspace  /home/j7s/workspace
WORKDIR /home/j7s/workspace
RUN sudo apt update -y && \
    sudo apt upgrade -y && \
    rosdep install --ignore-src --simulate --reinstall --default-yes --from-path src > deps.bash && \
    rosdep install --ignore-src --from-path src --default-yes && \
    sudo rm -rf /var/lib/apt/lists/*
RUN . /opt/ros/$ROS_DISTRO/setup.sh && \
    colcon build

FROM base AS final

COPY --from=builder /home/j7s/workspace/install /opt/j7s
COPY --from=builder /home/j7s/workspace/deps.bash /opt/j7s/deps.bash
RUN sudo apt update -y && \
    sudo apt upgrade -y && \
    bash /opt/j7s/deps.bash && \
    sudo rm -rf /var/lib/apt/lists/*
