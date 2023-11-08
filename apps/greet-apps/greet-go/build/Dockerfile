FROM golang:1.20.11-alpine3.18 as builder
COPY ./main.go ./
RUN go build -o /go-app main.go

FROM alpine:3.18 as runtime
EXPOSE 8080
COPY --from=builder /go-app .
ENTRYPOINT ["./go-app"]
