FROM eclipse-temurin:11-jre-focal
ENV TZ=Europe/Zurich
ENV ILI2C_INPUT_DIR=/input
ENV ILI2C_OUTPUT_DIR=/output
ENV ILITOOLS_HOME_DIR=/ilitools
ENV HOME=/home/abc

RUN apt-get update && apt-get install unzip sudo

# Add non-root user and create our folders
RUN \
 useradd --uid 941 --user-group --home-dir $HOME --shell /bin/bash abc && \
 usermod --groups users abc && \
 mkdir -p \
   $ILI2C_INPUT_DIR \
   $ILI2C_OUTPUT_DIR \
   $ILITOOLS_HOME_DIR \
   $HOME

VOLUME $ILI2C_INPUT_DIR
VOLUME $ILI2C_OUTPUT_DIR

COPY docker-entrypoint.sh /entrypoint.sh
COPY ili2c-repository-check.sh /usr/local/bin/check-repository

ENTRYPOINT ["/entrypoint.sh"]
