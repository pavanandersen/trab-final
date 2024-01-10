# Ansible Collection - postka.ansible_collection_lemp

Such collection creates LEMP stack with Wordpress inside.

Role Variables
--------------

| Name | Description | Default | Required |
|------|-------------|---------|:--------:|
| root_password | Password for root user in DB | `root` | no |
| db_name | Name of database which will be created | `db` | no |
| user_name | Username for database admin | `user` | no |
| user_pass | Password for database admin | `pass` | no |
| sites_path | Folder where sites files stored | `/var/www/http_host` | no |
| AUTH_KEY | WordPress security keys. Can be generated [here](https://api.wordpress.org/secret-key/1.1/salt/) | `random` | no |
| SECURE_AUTH_KEY | WordPress security keys. Can be generated [here](https://api.wordpress.org/secret-key/1.1/salt/) | `random` | no |
| LOGGED_IN_KEY | WordPress security keys. Can be generated [here](https://api.wordpress.org/secret-key/1.1/salt/) | `random` | no |
| LOGGED_IN_KEY | WordPress security keys. Can be generated [here](https://api.wordpress.org/secret-key/1.1/salt/) | `random` | no |
| NONCE_KEY | WordPress security keys. Can be generated [here](https://api.wordpress.org/secret-key/1.1/salt/) | `random` | no |
| AUTH_SALT | WordPress security keys. Can be generated [here](https://api.wordpress.org/secret-key/1.1/salt/) | `random` | no |
| SECURE_AUTH_SALT | WordPress security keys. Can be generated [here](https://api.wordpress.org/secret-key/1.1/salt/) | `random` | no |
| LOGGED_IN_SALT | WordPress security keys. Can be generated [here](https://api.wordpress.org/secret-key/1.1/salt/) | `random` | no |
| NONCE_SALT | WordPress security keys. Can be generated [here](https://api.wordpress.org/secret-key/1.1/salt/) | `random` | no |
| domain_name | Domain name which will be used in site configuration | `wp.com` | no |
| app_name | Name of wordpress application which will be used in folders naming | `wordpress` | no |
| php_fpm_sock | Path to PHP FPM socket | `/run/php/php-fpm.sock` | no |
| sites_path | Folder where sites files stored | `/var/www/http_host` | no |
| db_name | Name of database where wordpress data stored | `wordpress` | no |
| db_host | MySQL host where wordpress db located | `localhost` | no |
| db_username | Username for communication with MySQL DB | `wordpressuser` | no |
| db_password | Password for communication with MySQL DB | `wordpresspass` | no |

Example Playbook
----------------

Example of usage can be found in test folders inside collection.

License
-------

BSD-4-Clause
