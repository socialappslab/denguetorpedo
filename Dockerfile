FROM ruby:2.3.0
MAINTAINER Cristhian Parra <cdparra@gmail.com>
ENV PROJECT_HOME /home/dengue
RUN apt-get update
RUN apt-get install -y sudo nodejs imagemagick
RUN mkdir -p ${PROJECT_HOME}
ADD deploy.sh deploy.sh
RUN chmod 777 deploy.sh

RUN mkdir ${PROJECT_HOME}/denguetorpedo
RUN mkdir ${PROJECT_HOME}/denguetorpedo/log
RUN touch ${PROJECT_HOME}/denguetorpedo/log/sidekiq.log
WORKDIR ${PROJECT_HOME}/denguetorpedo

RUN gem install rails:4.2.0 bundler:1.17.3 && sudo ln -s /usr/bin/convert /usr/local/bin/convert && gem install puma -v '2.11.2' --source 'http://rubygems.org/' -- --with-cppflags=-I/usr/local/opt/openssl/include

EXPOSE 3001
EXPOSE 5000
COPY . ${PROJECT_HOME}/denguetorpedo
WORKDIR ${PROJECT_HOME}/denguetorpedo
RUN bundle install
RUN rake assets:precompile
CMD bash deploy.sh
