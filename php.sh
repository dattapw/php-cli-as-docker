#!/usr/bin/env bash
# Run PHP from a Docker container (serversideup/php CLI) with common extensions.
set -euo pipefail

PHP_VERSION="${PHP_DOCKER_VERSION:-8.5}"
IMAGE="local/php-cli:${PHP_VERSION}"
EXTENSIONS="bcmath calendar exif gd gettext gmp imagick intl ldap mysqli soap sockets xsl apcu igbinary msgpack"

build_image() {
  echo "Building $IMAGE (one-time)..." >&2
  docker build --pull -t "$IMAGE" - >&2 <<EOF
FROM serversideup/php:${PHP_VERSION}-cli
USER root
RUN install-php-extensions ${EXTENSIONS}
USER www-data
EOF
}

# Build on first use, or when PHP_DOCKER_REBUILD is set
if [ -n "${PHP_DOCKER_REBUILD:-}" ] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  build_image
fi

# -t only when attached to a terminal, so pipes and redirects keep working
tty=(-i)
if [ -t 0 ] && [ -t 1 ]; then tty=(-it); fi

# $(basename "$0") lets you symlink this script as other tools, e.g. composer
# shellcheck disable=SC2086
exec docker run --rm "${tty[@]}" \
  --network host \
  -u "$(id -u):$(id -g)" \
  -e SHOW_WELCOME_MESSAGE=false \
  -v "$PWD:$PWD" -w "$PWD" \
  ${PHP_DOCKER_ARGS:-} \
  "$IMAGE" "$(basename "$0")" "$@"
