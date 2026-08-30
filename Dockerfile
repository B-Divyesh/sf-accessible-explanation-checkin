FROM node:22-alpine AS frontend
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY frontend ./frontend
RUN npm run build

FROM rust:1-slim-bookworm AS backend
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml Cargo.lock ./
COPY src ./src
COPY migrations ./migrations
COPY frontend/public/404.html frontend/public/404.html
RUN cargo build --release --locked

FROM debian:bookworm-slim AS runtime
ARG BUILD_SHA=development
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/* \
    && groupadd --system checkin && useradd --system --gid checkin --home-dir /app checkin \
    && mkdir -p /app /data/uploads && chown -R checkin:checkin /app /data
WORKDIR /app
COPY --from=backend /app/target/release/accessible-explanation-checkin /app/server
COPY --from=frontend /app/dist /app/dist
# The factory mounts the durable Azure Files share at /data. The server chooses
# /data itself when it exists, and otherwise falls back to ./data for local use.
USER checkin
ENV PORT=8080 BUILD_SHA=${BUILD_SHA}
EXPOSE 8080
CMD ["/app/server"]
