
ARG WORDPRESS_VERSION=6.4
ARG PHP_VERSION=8.3

# FROM wordpress:${WORDPRESS_VERSION}-php${PHP_VERSION}-apache

FROM wordpress:${WORDPRESS_VERSION}-php${PHP_VERSION}-apache

LABEL maintainer="lalifeier <lalifeier@gmail.com>"

# Environment variables
# ENV WOOCOMMERCE_VERSION 8.6.1
# ENV WOOCOMMERCE_PDF_INVOICES_VERSION 3.7.7
# ENV SEQUENCIAL_ORDER_NUMBERS_VERSION 1.6.0
ENV WORDPRESS_ROOT_PATH=/var/www/html
ENV WORDPRESS_PLUGINS_DIR=${WORDPRESS_ROOT_PATH}/wp-content/plugins
ENV WORDPRESS_THEMES_DIR=${WORDPRESS_ROOT_PATH}/wp-content/themes
ENV WORDPRESS_UPLOADS_DIR=${WORDPRESS_ROOT_PATH}/wp-content/uploads

# ARG UID=1000
# RUN groupmod -g ${UID} www-data
# RUN usermod -u ${UID} www-data


RUN mkdir "$WORDPRESS_UPLOADS_DIR" && chown -R www-data:www-data "${WORDPRESS_ROOT_PATH}"

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sudo \
    less \
    wget \
    unzip

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql

RUN pecl install xdebug && docker-php-ext-enable xdebug

# Install Composer
# RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Install WP CLI
RUN curl -sLo wp-cli.phar https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# # Install WooCommerce
# RUN wget -q https://downloads.wordpress.org/plugin/woocommerce.${WOOCOMMERCE_VERSION}.zip -O woocommerce.zip \
#     && unzip -q woocommerce.zip -d ${WORDPRESS_PLUGINS_DIR} \
#     && rm woocommerce.zip

# # Install WooCommerce PDF Invoices & Packing Slips
# RUN wget -q https://downloads.wordpress.org/plugin/woocommerce-pdf-invoices-packing-slips.${WOOCOMMERCE_PDF_INVOICES_VERSION}.zip -O woocommerce-pdf-invoices-packing-slips.zip \
#     && unzip -q woocommerce-pdf-invoices-packing-slips.zip -d ${WORDPRESS_PLUGINS_DIR} \
#     && rm woocommerce-pdf-invoices-packing-slips.zip

# # Install WT WooCommerce Sequential Order Numbers
# RUN wget -q https://downloads.wordpress.org/plugin/wt-woocommerce-sequential-order-numbers.${SEQUENCIAL_ORDER_NUMBERS_VERSION}.zip -O wt-woocommerce-sequential-order-numbers.zip \
#     && unzip -q wt-woocommerce-sequential-order-numbers.zip -d ${WORDPRESS_PLUGINS_DIR} \
#     && rm wt-woocommerce-sequential-order-numbers.zip

# Set stall script.
RUN curl -sLo /usr/local/bin/wait-for-it.sh https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh \
    && chmod +x /usr/local/bin/wait-for-it.sh

# ENV DOCKERIZE_VERSION v0.6.1
# RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
#     && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
#     && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Remove exec statement from base entrypoint script.
# RUN sed -i '$d' /usr/local/bin/docker-entrypoint.sh

# Set up Apache
RUN echo 'ServerName localhost' >> /etc/apache2/apache2.conf
# RUN a2enmod rewrite
# RUN service apache2 restart

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN  chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

CMD ["apache2-foreground"]

# USER www-data
