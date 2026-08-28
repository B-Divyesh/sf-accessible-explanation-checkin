FROM node:22-alpine AS frontend
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY frontend ./frontend
RUN npm run build

FROM rust:1.89-slim-bookworm AS backend
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml Cargo.lock ./
COPY src ./src
COPY migrations ./migrations
RUN cargo build --release --locked

FROM debian:bookworm-slim AS runtime
ARG BUILD_SHA=development
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/* \
    && groupadd --system checkin && useradd --system --gid checkin --home-dir /app checkin \
    && mkdir -p /app/data/uploads && chown -R checkin:checkin /app
WORKDIR /app
COPY --from=backend /app/target/release/accessible-explanation-checkin /app/server
COPY --from=frontend /app/dist /app/dist
USER checkin
ENV PORT=8080 DATABASE_URL=sqlite:/tmp/checkins.db?mode=rwc UPLOADS_DIR=/app/data/uploads PERSISTENCE_DIR=/app/data DIST_DIR=dist BUILD_SHA=${BUILD_SHA}
EXPOSE 8080
CMD ["/app/server"]
