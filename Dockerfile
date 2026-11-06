# Build environment for the sh-based static site generator.
#
# Build the image:
#   podman build -t myblog .
#
# Build the site (source mounted read-write at /site, output appears in ./public):
#   podman run --rm -v "$PWD:/site" myblog
#
# Publish to GitHub Pages (needs your host git identity + SSH key):
#   podman run --rm \
#       -v "$PWD:/site" \
#       -v "$HOME/.gitconfig:/root/.gitconfig:ro" \
#       -v "$HOME/.ssh:/root/.ssh:ro" \
#       -e GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new" \
#       myblog make publish
#
# The read-only ~/.gitconfig provides your commit identity
# (user.name/user.email) and, if configured, init.defaultBranch.
# The read-only ~/.ssh provides your private key and known_hosts for the
# git@github.com push. Ensure private keys are chmod 600; on SELinux hosts
# append :Z to the .ssh mount or pass --security-opt label=disable.
#
# Notes:
# - alpine ships neither `pandoc` nor `d2`, so both are installed from their
#   official statically linked releases.
# - `make` is required by the Makefile and by the d2 release's install target.
# - `git` (with `openssh-client`) is required by the publish target.

FROM alpine:3.21

ARG PANDOC_VERSION=3.13
ARG D2_VERSION=v0.9.0

RUN apk add --no-cache \
        make \
        git \
        curl \
        ca-certificates \
        tar \
        gzip \
        coreutils \
        openssh-client \
    && update-ca-certificates

# Install pandoc from the official statically linked release.
RUN set -eux; \
    case "$(apk --print-arch)" in \
        x86_64)  pandoc_arch=amd64 ;; \
        aarch64) pandoc_arch=arm64 ;; \
        *) echo "unsupported architecture: $(apk --print-arch)" >&2; exit 1 ;; \
    esac; \
    tarball="pandoc-${PANDOC_VERSION}-linux-${pandoc_arch}.tar.gz"; \
    curl -fsSL -o "/tmp/${tarball}" \
        "https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/${tarball}"; \
    tar -xzf "/tmp/${tarball}" --strip-components 1 -C /usr/local; \
    rm -f "/tmp/${tarball}"; \
    pandoc --version

# Install d2 from the official standalone release.
RUN set -eux; \
    case "$(apk --print-arch)" in \
        x86_64)  d2_arch=amd64 ;; \
        aarch64) d2_arch=arm64 ;; \
        *) echo "unsupported architecture: $(apk --print-arch)" >&2; exit 1 ;; \
    esac; \
    tarball="d2-${D2_VERSION}-linux-${d2_arch}.tar.gz"; \
    base="https://github.com/d2lang/d2/releases/download/${D2_VERSION}"; \
    curl -fsSL -o "/tmp/${tarball}" "${base}/${tarball}"; \
    if curl -fsSL -o /tmp/d2-SHA256SUMS "${base}/SHA256SUMS"; then \
        grep "${tarball}\$" /tmp/d2-SHA256SUMS > /tmp/d2-check.sha256; \
        (cd /tmp && sha256sum -c d2-check.sha256); \
    fi; \
    tar -xzf "/tmp/${tarball}" -C /tmp; \
    make -sC "/tmp/d2-${D2_VERSION}" install PREFIX=/usr/local; \
    rm -rf "/tmp/${tarball}" "/tmp/d2-${D2_VERSION}" \
        /tmp/d2-SHA256SUMS /tmp/d2-check.sha256; \
    d2 --version

WORKDIR /site

CMD ["make", "pages"]
