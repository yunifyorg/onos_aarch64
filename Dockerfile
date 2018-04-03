FROM arm64v8/debian

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates wget python maven git curl automake bison flex g++ git libboost-all-dev libevent-dev libssl-dev libtool make pkg-config thrift-compiler patch software-properties-common gnupg

RUN apt-get update && \
    add-apt-repository ppa:webupd8team/java -y && \
    apt-get update && \
    echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections && \
    apt-get install oracle-java8-installer oracle-java8-set-default -y --allow-unauthenticated

RUN apt-get install unzip && \
    git clone https://github.com/google/protobuf.git && \
    cd protobuf && \
    git checkout v3.2.0 && \
    git submodule update --init --recursive && \
    ./autogen.sh && \
    ./configure && \
    make && make check && make install && \
    export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH && \
    ldconfig && \
    mvn install:install-file -DgroupId=com.google.protobuf -DartifactId=protoc -Dversion=3.2.0 -Dclassifier=linux-aarch64 -Dfile=/protobuf/src/protoc -Dpackaging=exe

COPY grpc-java.v1.3.1.patch /

RUN cd / && git clone -b v1.3.1 https://github.com/grpc/grpc-java \
    && cd grpc-java \
    && ./gradlew \
    && patch -p1 < /grpc-java.v1.3.1.patch \
    && ./gradlew java_pluginExecutable \
    && mvn install:install-file -DgroupId=io.grpc -DartifactId=protoc-gen-grpc-java -Dversion=1.3.1 -Dclassifier=linux-aarch64 -Dpackaging=exe -Dfile=/grpc-java/compiler/build/exe/java_plugin/protoc-gen-grpc-java

RUN cd / && git clone https://gerrit.onosproject.org/onos

RUN mvn install:install-file -DgroupId=com.google.protobuf -DartifactId=protoc -Dversion=3.2.0 -Dclassifier=linux-aarch64 -Dfile=/protobuf/src/protoc -Dpackaging=zip

COPY onos.patch /

COPY protobuf_3.0.2/protoc /protobuf_3.0.2/protoc

RUN mvn install:install-file -DgroupId=com.google.protobuf -DartifactId=protoc -Dversion=3.0.2 -Dclassifier=linux-aarch64 -Dfile=/protobuf_3.0.2/protoc -Dpackaging=zip

RUN cd onos \
    && patch -p1 < /onos.patch \
    && sed -i 's/jar -xf/unzip/g' /onos/tools/test/bin/onos-stage-apps \
    && /onos/tools/build/onos-buck build onos --show-output
