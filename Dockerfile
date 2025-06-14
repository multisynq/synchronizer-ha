ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Node.js, npm, and required dependencies including debugging tools
RUN apk add --no-cache \
        curl \
        bash \
        jq \
        openssl \
        ca-certificates \
        git \
        python3 \
        make \
        g++ \
        docker-cli \
        strace \
        gdb \
        file \
        binutils \
        util-linux

# Add debugging environment variables
ENV DEBUG_MODE=false \
    SEGFAULT_DEBUG=true \
    NODE_DEBUG_NATIVE=1

# Install a compatible Node.js version (v18 LTS) with architecture detection
RUN ARCH=$(uname -m) && \
    echo "Detected architecture: $ARCH" && \
    case "$ARCH" in \
        x86_64) NODE_ARCH="x64" ;; \
        aarch64) NODE_ARCH="arm64" ;; \
        armv7l) NODE_ARCH="armv7l" ;; \
        *) echo "Unsupported architecture: $ARCH, falling back to system Node.js"; apk add --no-cache nodejs npm; exit 0 ;; \
    esac && \
    echo "Installing Node.js for architecture: $NODE_ARCH" && \
    curl -fsSL "https://unofficial-builds.nodejs.org/download/release/v18.20.4/node-v18.20.4-linux-$NODE_ARCH-musl.tar.xz" | tar -xJ -C /usr/local --strip-components=1 || \
    (echo "Failed to install Node.js v18, using system version..." && \
     apk add --no-cache nodejs npm)

# Verify Node.js version
RUN echo "Node.js version: $(node --version)" && \
    echo "NPM version: $(npm --version)" && \
    node -e "const version = process.version.slice(1).split('.'); if (parseInt(version[0]) < 10) { console.error('Node.js version too old:', process.version); process.exit(1); } else { console.log('Node.js version OK:', process.version); }"

# Set npm environment variables instead of using npm config
ENV NPM_CONFIG_UNSAFE_PERM=true \
    NPM_CONFIG_FUND=false \
    NPM_CONFIG_AUDIT=false \
    NPM_CONFIG_REGISTRY=https://registry.npmjs.org/ \
    NPM_CONFIG_TIMEOUT=300000 \
    NPM_CONFIG_CACHE=/tmp/.npm

# Create npm cache directory and install synchronizer-cli
RUN mkdir -p /tmp/.npm && \
    chmod 777 /tmp/.npm && \
    npm install -g synchronizer-cli@latest --verbose --no-optional || \
    (echo "NPM install failed, trying alternative approach..." && \
     mkdir -p /usr/lib/node_modules/synchronizer-cli && \
     curl -L https://registry.npmjs.org/synchronizer-cli/-/synchronizer-cli-2.2.12.tgz | tar -xz -C /usr/lib/node_modules/synchronizer-cli --strip-components=1 && \
     ln -sf /usr/lib/node_modules/synchronizer-cli/index.js /usr/bin/synchronize && \
     chmod +x /usr/bin/synchronize /usr/lib/node_modules/synchronizer-cli/index.js)

# Clean up npm cache
RUN npm cache clean --force || rm -rf /tmp/.npm || true

# Verify installation with comprehensive debugging
RUN echo "=== Comprehensive Installation Verification ===" && \
    echo "Build architecture: ${BUILD_ARCH}" && \
    echo "System architecture: $(uname -m)" && \
    echo "Node.js version: $(node --version)" && \
    echo "NPM version: $(npm --version)" && \
    echo "Node.js binary details:" && \
    file $(which node) && \
    echo "Node.js binary libraries:" && \
    (ldd $(which node) 2>/dev/null || readelf -d $(which node) 2>/dev/null | head -10 || echo "Binary analysis not available") && \
    echo "Checking synchronize command..." && \
    (which synchronize && echo "✓ synchronize found in PATH at: $(which synchronize)") || echo "✗ synchronize not in PATH" && \
    (ls -la /usr/bin/synchronize && echo "✓ synchronize binary exists") || echo "✗ synchronize binary missing" && \
    (test -f /usr/bin/synchronize && file /usr/bin/synchronize) || echo "✗ cannot analyze synchronize binary" && \
    (ls -la /usr/lib/node_modules/synchronizer-cli/ && echo "✓ synchronizer-cli module exists") || echo "✗ synchronizer-cli module missing" && \
    (test -f /usr/lib/node_modules/synchronizer-cli/package.json && echo "✓ package.json found:" && cat /usr/lib/node_modules/synchronizer-cli/package.json | jq -r '.name, .version, .bin') || echo "✗ package.json missing or invalid" && \
    echo "Testing basic Node.js functionality..." && \
    node -e "console.log('Node.js test: SUCCESS'); console.log('Platform:', process.platform); console.log('Arch:', process.arch);" && \
    echo "=== End Comprehensive Verification ==="

# Copy run and debug scripts
COPY run.sh /
COPY debug.sh /
RUN chmod a+x /run.sh /debug.sh

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