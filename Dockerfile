ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Node.js, npm, and required dependencies
RUN \
    apk add --no-cache \
        nodejs \
        npm \
        docker-cli \
        curl \
        bash \
        jq \
        openssl \
    && npm install -g synchronizer-cli@latest

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

# Create config directory with proper permissions
RUN mkdir -p /data/synchronizer-cli && \
    mkdir -p /data/.synchronizer-cli && \
    chmod 755 /data/synchronizer-cli /data/.synchronizer-cli

# Set working directory
WORKDIR /data

# Labels
LABEL \
    io.hass.name="Multisynq Synchronizer" \
    io.hass.description="Run a Multisynq Synchronizer through your Home Assistant instance to participate in DePIN networks and earn rewards" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="Miguel Matos <miguel.matos@multisynq.io>" \
    org.opencontainers.image.title="Multisynq Synchronizer" \
    org.opencontainers.image.description="Run a Multisynq Synchronizer through your Home Assistant instance to participate in DePIN networks and earn rewards" \
    org.opencontainers.image.source="https://github.com/multisynq/synchronizer-ha" \
    org.opencontainers.image.licenses="Apache-2.0"

CMD [ "/run.sh" ]