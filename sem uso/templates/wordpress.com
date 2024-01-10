server {
    listen 80;
    server_name wordpress.com;

    root /var/www/html/wordpress.com;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires max;
        log_not_found off;
    }

    access_log /var/log/nginx/wordpress.com_access.log;
    error_log /var/log/nginx/wordpress.com_error.log;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-available/*;
}