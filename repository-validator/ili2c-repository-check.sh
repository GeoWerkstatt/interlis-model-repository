#!/bin/bash
set -e

proxy_port=$(echo $PROXY | grep -Eo '[0-9]+' | tail -1)
proxy_host=${PROXY%":$(echo ${PROXY##*:})"} # remove port
proxy_host=${proxy_host#*://} # remove protocol

[[ -n $ILI2C_MODEL_DIR ]] && options+=" --modeldir $ILI2C_MODEL_DIR"
[[ -n $proxy_host ]] && options+=" --proxy $proxy_host"
[[ -n $proxy_port ]] && options+=" --proxyPort $proxy_port"
[[ $ILI2C_ENABLE_TRACE = true ]] && options+=" --trace"

# Print executed commands to the Docker container log output
exec {BASH_XTRACEFD}> >(sudo tee /proc/1/fd/2)

# Execute ili2c with the given options
$JAVA_HOME/bin/java -jar $ILITOOLS_HOME_DIR/ili2c/$ILI2C_VERSION/ili2c.jar $options --check-repo-ilis $ILI2C_INPUT_DIR

if [ $? -eq 0 ]
then
    echo "Repository validated sucessfully. Copying contents of '$ILI2C_INPUT_DIR' to '$ILI2C_OUTPUT_DIR'..."
    rm -r $ILI2C_OUTPUT_DIR/* && cp -r $ILI2C_INPUT_DIR/* $ILI2C_OUTPUT_DIR
    echo Validated: $(date +"%H:%M %d.%m.%Y") > $ILI2C_OUTPUT_DIR/Version.md
    exit 0
else
    echo "Repository validation resulted in errors. Check logs above"
    exit 1
fi
