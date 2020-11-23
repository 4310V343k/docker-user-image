# User Images
Base images that step down from root into a runtime-defined non-privileged user

[![BuyMeACoffee](https://img.shields.io/badge/buy%20me%20a%20coffee-donate-orange)](https://buymeacoff.ee/phasecorex)
[![PayPal](https://img.shields.io/badge/paypal-donate-blue)](https://paypal.me/pcx)

This repository is used as the template for building many of my `user-[IMAGE]` images. Currently we have the following images set up with multi-arch support:

- `alpine` [![Build Status](https://github.com/PhasecoreX/docker-user-image/workflows/build_alpine/badge.svg)](https://github.com/PhasecoreX/docker-user-image/actions?query=workflow%3Abuild_alpine) [![Docker Pulls](https://img.shields.io/docker/pulls/phasecorex/user-alpine)](https://hub.docker.com/r/phasecorex/user-alpine)
- `debian` [![Build Status](https://github.com/PhasecoreX/docker-user-image/workflows/build_debian/badge.svg)](https://github.com/PhasecoreX/docker-user-image/actions?query=workflow%3Abuild_debian) [![Docker Pulls](https://img.shields.io/docker/pulls/phasecorex/user-debian)](https://hub.docker.com/r/phasecorex/user-debian)
- `python` [![Build Status](https://github.com/PhasecoreX/docker-user-image/workflows/build_python/badge.svg)](https://github.com/PhasecoreX/docker-user-image/actions?query=workflow%3Abuild_python) [![Docker Pulls](https://img.shields.io/docker/pulls/phasecorex/user-python)](https://hub.docker.com/r/phasecorex/user-python)
- `ubuntu` [![Build Status](https://github.com/PhasecoreX/docker-user-image/workflows/build_ubuntu/badge.svg)](https://github.com/PhasecoreX/docker-user-image/actions?query=workflow%3Abuild_ubuntu) [![Docker Pulls](https://img.shields.io/docker/pulls/phasecorex/user-ubuntu)](https://hub.docker.com/r/phasecorex/user-ubuntu)

## For Developers
Simply have your image use this image as its base image:
```
FROM phasecorex/user-[IMAGE]
```
Replace `[IMAGE]` with any of the above supported image names. Extending an image is just like extending the library image they are based off of, except you get a few more features:
- UID/GID support: A user can specify `PUID` (and optionally `PGID`) to set the UID/GID your images `CMD` will run as. This also will make sure certain directories have proper permissions set on them, see Directories below.
- Timezone support: A user can specify `TZ` to set the containers timezone.
- Niceness support: A user can specify `NICENESS` to set the containers cpu niceness.

### Directories
There are two directories created for your program to use:
- `/config`: Useful to have your programs config files stored. The user can easily volume/bind mount this directory and modify config values.
- `/data`: Useful for your program to store databases or other persistence data. Again, the user can easily volume/bind mount this directory to save persistence.

These two directories will be chowned to the UID and GID the user selected via environment variables at start. If the image detects that the owner/group has been changed since last run, a full recursive chown will be performed instead. Your program will not need to worry about any permission errors with these directories.

### Multi-Arch
Pulling the base image will automatically pull the correct architecture for your build environment.

### Custom Entrypoints
This image uses an entrypoint script to do all of the setup at runtime. If your image utilizes an entrypoint script as well, you will need to prepend this images entrypoint (`user-entrypoint`) to it:
```
ENTRYPOINT ["user-entrypoint", "your", "other", "commands"]
```
If you've modified the `$PATH`, or otherwise can't run `user-entrypoint`, you can use `/bin/user-entrypoint` instead.

## For Users
If you're a developer using this image, consider including this information in your images readme.

### UID/GID
Set the environment variable `PUID` as the user ID you want the container to run as.
You can also set the environment variable `PGID` to specify the group ID. It will default to the user ID.

For example:
```
docker run -it -e PUID=1000 phasecorex/user-[IMAGE]
docker run -it -e PUID=1000 -e PGID=1024 phasecorex/user-[IMAGE]
docker run -it -e PUID=0 phasecorex/user-[IMAGE]
```
If not supplied, the default `PUID` and `PGID` will be 1000.

If set manually to 0, the process will run as root.

### Timezone
You can also set a timezone that your process will run in. Simply define the `TZ` environment variable:
```
docker run -it -e TZ=America/Detroit -e PUID=1000 phasecorex/user-[IMAGE]
```
This helps with having correct times in process logs.

### Niceness
By default, the process will run at the niceness that Docker itself is running at (usually zero). If you would like to change that, simply define the `NICENESS` environment variable:
```
docker run -it -e TZ=America/Detroit -e PUID=1000 -e NICENESS=10 phasecorex/user-[IMAGE]
docker run -it -e TZ=America/Detroit -e PUID=1000 -e NICENESS=-10 --cap-add=SYS_NICE phasecorex/user-[IMAGE]
```
Niceness has a range of -20 (highest priority, least nice to other processes) to 19 (lowest priority, very nice to other processes). Setting this to a value less than the default (higher priority) will require that you start the container with `--cap-add=SYS_NICE`. Setting it above the default will not need that capability set.

