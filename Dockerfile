FROM ruby:3.2.2
COPY . /pyxis
WORKDIR /pyxis
RUN bundle install
