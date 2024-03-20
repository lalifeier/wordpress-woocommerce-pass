#!/bin/bash

# Wait for the db to be available
wait-for-it.sh ${WORDPRESS_DB_HOST}:${WORDPRESS_DB_PORT:-3306}
# dockerize -wait tcp://${WORDPRESS_DB_HOST}:${WORDPRESS_DB_PORT:-3306} -timeout 1m

# Make sure that the upstream entrypoint does not call exec
# TODO: Fix this in a pull request to docker-library/wordpress
sed -i '/exec "$@"/d' /usr/local/bin/docker-entrypoint.sh

# Run the entrypoint script form the wordpress image
# docker-entrypoint.sh "$@"
docker-entrypoint.sh 'apache2'

# Config WordPress
if [ ! -f "${WORDPRESS_ROOT_PATH}/wp-config.php" ]; then
    wp config create \
        --path="${WORDPRESS_ROOT_PATH}" \
        --dbname="${WORDPRESS_DB_NAME}" \
        --dbuser="${WORDPRESS_DB_USER}" \
        --dbpass="${WORDPRESS_DB_PASSWORD}" \
        --dbhost="${WORDPRESS_DB_HOST}" \
        --dbprefix="${WORDPRESS_TABLE_PREFIX}" \
        --skip-check \
        --quiet \
        --allow-root
fi

# wp config set WP_AUTO_UPDATE_CORE false --allow-root
# wp config set AUTOMATIC_UPDATER_DISABLED true --allow-root

# Install WP if not yet installed
if ! $( wp core is-installed --allow-root ); then
  wp core install \
    --path="${WORDPRESS_ROOT_PATH}" \
    --url=${WORDPRESS_URL:='localhost'} \
    --title=${WORDPRESS_TITLE:='Test'} \
    --admin_user=${WORDPRESS_ADMIN_USER:='lalifeier'} \
    --admin_password=${WORDPRESS_ADMIN_PASSWORD:='123456'} \
    --admin_email=${WORDPRESS_ADMIN_EMAIL:='lalifeier@gmail.com'} \
    --skip-email \
    --allow-root
fi

wp plugin list --allow-root

UNINSTALL_PLUGINS=("akismet" "hello")
# contact-form-7 "woocommerce-payments" "woocommerce-paypal-payments" "woocommerce-gateway-stripe" "woocommerce-product-price-based-on-countries" "woocommerce-google-analytics-integration"
INSTALL_PLUGINS=("woocommerce" "woocommerce-pdf-invoices-packing-slips" "elementor" "wordpress-seo" "wordfence" "updraftplus" "cloudflare")
# storefront botiga astra clotya
# https://themeforest.net/category/wordpress/ecommerce/woocommerce
INSTALL_THEME=botiga
UNINSTALL_THEMES=("twentytwentyone" "twentytwentytwo" "twentytwentythree" "twentytwentyfour")

for plugin in "${UNINSTALL_PLUGINS[@]}"; do
  if wp plugin is-installed "$plugin" --allow-root; then
    wp plugin uninstall "$plugin" --deactivate --allow-root
  fi
done

for plugin in "${INSTALL_PLUGINS[@]}"; do
  if ! wp plugin is-installed "$plugin" --allow-root; then
    wp plugin install "$plugin" --activate --force --allow-root
  fi
done

for theme in "${UNINSTALL_THEMES[@]}"; do
  wp theme delete "$theme" --allow-root
done

if [ "${INSTALL_THEME}" != '' ] && ! wp theme is-installed "${INSTALL_THEME}" --allow-root; then
  wp theme install "${INSTALL_THEME}" --activate --allow-root
fi

# wp plugin activate --all --allow-root

wp plugin list --allow-root

# wp post delete 1 --allow-root
wp post delete $(wp post list --post_type=post --format=ids --allow-root) --force --allow-root
# wp post delete $(wp post list --post_type=post --posts_per_page=1 --post_status=publish --postname="hello-world" --field=ID --format=ids) --force --allow-root

# Set pretty permalinks.
wp rewrite structure '/%year%/%monthnum%/%postname%/' --allow-root

echo "Running WordPress version: $(wp core version --allow-root) at $(wp option get home --allow-root)"

exec "$@"
