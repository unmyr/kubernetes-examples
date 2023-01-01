FROM golang:1.19-alpine3.16 as builder
COPY ./main.go ./
RUN go build -o /go-app main.go

FROM alpine:3.16 as runtime
EXPOSE 8080
COPY --from=builder /go-app .
ENTRYPOINT ["./go-app"]
