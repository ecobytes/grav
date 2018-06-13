FROM nginx:1.14.0

# Desired version of grav
ARG GRAV_VERSION=1.4.5
ARG TINI_VERSION=0.18.0

# Install dependencies
RUN apt-get update && \
    apt-get install -y sudo wget vim unzip php php-curl php-gd php-pclzip php-fpm php-zip php-mbstring php-xml
ADD https://github.com/krallin/tini/releases/download/v$TINI_VERSION/tini /usr/local/bin/tini
RUN chmod +x /usr/local/bin/tini

# Set user to www-data
RUN mkdir -p /var/www && chown www-data:www-data /var/www
USER www-data

# Install grav
WORKDIR /var/www
RUN wget https://github.com/getgrav/grav/releases/download/$GRAV_VERSION/grav-admin-v$GRAV_VERSION.zip && \
    unzip grav-admin-v$GRAV_VERSION.zip && \
    rm grav-admin-v$GRAV_VERSION.zip && \
    cd grav-admin && \
    bin/gpm install -f -y admin

# Return to root user
USER root

# Configure nginx with grav
WORKDIR grav-admin
RUN cd webserver-configs && \
    sed -i 's/root \/home\/USER\/www\/html/root \/var\/www\/grav-admin/g' nginx.conf && \
    cp nginx.conf /etc/nginx/conf.d/default.conf

# Set the file permissions
RUN usermod -aG www-data nginx

# Run startup script
ADD resources /
CMD [ "/usr/local/bin/tini", "--", "/usr/local/bin/startup.sh" ]
