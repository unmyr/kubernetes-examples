# https://hub.docker.com/_/rust/
FROM rust:1.76 as builder

WORKDIR /usr/src/myapp
COPY src/* src/
COPY Cargo.toml .
RUN cargo build --release

# https://hub.docker.com/_/debian
FROM debian:12.5-slim
WORKDIR /opt/server
COPY --from=builder /usr/src/myapp/target/release/greet-rust .
EXPOSE 8080
ENTRYPOINT [ "/opt/server/greet-rust" ]
