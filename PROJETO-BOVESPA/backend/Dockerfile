# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY src/ ./src/

# Build (if needed)
# RUN npm run build

# Stage 2: Production
FROM node:18-alpine AS production

WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S appuser -u 1001 && \
    chown -R appuser:appuser /app

USER appuser

# Copy package files from builder
COPY --from=builder /app/package*.json ./

# Install production dependencies only
RUN npm install --only=production

# Copy source code
COPY --from=builder /app/src/ ./src/

# Create necessary directories
RUN mkdir -p /app/uploads /app/logs

# Expose port
EXPOSE 3001

# Start server
CMD ["node", "src/index.js"]