FROM ekidd/rust-musl-builder:stable as builder

WORKDIR /home/rust
COPY src/* src/
COPY Cargo.toml .
RUN cargo build --release --target x86_64-unknown-linux-musl

FROM alpine:latest
WORKDIR /opt/server
COPY --from=builder /home/rust/target/x86_64-unknown-linux-musl/release/greet-rust . 
EXPOSE 8080
ENTRYPOINT [ "./greet-rust" ]