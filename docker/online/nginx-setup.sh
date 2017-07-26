#!/bin/bash
LINENR=`grep -n "^;cgi\.fix_pathinfo=1" /etc/php5/fpm/php.ini | cut -f1 -d:`
REPLACED_LINE="cgi.fix_pathinfo=0"

sed -i "${LINENR}s:^.*$:${REPLACED_LINE}:g" /etc/php5/fpm/php.ini

DIR=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd`

echo "Configuring the nginx webserver"
if [ ! -f /etc/nginx/aspire ]; then
# BART        cp $DIR/nginx-default /etc/nginx/sites-available/default
        ln -s /usr/share/phpmyadmin /usr/share/nginx/www/phpmyadmin
        touch /etc/nginx/aspire
else
        echo "   already found a configured nginx server."
        echo "   If you want to force the default Aspire configuration, delete the /etc/nginx/aspire file."
fi

#BART
#if [ ! -f /etc/nginx/conf.d/aspire_ascl.conf ]; then
#        cp $DIR/aspire_ascl.conf /etc/nginx/conf.d/aspire_ascl.conf
#fi

#BART
sed --in-place -e 's/uid = aspire/uid = root/' /opt/ASCL/aspire-portal/aspire-portal.ini

chown -R $(whoami):$(id -g -n) /usr/share/nginx/www
/etc/init.d/php5-fpm reload
/etc/init.d/nginx restart

cd /opt/ASCL/aspire-portal
./stop-aspire-portal.sh
./start-aspire-portal.sh
