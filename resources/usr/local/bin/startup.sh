#!/bin/bash

set -e

function configure_userdata() {
    export GRAV_USERDATA=/var/www/grav-admin/user
    if [ ! "$(ls -A $GRAV_USERDATA)" ]; then
        echo "[ INFO ] Setting up Grav user data directory"
        cp -R $GRAV_USERDATA.src/* $GRAV_USERDATA/
    else
        echo "[ INFO ] Using existing Grav user data directory"
    fi
}

function configure_admin() {
    export GRAV_HOME=/var/www/grav-admin

    # Setup admin user (if supplied)
    if [ -z $ADMIN_USER ]; then
        echo "[ INFO ] No Grav admin user details supplied"
    else
        if [ -e $GRAV_HOME/user/accounts/$ADMIN_USER.yaml ]; then
            echo "[ INFO ] Grav admin user already exists"
        else
            echo "[ INFO ] Setting up Grav admin user"
            cd $GRAV_HOME
            sudo -u www-data bin/plugin login newuser \
                 --user=${ADMIN_USER} \
                 --password=${ADMIN_PASSWORD-"Pa55word"} \
                 --permissions=${ADMIN_PERMISSIONS-"b"} \
                 --email=${ADMIN_EMAIL-"admin@domain.com"} \
                 --fullname=${ADMIN_FULLNAME-"Administrator"} \
                 --title=${ADMIN_TITLE-"SiteAdministrator"}
        fi
    fi
}

function configure_nginx() {
    echo "[ INFO ] Configuring Nginx"

    echo "[ INFO ]  > Updating to listen on port 80"
    sed -i 's/#listen 80;/listen 80;/g' /etc/nginx/conf.d/default.conf

    if [ -z ${DOMAIN} ]; then
        echo "[ INFO ]  > No Domain supplied. Not updating server config"
    else
        echo "[ INFO ]  > Setting server_name to" ${DOMAIN} www.${DOMAIN}
        sed -i 's|php5-fpm|php/php7.0-fpm|g' /etc/nginx/conf.d/default.conf
        sed -i 's/server_name localhost/server_name '${DOMAIN}' 'www.${DOMAIN}'/g' /etc/nginx/conf.d/default.conf
    fi
}

function start_services() {
    echo "[ INFO ] Starting nginx"
    bash -c 'service php7.0-fpm start; nginx -g "daemon off;"'
}


function main() {
    configure_userdata
    configure_admin
    configure_nginx
    start_services
}


main "$@"
