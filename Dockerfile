# Use official Node image
FROM node:20-bullseye

# Install yt-dlp (Python package)
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-pip && \
    pip3 install yt-dlp && \
    rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /app

# Install production dependencies exactly as locked
COPY package*.json ./
RUN npm ci --omit=dev

# Copy the rest of the app (node_modules is excluded by .dockerignore)
COPY . .

# Run as the image's unprivileged "node" user. It needs to own /app/tmp,
# where yt-dlp writes the downloaded audio.
RUN mkdir -p /app/tmp && chown node:node /app/tmp
USER node

# The hosting platform may pass PORT; default to 4000 for local consistency
ENV PORT=4000

# Any HTTP response means the server is up (there is no dedicated health route)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -s -o /dev/null "http://127.0.0.1:${PORT}/" || exit 1

# Start the server
CMD ["npm", "start"]
