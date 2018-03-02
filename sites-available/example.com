server
{
	listen 80;
	server_name example.com;

	access_log off;
	log_not_found off;

	return 301 http://www.example.com;
}

server
{
	listen 80 default_server;
	listen 443 ssl;
	server_name www.example.com;

	root /path/to/websites/example.com/www/;

	ssl_certificate /path/to/fullchain.pem;
	ssl_certificate_key /path/to/privatekey.pem;
	ssl_dhparam /path/to/dhparam.pem;

	access_log /var/log/nginx/example.com.access.log advanced flush=5m buffer=32k;
	error_log /var/log/nginx/example.com.errors.log warn;

	limit_req zone=RPS010 burst=100 nodelay;
	limit_conn CPIP 20;

	location @php
	{
		include bootstrap/modules/php.conf;

		limit_req zone=RPS010 burst=20 nodelay;
		limit_conn CPIP 10;
	}

	location /errors/
	{
		alias /path/to/websites/example.com/www/errors/;
		allow all;
	}

	error_page 403 /errors/403.html;
	error_page 404 /errors/404.html;
	error_page 500 /errors/500.html;

	include bootstrap/modules/ssl.conf;
	include bootstrap/modules/gzip.conf;
	include bootstrap/locations/system.conf;
	include bootstrap/locations/static.conf;
	include bootstrap/locations/errors.conf;
	include bootstrap/locations/php.conf;
}