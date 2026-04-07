# Stage 1: Build configuration
FROM nginx:1.27-alpine AS builder

COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Stage 2: Production image
FROM nginx:1.27-alpine

LABEL maintainer="juwondre"
LABEL org.opencontainers.image.source="https://github.com/juwondre/gitops"

# Remove default config
RUN rm -rf /etc/nginx/conf.d/*

# Copy custom config from builder
COPY --from=builder /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf

# Create non-root user and set permissions
RUN addgroup -S appgroup && adduser -S appuser -G appgroup \
    && chown -R appuser:appgroup /var/cache/nginx \
    && chown -R appuser:appgroup /var/log/nginx \
    && touch /var/run/nginx.pid \
    && chown -R appuser:appgroup /var/run/nginx.pid \
    && chmod -R 755 /var/cache/nginx

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
