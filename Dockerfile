FROM debian:9-slim AS builder
LABEL maintainer "mecab <mecab@misosi.ru>"

RUN apt-get update && \
    apt-get -y install curl git build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libboost-all-dev libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler libqrencode-dev && \
    apt-get -y install curl && \
    curl -L -o elicoin.tar.gz https://github.com/elicoin/elicoin/archive/1.0.tar.gz && \
    echo '1c959369bda5efe7dacfa0f448efa8a444527aac91a39ad4df23a5e271fea471  elicoin.tar.gz' | sha256sum -c && \
    tar zxvf elicoin.tar.gz && \
    cd elicoin-1.0 && \
    ELICOIN_ROOT=$(pwd) && \
    BDB_PREFIX="${ELICOIN_ROOT}/db4" && \
    mkdir -p $BDB_PREFIX && \
    curl -L -O 'http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz' && \
    echo '12edc0df75bf9abd7f82f821795bcee50f42cb2e5f76a6a281b85732798364ef  db-4.8.30.NC.tar.gz' | sha256sum -c && \
    tar -xzvf db-4.8.30.NC.tar.gz && \
    cd db-4.8.30.NC/build_unix/ && \
    ../dist/configure --enable-cxx --disable-shared --with-pic --prefix=$BDB_PREFIX && \
    make -j$(nproc) && \
    make install && \
    cd $ELICOIN_ROOT && \
    ./autogen.sh && \
    ./configure LDFLAGS="-L${BDB_PREFIX}/lib/" CPPFLAGS="-I${BDB_PREFIX}/include/" --disable-tests --prefix=/built && \
    make -j$(nproc) && \
    make install

FROM debian:9-slim
RUN apt-get -y update && \
    apt-get -y install git libssl-dev libevent-dev libboost-all-dev libqt5gui5 libqt5core5a libqt5dbus5 qttools5-dev libprotobuf-dev libqrencode-dev
COPY --from=builder /built /usr/local

ENTRYPOINT ["/usr/local/bin/elicoind"]
VOLUME ["/data"]
CMD ["-datadir=/data"]
EXPOSE 9332 9333
