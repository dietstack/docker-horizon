FROM osmaster
MAINTAINER Kamil Madac (kamil.madac@t-systems.sk)

# Source codes to download
ENV srv_name=horizon
ENV repo="https://github.com/openstack/horizon" branch="stable/newton" commit="bd8b21b"

# nginx is webserver and gettext is needed for horizon internationalization
RUN apt-get update; apt-get install -y nginx nginx-doc gettext && \
    rm /etc/nginx/sites-enabled/default && \
    pip install uwsgi

# Download source codes
RUN if [ -n $commit ]; then \
       git clone $repo --single-branch --branch $branch; \
       cd $srv_name && git checkout $commit; \
    else \
       git clone $repo --single-branch --depth=1 --branch $branch; \
    fi

# Apply source code patches
RUN mkdir -p /patches
COPY patches/* /patches/
RUN /patches/patch.sh

# Install horizon with dependencies
RUN cd horizon; pip install -r requirements.txt -c /requirements/upper-constraints.txt; \
    pip install supervisor python-memcached; \
    python setup.py install

# prepare directories
RUN mkdir -p /etc/supervisord /var/log/supervisord

# copy horizon config file
COPY configs/horizon/local_settings.py /horizon/openstack_dashboard/local/local_settings.py
COPY themes/testlab/ /horizon/openstack_dashboard/themes/testlab/

# prepare necessary stuff
# http://docs.openstack.org/developer/horizon/topics/install.html
RUN rm /etc/nginx/sites-enabled/default; \
    mkdir -p /var/log/nginx/horizon && \
    useradd -M -s /sbin/nologin horizon && \
    usermod -G www-data horizon && \
    mkdir -p /run/uwsgi/ && chown horizon:horizon /run/uwsgi && chmod 775 /run/uwsgi; \
    chown -R horizon:www-data /horizon/openstack_dashboard/local; \
    chown -R horizon:www-data /horizon/openstack_dashboard/themes; \
    mkdir -p /horizon/static && chown -R horizon:horizon /horizon/static

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

# some cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*; \
    rm -rf /root/.cache/*

ENTRYPOINT ["/app/entrypoint.sh"]

# Define default command.
CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisord.conf"]

