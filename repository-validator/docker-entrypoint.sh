#!/bin/bash
set -e

# Set proxy environment variables
[[ -n $PROXY ]] && export \
  http_proxy=$PROXY \
  https_proxy=$PROXY \
  HTTP_PROXY=$PROXY \
  HTTPS_PROXY=$PROXY

# Set default values (if not specified in docker-compose)
export ILI2C_MODEL_DIR="$ILI2C_INPUT_DIR;${ILI2C_VALIDATION_REPOSITORY:-http://models.interlis.ch/}"

# Download and configure ili2c
download_and_configure_ilitool () {
  ilitool=$1
  version=$2
  installDir=$3/$ilitool/$version
  echo -n "Download and configure $ilitool-$version ..."
  curl https://downloads.interlis.ch/$ilitool/$ilitool-$version.zip -LO --silent --show-error && \
    mkdir -p $installDir && unzip -o -q $ilitool-$version.zip -d $installDir && \
    rm $ilitool-$version.zip && \
    echo "done!" || exit 1
}

ILI2C_LATEST_VERSION=$(curl https://www.interlis.ch/downloads/ili2c --silent | grep -Po '(?<=ili2c-)\d+.\d+.\d+' | head -n 1)
export ILI2C_VERSION=${ILI2C_VERSION:-$ILI2C_LATEST_VERSION}
download_and_configure_ilitool ili2c $ILI2C_VERSION $ILITOOLS_HOME_DIR

# Use default user:group if no $PUID and/or $PGID is provided.
groupmod -o -g ${PUID:-941} abc && \
  usermod -o -u ${PGID:-941} abc &> /dev/null && \
  usermod -aG sudo abc && \
  echo "abc ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Change owner for our folders
echo -n "Set permissions for mounted volumes ..." && \
  chown -R abc:abc $ILI2C_INPUT_DIR && \
  chown -R abc:abc $ILI2C_OUTPUT_DIR && \
  chown -R abc:abc $ILITOOLS_HOME_DIR && \
  echo "done!"

# Export current environment for all users and cron jobs
echo -n "Configure environment ..." && \
  env | xargs -I {} echo 'export "{}"' > /etc/profile.d/env.sh && \
  env >> /etc/environment && echo "done!"


echo \
"--------------------------------------------------------------------------
ili2c version:                    $ILI2C_VERSION `[[ $ILI2C_VERSION != $ILI2C_LATEST_VERSION ]] && echo "(new version $ILI2C_LATEST_VERSION available!)"`
ili2c model repositories:         $ILI2C_MODEL_DIR
ili2c trace messages:             $([[ $ILI2C_ENABLE_TRACE = true ]] && echo enabled || echo disabled)
http proxy:                       ${PROXY:-no proxy set}
http proxy exceptions:            $([[ -n $NO_PROXY ]] && echo $NO_PROXY || echo undefined)
user uid:                         $(id -u abc)
user gid:                         $(id -g abc)
timezone:                         $TZ
--------------------------------------------------------------------------"

echo -e "INTERLIS repository validation has started.\n"
sudo -H --preserve-env --user abc check-repository
