FROM debian:stretch-slim
MAINTAINER Kamil Madac (kamil.madac@gmail.com)

# Apply source code patches
RUN mkdir -p /patches
COPY patches/* /patches/

RUN echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf && \
    echo 'APT::Get::Install-Suggests "false";' >> /etc/apt/apt.conf && \
    apt update; apt install -y ca-certificates wget python libpython2.7 libxml2-dev nginx gettext netbase && \
    update-ca-certificates; \
    wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py; \
    python get-pip.py; \
    rm get-pip.py; \
    wget https://raw.githubusercontent.com/openstack/requirements/stable/pike/upper-constraints.txt -P /app && \
    /patches/stretch-crypto.sh && \
    apt-get clean && apt autoremove && \
    rm -rf /var/lib/apt/lists/*; rm -rf /root/.cache

# Source codes to download
ENV SVC_NAME=horizon SVC_VERSION=10.0.5
ENV REPO="https://github.com/openstack/horizon" BRANCH="stable/pike" COMMIT="39d863e"
#ENV RELEASE_URL=https://github.com/openstack/$SVC_NAME/archive/$SVC_VERSION.tar.gz

# Install nova with dependencies
ENV BUILD_PACKAGES="git build-essential libssl-dev libffi-dev python-dev"

RUN apt update; apt install -y $BUILD_PACKAGES && \
    if [ -z $REPO ]; then \
      echo "Sources fetching from releases $RELEASE_URL"; \
      wget $RELEASE_URL && tar xvfz $SVC_VERSION.tar.gz -C / && mv $(ls -1d $SVC_NAME*) $SVC_NAME && \
      cd /$SVC_NAME && pip install -r requirements.txt -c /app/upper-constraints.txt && PBR_VERSION=$SVC_VERSION python setup.py install; \
    else \
      if [ -n $COMMIT ]; then \
        cd /; git clone $REPO --single-branch --branch $BRANCH; \
        cd /$SVC_NAME && git checkout $COMMIT; \
      else \
        git clone $REPO --single-branch --depth=1 --branch $BRANCH; \
      fi; \
      cd /$SVC_NAME; pip install -r requirements.txt -c /app/upper-constraints.txt && python setup.py install && \
      rm -rf /$SVC_NAME/.git; \
    fi; \
    pip install supervisor uwsgi python-memcached && \
    apt remove -y --auto-remove $BUILD_PACKAGES &&  \
    apt-get clean && apt autoremove && \
    rm -rf /var/lib/apt/lists/* && rm -rf /root/.cache

# prepare directories
RUN mkdir -p /etc/supervisord /var/log/supervisord

# copy horizon config file
COPY configs/horizon/local_settings.py /horizon/openstack_dashboard/local/local_settings.py
COPY themes/ /horizon/openstack_dashboard/themes/
COPY files/logo-splash.png files/favicon.ico /horizon/openstack_dashboard/static/dashboard/img/

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

ENTRYPOINT ["/app/entrypoint.sh"]

# Define default command.
CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisord.conf"]
