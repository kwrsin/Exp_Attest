FROM ruby:2.7.2-alpine
WORKDIR /code
# REF: https://stackoverflow.com/questions/49157957/installing-gems-with-native-extension-on-docker-image
# REF: https://danbruder.com/blog/what-is-the-alpine-equivalent-to-build-essential/
# REF: https://stackoverflow.com/questions/59477399/warning-the-lockfile-is-being-updated-to-bundler-2-after-which-you-will-be-una
RUN mkdir ../store
RUN apk update \
    && apk --no-cache --update add build-base
RUN gem install bundler:1.17.2
COPY ./Gemfile* ./
RUN bundle install
EXPOSE 4567
COPY . .
CMD ["bundle", "exec", "ruby", "main.rb"]