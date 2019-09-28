FROM ruby:2.3.0
MAINTAINER Cristhian Parra <cdparra@gmail.com>
ENV PROJECT_HOME /home/dengue
RUN groupadd dengue
RUN useradd dengue -m -g dengue -s /bin/bash
RUN passwd -d -u dengue
RUN apt-get update
RUN apt-get install -y sudo nodejs
RUN apt-get install -y imagemagick
RUN echo "dengue ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dengue
RUN chmod 0440 /etc/sudoers.d/dengue
RUN mkdir -p ${PROJECT_HOME}
RUN chown dengue:dengue ${PROJECT_HOME}
RUN chown -R dengue:dengue ~/.gem
RUN chown -R dengue:dengue /usr/local/bundle
ADD deploy.sh deploy.sh
RUN chmod 777 deploy.sh
USER dengue
RUN mkdir ${PROJECT_HOME}/denguetorpedo
WORKDIR ${PROJECT_HOME}/denguetorpedo

RUN gem install rails -v 4.2.5
RUN gem install bundler:1.11.2
RUN sudo ln -s /usr/bin/convert /usr/local/bin/convert
RUN gem install puma -v '2.11.2' --source 'http://rubygems.org/' -- --with-cppflags=-I/usr/local/opt/openssl/include
EXPOSE 3001
EXPOSE 5000
COPY . ${PROJECT_HOME}/denguetorpedo
WORKDIR ${PROJECT_HOME}/denguetorpedo
RUN bundle install
CMD bash deploy.sh
