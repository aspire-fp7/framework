#!/bin/bash

echo 'mysql-server mysql-server/root_password password aspire' | debconf-set-selections
echo 'mysql-server mysql-server/root_password_again password aspire' | debconf-set-selections

echo 'phpmyadmin phpmyadmin/dbconfig-install boolean false' | debconf-set-selections
echo 'phpmyadmin phpmyadmin/app-password-confirm password aspire' | debconf-set-selections
echo 'phpmyadmin phpmyadmin/mysql/admin-pass password aspire' | debconf-set-selections
echo 'phpmyadmin phpmyadmin/mysql/app-pass password aspire' | debconf-set-selections
echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections
