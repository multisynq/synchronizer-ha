ARG BUILD_FROM
FROM $BUILD_FROM

# Install Node.js and npm
RUN apk update && \
    apk add --no-cache nodejs npm

# Install synchronizer-cli globally
RUN npm install -g synchronizer-cli

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

# Set working directory
WORKDIR /data

# Labels
LABEL \
    io.hass.name="Multisynq Synchronizer" \
    io.hass.description="Run a Multisynq Synchronizer through your Home Assistant instance to participate in DePIN networks and earn rewards" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="Miguel Matos <miguel.matos@multisynq.io>"

CMD [ "/run.sh" ]