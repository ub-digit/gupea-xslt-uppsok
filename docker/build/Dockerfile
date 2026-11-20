FROM ruby:3.3.14

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en

# timezone env with default
ENV TZ=Europe/Stockholm
# Set working directory in container
WORKDIR /usr/src/app/

COPY . ./

RUN bundle install --jobs 4 --retry 3

# Start the main process
CMD ["bundle", "exec", "puma", "-b", "0.0.0.0"]
