FROM golang:1.12-alpine3.10
RUN apk add gcc libc-dev git
RUN mkdir -p $GOPATH/src/temperature-mapper
COPY . $GOPATH/src/temperature-mapper
ENV GO111MODULE=on GOPROXY=https://goproxy.cn
WORKDIR $GOPATH/src/temperature-mapper/temperature-mapper.
RUN go mod init && go mod tidy
WORKDIR $GOPATH
RUN CGO_ENABLED=1 go install $GOPATH/src/temperature-mapper/temperature-mapper
ENTRYPOINT ["temperature-mapper"]
