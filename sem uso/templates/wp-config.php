<?php
/**
 * Arquivo de configuração do WordPress para Ansible
 */

define('DB_NAME', '{{ db_name }}');
define('DB_USER', '{{ db_user }}');
define('DB_PASSWORD', '{{ db_password }}');
define('DB_HOST', '{{ db_host }}');
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', '');

$table_prefix = 'wp_';

define('WP_DEBUG', false);
define('WP_ALLOW_REPAIR', false);

define('WP_HOME', 'http://{{ ansible_ssh_host }}');
define('WP_SITEURL', 'http://{{ ansible_ssh_host }}/wordpress');
/**
*define('AUTH_KEY',         'coloque sua chave aqui');
*define('SECURE_AUTH_KEY',  'coloque sua chave aqui');
*define('LOGGED_IN_KEY',    'coloque sua chave aqui');
*define('NONCE_KEY',        'coloque sua chave aqui');
*define('AUTH_SALT',        'coloque sua chave aqui');
*define('SECURE_AUTH_SALT', 'coloque sua chave aqui');
*define('LOGGED_IN_SALT',   'coloque sua chave aqui');
*define('NONCE_SALT',       'coloque sua chave aqui');
*/
if ( !defined('ABSPATH') )
  define('ABSPATH', dirname(__FILE__) . '/');

require_once(ABSPATH . 'wp-settings.php');
