FROM fluent/fluentd:latest
MAINTAINER Pascal Bernier <xbernpa@ville.montreal.qc.ca>
USER root
WORKDIR /home/fluent

RUN set -ex \
    && apk add --no-cache --virtual .build-deps \
        build-base \
        ruby-dev \
    && echo 'gem: --no-document' >> /etc/gemrc \
    && gem install fluent-plugin-secure-forward \
    && gem install fluent-plugin-record-reformer \
    && gem install fluent-plugin-gelf-hs \
    && gem install fluent-plugin-s3 \
    && gem install fluent-plugin-kubernetes_metadata_filter \
    && gem install fluent-plugin-detect-exceptions \
    && apk del .build-deps \
    && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem

# Copy configuration files
COPY ./conf/fluent.conf /fluentd/etc/
COPY ./conf/kubernetes.conf /fluentd/etc/

# Copy plugins
COPY plugins /fluentd/plugins/

# Environment variables
ENV FLUENTD_OPT=""
ENV FLUENTD_CONF="fluent.conf"

# jemalloc is memory optimization only available for td-agent
# td-agent is provided and QA'ed by treasuredata as rpm/deb/.. package
# -> td-agent (stable) vs fluentd (edge)
#ENV LD_PRELOAD="/usr/lib/libjemalloc.so.2"

# Customize entrypoint.sh (run as root)
COPY entrypoint.sh /bin/
RUN chmod +x /bin/entrypoint.sh

# Run Fluentd
CMD exec fluentd -c /fluentd/etc/$FLUENTD_CONF -p /fluentd/plugins $FLUENTD_OPT
