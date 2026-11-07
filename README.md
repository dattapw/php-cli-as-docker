# PHP CLI as Docker

Run php and composer on your Linux machine without installing PHP. Both commands are thin wrappers that run inside a Docker container built on serversideup/php (CLI variation), with a set of common PHP extensions added.

It behaves like a native install: your current directory is available inside the container, files PHP creates are owned by you, localhost services are reachable, and pipes, scripts and #!/usr/bin/env php shebangs work.

## Requirements

- Linux
- [Docker](https://docs.docker.com/engine/install/), usable by your user (member of the `docker` group, or rootless Docker)
- `curl` or `wget` (installer only)


## Install

```bash
curl -fsSL https://raw.githubusercontent.com/dattapw/php-cli-as-docker/main/install.sh | sh
```

The installer:

1. Downloads `php.sh` from this repo and installs it as `~/.local/bin/php`.
2. Symlinks `~/.local/bin/composer` to it.
3. Adds `~/.local/bin` to your `PATH` if it isn't there already. It detects your login shell and edits the matching rc file (`~/.bashrc`, `~/.zshrc`, `~/.config/fish/config.fish`, `~/.kshrc`, or `~/.profile` as a fallback).
Open a new terminal (or `source` the rc file it prints) and run `php -v`.
 
The first run builds the local image, which takes a minute or two. After that, startup is instant.


## Usage
 
Use `php` and `composer` as you normally would:
 
```bash
php script.php
php -r 'echo PHP_VERSION, PHP_EOL;'
php -S 127.0.0.1:8000          # dev server, reachable from your browser
```
 
### Configuration
 
Configure the wrapper with environment variables:
 
| Variable | Default | Description |
|---|---|---|
| `PHP_DOCKER_VERSION` | `8.5` | PHP version to use. Each version gets its own image (`local/php-cli:<version>`). |
| `PHP_DOCKER_REBUILD` | unset | Set to any value to rebuild the image, pulling the latest base image. |
| `PHP_DOCKER_ARGS` | unset | Extra arguments passed to `docker run`. |
 
```bash
PHP_DOCKER_VERSION=8.4 php -v                       # use PHP 8.4
PHP_DOCKER_REBUILD=1 php -v                         # refresh the image
PHP_DOCKER_ARGS="-v /data:/data" php /data/job.php  # mount extra paths
PHP_DOCKER_ARGS="-e PHP_MEMORY_LIMIT=512M" php heavy.php
```
 
The base image can be tuned with any of its [environment variables](https://serversideup.net/open-source/docker-php/docs/reference/environment-variable-specification) (for example `PHP_MEMORY_LIMIT` or `PHP_DATE_TIMEZONE`) by passing them with `-e` through `PHP_DOCKER_ARGS`.


## Included extensions

From the base image:

- **Added by serversideup/php:** `opcache`, `pcntl`, `pdo_mysql`, `pdo_pgsql`, `redis`, `zip`
- **Part of the official PHP image:** `ctype`, `curl`, `dom`, `fileinfo`, `filter`, `hash`, `mbstring`, `openssl`, `pcre`, `session`, `tokenizer`, `xml`, and others
Added by this project:

`bcmath`, `calendar`, `exif`, `gd`, `gettext`, `gmp`, `imagick`, `intl`, `ldap`, `mysqli`, `soap`, `sockets`, `xsl`, `apcu`, `igbinary`, `msgpack`

Run `php -m` to see what is loaded.

`xdebug` is intentionally not included because it slows down every run. To add it or anything else, see below.


## Limitations

- **Only the current directory (and below) is visible** to PHP.
- **`--network host` is Linux-only** and gives the container your host network. Remove it from the script if you want isolation, and add `-p` mappings yourself.
- Commands that must run as root or install system packages aren't supported by this wrapper.


## Uninstall

```bash
rm ~/.local/bin/php ~/.local/bin/composer
docker rmi local/php-cli:8.5
```

The installer may also have added a line marked `# Added by the php docker installer` to your shell rc file; delete it if you don't want `~/.local/bin` on your `PATH`.


## Troubleshooting

**`permission denied` connecting to the Docker daemon.** Add your user to the `docker` group (`sudo usermod -aG docker $USER`, then log out and back in) or use rootless Docker.

**The image build fails on an extension.** Remove that extension from `EXTENSIONS` and rebuild, or pin an older PHP version with `PHP_DOCKER_VERSION`.

**`php: command not found` after installing.** Open a new terminal or `source` your shell's rc file, and check that `~/.local/bin` is in `echo $PATH`.

**Files in a mounted directory can't be written.** The container runs as your user, so the directory must be writable by you on the host.


## Credits

Built on the [serversideup/php](https://github.com/serversideup/docker-php) images and [docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer).
