# Multi-stage Dockerfile for Node.js production image
# Stage 1: Install dependencies
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Stage 2: Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY src/ ./src/

# Stage 3: Production image (minimal)
FROM node:20-alpine AS runner
WORKDIR /app

# Security: run as non-root user
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY package.json ./

USER appuser

ARG NODE_ENV=production
ARG BUILD_DATE
ARG VCS_REF

ENV NODE_ENV=${NODE_ENV}

LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.source="https://iamdevbox.com/posts/setting-up-a-cicd-pipeline-to-kubernetes-with-github-actions/"

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

CMD ["node", "src/index.js"]
