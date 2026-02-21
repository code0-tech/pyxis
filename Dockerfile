FROM gcr.io/go-containerregistry/crane:v0.21.0 AS crane
FROM ruby:3.2.2 AS final
COPY --from=crane /ko-app/crane /ko-app/crane
ENV PATH=/ko-app:$PATH
COPY . /pyxis
WORKDIR /pyxis
RUN bundle install
