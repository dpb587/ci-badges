FROM alpine
RUN apk --no-cache add curl ca-certificates libxml2-utils py-pip \
  && pip install awscli
ADD bin /opt/badge/bin
ENV PATH="/opt/badge/bin:$PATH"
ENV badges_dir=/tmp/badges
