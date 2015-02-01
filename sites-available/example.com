server
{
	listen           80;
	server_name      example.com;

	access_log       off;
	log_not_found    off;

	return           301 http://www.example.com;
}

server
{
	listen           80;
	server_name      www.example.com;

	root             /path/to/websites/example.com/www/;

	#access_log       /var/log/nginx/example.com.bots.log main flush=1m buffer=32k if=$isBot;
	#access_log       /var/log/nginx/example.com.access.log main flush=5m buffer=32k if=$isHuman;
	access_log       /var/log/nginx/example.com.bots.log advanced if=$isBot;
	access_log       /var/log/nginx/example.com.access.log advanced if=$isHuman;
	error_log        /var/log/nginx/example.com.errors.log warn;

	limit_req        zone=RPS010 burst=100 nodelay;
	limit_conn       CPIP 20;

	location @php
	{
		include       bootstrap/modules/php.conf;

        	limit_req     zone=RPS010 burst=20 nodelay;
        	limit_conn    CPIP 10;
	}

	location ~ ^.+\.php(?:/.*)?$
	{
		try_files     !noop! @php; 
	}

	include          bootstrap/modules/gzip.conf;
        include          bootstrap/locations/system.conf;
        include          bootstrap/locations/static.conf;

}

server
{
	listen           80;
	server_name      api.example.com;

	root             /path/to/websites/example.com/api/;

	include          bootstrap/modules/gzip.conf;
	include          bootstrap/locations/system.conf;
        include          bootstrap/locations/static.conf;
}
