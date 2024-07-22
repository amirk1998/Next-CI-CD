# Use a specific version of Node.js for better reproducibility
FROM node:20.15-alpine AS base

# Install dependencies and tools
RUN apk add --no-cache g++ make py3-pip libc6-compat

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Expose port 3000
EXPOSE 3000

# Builder stage
FROM base AS builder

# Set working directory
WORKDIR /app

# Copy all files
COPY . .

# Install dependencies and build
RUN npm ci && npm run build

# Production stage
FROM base AS production

# Set working directory
WORKDIR /app

# Set Node environment to production
ENV NODE_ENV=production

# Install only production dependencies
RUN npm ci --only=production

# Create a non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
USER nextjs

# Copy built files and dependencies
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./package.json
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules

# Start the application
CMD ["npm", "start"]

# Development stage
FROM base AS dev

# Set Node environment to development
ENV NODE_ENV=development

# Install all dependencies
RUN npm install

# Copy all files
COPY . .

# Start the development server
CMD ["npm", "run", "dev"]