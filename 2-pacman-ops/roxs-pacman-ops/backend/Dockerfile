# Backend Dockerfile for Pacman DevOps Challenge
FROM node:18-alpine

LABEL maintainer="RoxsRoss DevOps Challenge" \
      version="1.0.0" \
      description="Pacman DevOps Challenge Backend" \
      challenge="90DaysWithRoxs"

# Create app directory
WORKDIR /app

# Add non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S pacman -u 1001

# Copy package files for better layer caching
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application code
COPY . .

# Change ownership to nodejs user
RUN chown -R pacman:nodejs /app

# Switch to non-root user
USER pacman

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Start the application
CMD ["npm", "start"]
