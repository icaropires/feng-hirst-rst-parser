FROM alpine as builder

RUN apk update && \
    apk add --no-cache build-base

COPY . /opt/feng-hirst-rst-parser

# The Feng's original README claims that liblbfgs is included, but it's not
WORKDIR /opt/feng-hirst-rst-parser/tools/crfsuite
RUN wget https://github.com/downloads/chokkan/liblbfgs/liblbfgs-1.10.tar.gz && \
    tar xvzf liblbfgs-1.10.tar.gz && \
    rm liblbfgs-1.10.tar.gz

WORKDIR /opt/feng-hirst-rst-parser/tools/crfsuite/liblbfgs-1.10
RUN ./configure --prefix=$HOME/local && \
    make clean && \
    make -j && \
    make install

WORKDIR /opt/feng-hirst-rst-parser/tools/crfsuite/crfsuite-0.12
# Can't put chmod and ./configure in the same layer (to avoid "is busy" error)
RUN chmod +x configure install-sh
RUN ./configure --prefix=$HOME/local --with-liblbfgs=$HOME/local && \
    make clean && \
    make -j && \
    make install && \
    ln -s /root/local/bin/crfsuite /opt/feng-hirst-rst-parser/tools/crfsuite/crfsuite-stdin && \
    chmod +x /opt/feng-hirst-rst-parser/tools/crfsuite/crfsuite-stdin


FROM alpine

RUN apk update && \
    apk add --no-cache py2-pip py2-setuptools openjdk8-jre-base perl && \
    pip install nltk==3.4

WORKDIR /opt/feng-hirst-rst-parser
COPY --from=builder /opt/feng-hirst-rst-parser .

WORKDIR /root/local
COPY --from=builder /root/local .

RUN apk del py2-pip && \
	rm -rf \
	/tmp/* \
	/var/cache/apk/*

WORKDIR /opt/feng-hirst-rst-parser/src
CMD ["/bin/sh"]
