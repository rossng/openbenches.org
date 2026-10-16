# OpenBenches website (Symfony) served by Apache, for local development and testing.
# Build context is www/. See compose.yaml in the repository root.
FROM php:8.5-apache

COPY --from=mlocati/php-extension-installer:2.9.3 /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions mysqli pdo_mysql imagick exif intl zip @composer

RUN a2enmod rewrite \
 && printf '%s\n' \
      'upload_max_filesize = 20M' \
      'post_max_size = 80M' \
      'memory_limit = 512M' \
    > /usr/local/etc/php/conf.d/openbenches.ini

# Serve www/public directly. The repo's top-level .htaccess forces HTTPS, which we don't want locally.
ENV APACHE_DOCUMENT_ROOT=/var/www/openbenches/public
RUN printf '%s\n' \
      '<VirtualHost *:80>' \
      '  DocumentRoot ${APACHE_DOCUMENT_ROOT}' \
      '  <Directory /var/www/openbenches>' \
      '    AllowOverride None' \
      '  </Directory>' \
      '  <Directory ${APACHE_DOCUMENT_ROOT}>' \
      '    Require all granted' \
      '    FallbackResource /index.php' \
      '  </Directory>' \
      '</VirtualHost>' \
    > /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/openbenches
COPY composer.json composer.lock ./
RUN composer install --no-interaction --no-scripts --no-autoloader --prefer-dist
COPY . .
# Production's document root is www/, and some code builds paths as DOCUMENT_ROOT . "/public/...".
RUN composer dump-autoload --optimize \
 && ln -s . public/public \
 && mkdir -p var public/photos \
 && chown -R www-data:www-data var public/photos

# Photos are looked up relative to the working directory (public/ under Apache).
VOLUME /var/www/openbenches/public/photos
