FROM php:7.4-apache-buster

MAINTAINER Anthony Bretaudeau <anthony.bretaudeau@inrae.fr>

WORKDIR /var/www

RUN mkdir -p /usr/share/man/man1 /usr/share/man/man7

# Install packages and PHP-extensions
RUN apt-get -q update \
&& DEBIAN_FRONTEND=noninteractive apt-get -yq --no-install-recommends install \
    file libfreetype6 libjpeg62-turbo libpng16-16 libx11-6 libxpm4 gnupg \
    postgresql-client wget patch git unzip \
    python-setuptools cron libhwloc5 build-essential libzip4 libzip-dev \
    zlib1g dirmngr nano rsync libicu63 wish libssl-dev libldap2-dev libonig-dev \
 && BUILD_DEPS="libfreetype6-dev libjpeg62-turbo-dev libmcrypt-dev libpng-dev libxpm-dev zlib1g-dev python-dev libpq-dev libicu-dev libpq-dev" \
 && apt-get -yq --no-install-recommends install $BUILD_DEPS \
 && docker-php-ext-configure gd \
       --with-jpeg=/usr/lib/x86_64-linux-gnu \
       --with-xpm=/usr/lib/x86_64-linux-gnu --with-freetype=/usr/lib/x86_64-linux-gnu \
 && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
 && docker-php-ext-install mbstring pdo_mysql pgsql pdo_pgsql mysqli zip intl gd ldap \
 && echo "no" | pecl install apcu \
 && pecl install apcu_bc \
 && echo "extension=apcu.so" > $PHP_INI_DIR'/conf.d/apc_ext.ini' \
 && echo "extension=apc.so" > $PHP_INI_DIR'/conf.d/z_apc_ext.ini' \
 && echo "short_open_tag=0" > $PHP_INI_DIR'/conf.d/short_open_tag.ini' \
 && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
 && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $BUILD_DEPS \
 && rm -rf /var/lib/apt/lists/* \
 && a2enmod rewrite && a2enmod proxy && a2enmod proxy_http \
 && ln -s /usr/lib/x86_64-linux-gnu/libssl.so /usr/lib/x86_64-linux-gnu/libssl.so.10 \
 && ln -s /usr/lib/x86_64-linux-gnu/libcrypto.so /usr/lib/x86_64-linux-gnu/libcrypto.so.10 \
 && rm /etc/apache2/conf-enabled/serve-cgi-bin.conf

ENV TINI_VERSION v0.9.0
RUN set -x \
    && curl -fSL "https://github.com/krallin/tini/releases/download/$TINI_VERSION/tini" -o /usr/local/bin/tini \
    && chmod +x /usr/local/bin/tini

ENTRYPOINT ["/usr/local/bin/tini", "--"]


ENV ENABLE_OP_CACHE=1

ADD entrypoint.sh /
ADD /scripts/ /scripts/
ADD apache.conf /etc/apache2/sites-available/000-default.conf

CMD ["/entrypoint.sh"]
