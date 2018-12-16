#!/bin/bash

# We need to make sure that the app folder on the host machine is owned by
# "www-data:www-data", which seems to be, for both the "phpfpm" and
# "nginx-app" containers "33:33" ("$ id www-data" from both containers).
#
# http://stackoverflow.com/a/29251160/2141119
chown -R 33:33 ../
chmod -R g+rwx ../

# We need to pass the "-p" option (project) to avoid colliding with the volume names:
# docker-compose by default uses the folder its launched from as volume name for the
# project. "-p $(basename $(dirname $(pwd)))" corresponds to parent directory name.
docker-compose -p $(basename $(dirname $(pwd))) up -d --force-recreate

docker-compose -p $(basename $(dirname $(pwd))) exec phpfpm php artisan key:generate

# We cannot run the migration on the composer post-install hook because it would
# run from the "composer" container which isn't capable of running "artisan"
# (which basically has the same requirements as a Laravel application). We will
# delegate the "phpfpm" container using this script for now.
docker-compose -p $(basename $(dirname $(pwd))) exec phpfpm php artisan migrate --force

