## A docker-compose configuration to set up a ready-to-use Laravel environment.
- PHP 7.3, Xdebug, Composer
- MySQL 8.0
- Nginx

### Usage
- Clone the repository inside your project root: `git clone <url> .docker`
- Remove from your .env file the following variables:
    - DB_CONNECTION
    - DB_HOST
    - DB_PORT
    - DB_DATABASE
    - DB_USERNAME
    - DB_PASSWORD
- Optional: Update the VIRTUAL_HOST value in `.docker/.env`
- From within the .docker folder, run `docker-compose -p $(basename $(dirname $(pwd))) up -d`
    
You should be able to view your Laravel project at http://website.localhost or
at http://$VIRTUAL_HOST

##### Note about docker-compose -p <project-name>
To avoid volume collision always remember to pass in a unique project name when
running docker-compose. I am currently using the parent folder name as project
name. Given this folder structure: `.../my-project/.docker`, running
`docker-compose -p $(basename $(dirname $(pwd)))` from within the `.docker`
folder will use `my-project` as project name.

Add this function to your bash profile or .zshenv to be able to use `dcp` as a
shortcut: 
```bash
function dcp() {
    docker-compose -p $(basename $(dirname $(pwd))) $@
}
```
This will set the --project-name argument for you.

### 1. Reverse proxy and running multiple applications
As of right now it's not possible to run multiple Laravel applications at the
same time. This is because both the nginx-proxy and database services publish
hard coded ports. I don't currently see this as a deal-breaker and could be
fixed by running nginx-proxy either externally or with a different port and by
setting a custom port for the database service on a per-project basis.

### 2. HTTPS
To enable HTTPS you simply need to:
- Generate a .key and .crt file into the .docker/images/nginx-proxy/certs folder
  by running the following command from the docker folder. The variable
  VIRTUAL_HOST must be the same to the one you set in the .docker/.env file.
```
VIRTUAL_HOST=website.localhost bash -c 'openssl req -new -x509 -nodes -sha256 -days 365 -newkey rsa:2048 -keyout images/nginx-proxy/certs/$VIRTUAL_HOST.key -out images/nginx-proxy/certs/$VIRTUAL_HOST.crt -subj "/C=US/ST=Oregon/L=Portland/O=Localhost/OU=Development/CN=$VIRTUAL_HOST"'
```
- Update the nginx-proxy service to expose port 443:
```yml
  3 services:
  4   nginx-proxy:
  ...
  6     ports:
  7       - 80:80
+ 8       - 443:443
```
- If present, update your Trusted Proxy configuration to trust the caller IP
```php
// app/Http/Middleware/TrustProxies.php
-  15     protected $proxies;
+  15     protected $proxies = '*';
```
Your browser will complain about your self-signed SSL certificate. 

### 3. Xdebug
Xdebug is installed and enabled by default and uses port 9000. You just need to
configure your IDE.

For PHPStorm, all you need to do is:
- Install the Browser extension: https://www.jetbrains.com/help/phpstorm/browser-debugging-extensions.html
- Start listening, from the Menu: Run > Start Listening for PHP Debug Connections 

### 4. Node (NPM, Yarn)
You'll probably need npm/yarn, I'm currently using the "serafinomb/node"
docker image. Usage is as follows:
- `docker run -it --rm -v $(PWD):/ws:delegated -w /ws serafinomb/node node -v`
- `docker run -it --rm -v $(PWD):/ws:delegated -w /ws serafinomb/node npm -v`
- `docker run -it --rm -v $(PWD):/ws:delegated -w /ws serafinomb/node yarn -v`

You can add an alias or function to your bash profile/.zshenv for each one of
them. For example:
```bash
function node() {
    docker run -it --rm -e "TERM=xterm-256color" -v $(PWD):/ws:delegated -w /ws serafinomb/node node $@
}

function npm() {
    node npm $@
}

function npx() {
    node npx $@
}

function yarn() {
    node yarn $@
}
```

And if you need to run "npm run start" consider using the following command which should have better performances:
```bash
docker run -it --rm -v $PWD:/ws:delegated,ro -v $PWD/node_modules -w /ws -p 3000:3000 -e CHOKIDAR_USEPOLLING=true -e CHOKIDAR_INTERVAL=250 serafinomb/node npm run start

```

### 5. Database tunneling
If you are working with a remote database, example Amazon RDS, and you need to
establish a tunnel connection to connect to it:

- Copy your PEM certificate into `<project-dir>/app/storage`
- Add the following line to your `.gitignore` to make sure not to commit your
  PEM file by mistake: `/storage/*.pem`
- Edit the `docker-compose.yml` to expose the port 33060 from the php-fpm service:
```yml
   3 services:
   ...
  12   php-fpm:
  13     build: ./images/php-fpm
+ 14     ports:
+ 15       - 33060
```
- Edit the php-fpm Dockerfile in `.docker/images/php-fpm/Dockerfile` to install
`openssh-client`:
```
  3 RUN apt-get update && \
- 4     apt-get install -y mysql-client && \
+ 4     apt-get install -y mysql-client openssh-client && \
```
- (Optional) Remove the entire "db" section from the docker-compose.yml file
- Update your `docker-compose.yml` php-fpm service environments to replace DB_HOST:
```
- 19       DB_HOST: db
+ 19       DB_HOST: 127.0.0.1
```
- Restart the containers with `dcp up -d --force-recreate`
- Establish the SSH tunnel with `dcp exec php-fpm ssh -i storage/<keypair name>.pem -4 -o ServerAliveInterval=30 -f <user>@<machine ip> -L 33060:<databse dns>:3306 -N`
---

The following docker-compose configuration <https://github.com/devigner/docker-compose-php> has been used as a starting point.

---

## Troubleshooting

While creating a new environment I encountered the following error while connecting to MySQL through Sequel Pro:
```
MySQL said: Authentication plugin 'caching_sha2_password' cannot be loaded: dlopen(/usr/local/lib/plugin/caching_sha2_password.so, 2): image not found
```

I solved this by logging in into the mysql docker-compose container and running:
1. docker exec -it <app_name>_db_1 bash
2. mysql -u root -p 123456
3. `ALTER USER 'user' IDENTIFIED WITH mysql_native_password BY 'password';`

From <https://stackoverflow.com/a/50130973/2141119>
