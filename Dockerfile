# Dockerfile to create a TimescaleDB image with pgTAP installed

# pulling the base image
FROM timescale/timescaledb-ha:pg15

# switch to root user to install packages
USER root

# install dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    make \
    perl \
    cpanminus \
    postgresql-server-dev-15 \
    wget \
    patch \
    build-essential

# install TAP::Parser::SourceHandler::pgTAP Perl module
RUN cpanm --notest TAP::Parser::SourceHandler::pgTAP

# clone, build, and install pgTAP
RUN git clone https://github.com/theory/pgtap.git /tmp/pgtap && \
    cd /tmp/pgtap && \
    make && \
    make install && \
    rm -rf /tmp/pgtap

# clean up apt cache to reduce image size
RUN rm -rf /var/lib/apt/lists/*

# switch back to postgres user
USER postgres