FROM cdrakep/synqchronizer:latest

# Install bashio and dependencies for Home Assistant configuration handling
# First detect the base OS and install packages accordingly
RUN if command -v apk >/dev/null 2>&1; then \
        # Alpine Linux
        apk add --no-cache bash curl jq; \
    elif command -v apt-get >/dev/null 2>&1; then \
        # Debian/Ubuntu
        apt-get update && apt-get install -y bash curl jq && rm -rf /var/lib/apt/lists/*; \
    elif command -v yum >/dev/null 2>&1; then \
        # RHEL/CentOS
        yum install -y bash curl jq; \
    elif command -v dnf >/dev/null 2>&1; then \
        # Fedora
        dnf install -y bash curl jq; \
    else \
        echo "Package manager not found. Trying to continue without installing packages..."; \
    fi

# Download and install bashio for Home Assistant addon development
RUN if command -v curl >/dev/null 2>&1; then \
        curl -s -L https://github.com/hassio-addons/bashio/archive/v0.16.2.tar.gz | tar -xzC /tmp \
        && mv /tmp/bashio-0.16.2/lib /usr/lib/bashio \
        && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
        && rm -rf /tmp/bashio-0.16.2; \
    else \
        echo "curl not available, trying with wget..."; \
        if command -v wget >/dev/null 2>&1; then \
            wget -qO- https://github.com/hassio-addons/bashio/archive/v0.16.2.tar.gz | tar -xzC /tmp \
            && mv /tmp/bashio-0.16.2/lib /usr/lib/bashio \
            && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
            && rm -rf /tmp/bashio-0.16.2; \
        else \
            echo "Neither curl nor wget available, bashio installation skipped"; \
        fi; \
    fi

# Create with-contenv wrapper for bashio (Home Assistant compatibility)
RUN echo '#!/bin/bash' > /usr/bin/with-contenv && \
    echo 'shift' >> /usr/bin/with-contenv && \
    echo 'exec "$@"' >> /usr/bin/with-contenv && \
    chmod +x /usr/bin/with-contenv

# Copy the wrapper script that reads HA config and translates to command-line args
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Add Home Assistant labels
LABEL \
    io.hass.name="Multisynq Synchronizer" \
    io.hass.description="Run a Multisynq Synchronizer through your Home Assistant instance to participate in DePIN networks and earn rewards" \
    io.hass.type="addon" \
    io.hass.version="1.1.0" \
    maintainer="Miguel Matos <miguel.matos@multisynq.io>"

# Use our wrapper script which will call the base image's synchronizer with proper arguments
ENTRYPOINT ["/run.sh"]
CMD []
