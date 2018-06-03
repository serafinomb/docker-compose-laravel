## A docker-compose configuration to set up a ready-to-use laravel environment.
- PHP 7, with Xdebug
- MySQL
- Nginx
- Composer
- Node, with NPM

### Usage
- Clone the repository
- Copy/clone your laravel project inside `/app`
- Review the `/app/.env.docker-example` file for the database connection info
- Optional: Rename `.env.example` into `.env` and customize the variables
- If not using the Nutella (stand-alone) compose file: create a new network and run the nginx-proxy container (see 1. below)
- Review and run the `deploy.sh` script.
- Add the `VIRTUALHOST` domain, if set in the `.env` file, to your `hosts` file.

Mind that the `composer` container will probably fail the first time for reasons I'm not
sure about at the moment, I'm a little tired and I'm too lazy to re-run the `docker-compose up -d`
from a clean app to check. If you get the usual "cannot require composer"-something something
error just run `docker-compose composer up -d` again.
I've just re-run a "docker-compose up -d" on a clean project and composer didn't fail but is taking
its time to install the dependencies. So if it doesn't fail, wait till it's done (it will stop) to
run any command in your application.

You should be able to view your laravel project at http://localhost or at http://VIRTUAL_HOST

### 1. Run multiple applications
I've not tested this deeply but this should allow us to have multiple nxing-app running at the
same time, with different virtual hosts, allowing us to have multiple applications with
different domains.

```
$ docker network create nginx-proxy
$ docker run -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro --net nginx-proxy jwilder/nginx-proxy
```

### 2. Xdebug
Xdebug is installed and enabled by default in the "phpfpm" container. All you need to do to start using
it is set your private IP in ".docker/images/php-fpm/php.ini" in the "xdebug.remote_host" option.

### 3. Database tunneling
If you are working with a remote database, example Amazon RDS, and you need to enstablish a tunnel connection to connect to it:

- Copy your PEM certificate into the `/app/storage` folder
- Add the following line to your `.gitignore` to make sure not to commit your PEM file by mistake: `/storage/*.pem`
- Edit the `docker-compose.yml`, adding the following line inside the "services", "php", "expose" section: `- 33060`. It should look something like this:
```yml
  3 services:
  4   phpfpm:
  5     build: ./.docker/images/php-fpm
  6     expose:
  7       - 9000
+ 8       - 33060
```
- (Optional) You can remove the entire "db" section from the docker-compose.yml file
- Restart the containers with `docker-compose up -d --force-recreate`
- Install the SSH client with `docker-compose exec phpfpm /bin/bash -c "apt update && apt install openssh-client"`
- Enstablish the SSH tunnel with `docker-compose exec phpfpm ssh -i storage/<keypair name>.pem -4 -o ServerAliveInterval=30 -f <user>@<machine ip> -L 33060:<databse dns>:3306 -N`
- Edit your .env file as follows: `DB_HOST=127.0.0.1` and `DB_PORT=33060`
---

The following docker-compose configuration <https://github.com/devigner/docker-compose-php> has been used as a starting point.

---

#### Notes
After restarting the containers `$ docker-compose up -d --force-recreate` I had the following error when making requests to the nginx instance `$ curl -H "Host: <VIRTUAL_HOST>" 0.0.0.0`:
```
[error] 18#18: *1 directory index of "/usr/share/nginx/html/" is forbidden, client: 172.18.0.1, server: localhost, request: "GET / HTTP/1.1", host: "<VIRTUAL_HOST>"
```
I debugged this thing for almost two evenings and finally solved it by removing `$ docker rm -f <container id> ...` all the related containers and running a `$ docker-compose up -d`.

Use `$ docker ps -a` for a list of all containers.

---

I had a 503 permission issue on the Mac Pro (read Hackintosh) at home. I tried this evening to do the same steps on my Macbook Air and everything went fine.
I've to investigate this and try again on the Mac Pro but I've the feeling that the issue might have been caused by running the `deploy.sh` script as "sudo".
I suggest to `rm` the "app" folder completely and re-clone your project, and run the commands manually. Until I get to make a good deploy script.
Right– I fixed this by running `chmod -R g+rwx app`.

---

I also had problems connecting to the MySQL database, something about allowed domain to connect to the database. I had no issue on this machine (Macbook Air) though.
I need to investigate into it.
I tried again on my Mac Pro and running the `deploy.sh` script as "sudo" might have caused the MySQL issue. I removed the volumes and rerun `docker-compose up -d`
and everything is working fine now. Use `docker volume` to manage your volumes.

---

While creating a new environment I encountered the following error while connecting to MySQL through Sequel Pro:
```
MySQL said: Authentication plugin 'caching_sha2_password' cannot be loaded: dlopen(/usr/local/lib/plugin/caching_sha2_password.so, 2): image not found
```

I solved this by logging in into the mysql docker-compose container and running:
1. docker exec -it <app_name>_db_1 bash
2. mysql -u root -p 123456
3. `ALTER USER 'user' IDENTIFIED WITH mysql_native_password BY 'password';`

From <https://stackoverflow.com/a/50130973/2141119>
