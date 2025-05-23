#*********************************************************************
#   Copyright 2019 Regents of the University of California
#   All rights reserved
#*********************************************************************
# See https://itnext.io/docker-rails-puma-nginx-postgres-999cd8866b18

FROM public.ecr.aws/docker/library/ruby:3.2
RUN apt-get update -y -qq && apt-get install -y build-essential libpq-dev nodejs && apt-get -y upgrade

# Set an environment variable where the Rails app is installed to inside of Docker image
ENV RAILS_ROOT /var/www/app_name
RUN mkdir -p $RAILS_ROOT $RAILS_ROOT/log

# Set working directory
WORKDIR $RAILS_ROOT

# Setting env up
ENV RAILS_ENV='docker'
ENV RACK_ENV='docker'

# Adding gems
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

RUN gem install bundler
RUN bundle install 
RUN mkdir pid

# Adding project files
COPY . .
RUN bundle install 

# Build a discardable master.key and credentials.yml.enc file for docker deployment
RUN EDITOR=nano bundle exec rails credentials:edit

RUN SSM_SKIP_RESOLUTION=Y bundle exec rails assets:precompile && \
    bundle exec rails dev:cache
    
EXPOSE 3000 8086 1234

# https://serverfault.com/questions/683605/docker-container-time-timezone-will-not-reflect-changes
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# CA cert for LDAP SSL access
RUN mkdir /usr/local/share/ca-certificates/extra
COPY docker/ldap-ca.crt /usr/local/share/ca-certificates/extra/ldap-ca.crt
RUN /usr/sbin/update-ca-certificates

RUN echo Docker Build `date` > .version

CMD ["bundle", "exec", "puma", "-C", "config/application.rb", "-p", "8086"]
