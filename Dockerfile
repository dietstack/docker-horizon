FROM osmaster

MAINTAINER Kamil Madac (kamil.madac@t-systems.sk)

ENV http_proxy="http://172.27.10.114:3128"
ENV https_proxy="http://172.27.10.114:3128"

# Source codes to download
ENV horizon_repo="https://github.com/openstack/horizon"
ENV horizon_branch="stable/liberty"
ENV horizon_commit=""

# nginx is webserver and gettext is needed for horizon internationalization
RUN apt-get update; apt-get install -y nginx nginx-doc gettext && \
    rm /etc/nginx/sites-enabled/default && \
    pip install uwsgi

# some cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download horizon source codes
RUN git clone $horizon_repo --single-branch --branch $horizon_branch; 

# Checkout commit, if it was defined above
RUN if [ ! -z $horizon_commit ]; then cd horizon && git checkout $horizon_commit; fi

# Apply source code patches
RUN mkdir -p /patches
COPY patches/* /patches/
RUN /patches/patch.sh

# Install horizon with dependencies
RUN cd horizon; pip install -r requirements.txt; pip install supervisor mysql-python; python setup.py install

# prepare directories for supervisor
RUN mkdir -p /etc/supervisord /var/log/supervisord

# prepare necessary stuff
RUN rm /etc/nginx/sites-enabled/default; \
    mkdir -p /var/log/nginx/horizon && \
    useradd -M -s /sbin/nologin horizon && \
    usermod -G www-data horizon && \
    mkdir -p /run/uwsgi/ && chown horizon:horizon /run/uwsgi && chmod 775 /run/uwsgi

# copy horizon configs
COPY configs/horizon/* /etc/horizon/

# copy supervisor config
COPY configs/supervisord/supervisord.conf /etc

# copy uwsgi ini files
RUN mkdir -p /etc/uwsgi
COPY configs/uwsgi/horizon.ini /etc/uwsgi/horizon.ini

# prepare nginx configs
RUN sed -i '1idaemon off;' /etc/nginx/nginx.conf
COPY configs/nginx/horizon.conf /etc/nginx/sites-enabled/horizon.conf

# external volume
VOLUME /horizon-override

# copy startup scripts
COPY scripts /app

# Define workdir
WORKDIR /app
RUN chmod +x /app/*

#ENTRYPOINT ["/app/entrypoint.sh"]

# Define default command.
CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisord.conf"]

