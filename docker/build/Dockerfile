FROM alpine:latest AS release
ARG GIT_REVISION
ARG GIT_REPO_URL

RUN apk add --no-cache git

WORKDIR /root/

RUN set -ex \
  && git clone $GIT_REPO_URL release -b $GIT_REVISION --depth 1

FROM docker.ub.gu.se/sinatra:ruby-3.2.2

# Set working directory in container
WORKDIR /usr/src/app/

COPY --from=release /root/release /usr/src/app

RUN bundle install --jobs 4 --retry 3

# Start the main process
CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:3000"]
