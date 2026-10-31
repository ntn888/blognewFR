---
title: "Setting up a container based ARM-cortex development environment"
description: "Ditch Distrobox; setup lean ephemeral environments using Dockerfile"
date: 2026-10-25T10:26:00
draft: false
category: ["misc"]
tags: ["sdk", "podman", "dev-env"]
---

In the past we'd looked at *Distrobox* as a means to setup ephemeral environments. Here we take a more traditional and a lighter path, direct on the container engine.

For this we'll be using *Podman*. It's an alternative to the ever popular Docker, but I find Podman integrates better with the rest of Linux. Of course you may prefer Docker, in that case just substitute the commands, they'd be identical.

Now, this is not a primer on containers, so we'll breeze past the setup, but feel free to look up the concepts if you're inclined. First install Podman on your system. For Debian this'd be:

``` bash

   sudo apt install podman
```

We'll take the baseline minimal Alpine Linux image, and build a custom local image, adding the required toolchain. For this we need a *Dockerfile*.

``` Dockerfile

   FROM docker.io/library/alpine

   # Python
   RUN apk add --no-cache python3 python3-dev

   # GNU Arm embedded toolchain
   #   gcc-arm-none-eabi      -> arm-none-eabi-gcc, arm-none-eabi-ar, libgcc
   #   binutils-arm-none-eabi -> pulled in as a dependency: arm-none-eabi-objcopy/-ld
   #   newlib-arm-none-eabi   -> bare-metal C library + headers (stdint.h, string.h)
   #   make                   -> 
   RUN apk add --no-cache \
           make \
           gcc-arm-none-eabi \
           newlib-arm-none-eabi \
           gdb-multiarch

   RUN apk add --no-cache py3-pyocd
   #<add PyOCD target support>

   WORKDIR /project
```

Create a new directory in your preferred location, call it `dev-env`. In that directory create a file name `Dockerfile` with the above content.

Now run:

``` bash

   podman build -t arm-toolchain .
```

This will build a local image named `arm-toolchain` with the toolchain as we required. Now we can invoke the following command in our workspace directory to drop into the container with the tools available to us.

``` bash

   podman run -it --rm -v "$PWD:/project" arm-toolchain
```

Then you can run `make --version` and `arm-none-eabi-gcc --version` to confirm they work. When you are finished with a development session simply run `exit` or press `CTRL-D`. You will need to run the command whenever you start development.

Make sure to set the appropriate [usb rules](/posts/usb-rules) so that the probe is accessible within the container!

