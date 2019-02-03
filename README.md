## A docker-compose configuration to set up a ready-to-use laravel environment.
- PHP 7, with Xdebug
- MySQL
- Nginx
- Composer

### Usage
- Clone the repository inside your project root (<project-dir>/.docker for example)
- Update your database connection configuration:
    - DB_CONNECTION=mysql
    - DB_HOST=db
    - DB_PORT=3306
    - DB_DATABASE=database
    - DB_USERNAME=user
    - DB_PASSWORD=password
- Optional: Rename `.env.example` into `.env` and customize the variables
- Create a new network and run the nginx-proxy container (see 1. below)
- From whitin the .docker folder, review (and run if needed) the `deploy.sh` script.
    
You should be able to view your laravel project at http://localhost or at http://VIRTUAL_HOST

##### Note about docker-compose -p (project)
To avoid volume collision always remember to pass in a unique project name when running docker-compose. I am currently using the parent folder name as project name. Given this folder structure: `.../my-project/.docker`, running docker-compose -p $(basename $(dirname $(pwd))) from within the `.docker` folder will use `my-project` as project name.

Add this function into your bash profile or zshenv to use the parent folder as project name:
```bash
function dcp() {
    docker-compose -p $(basename $(dirname $(pwd))) $@
}
```

### 1. Reverse proxy and running multiple applications
Run the following commands to be able to use the custom hostname specified in the .env file (for example
project-name.client.localhost):

```
$ docker network create nginx-proxy
$ docker run -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro --net nginx-proxy jwilder/nginx-proxy
```

As of right now it's not possible to run multiple Laravel applications at the same time. Even if
we can specify a custom hostname for each of them, the database host and database name is still
shared accross all the instances. It can be fixed but I've not had the time nor the need to do
so.

### 2. Xdebug
Xdebug is installed and enabled by default in the "phpfpm" container. All you need to do to start using
it is set your private IP in ".docker/images/php-fpm/php.ini" in the "xdebug.remote_host" option.
I've had some issues setting this up on PHPStorm and will update this section once I've time to understand
why.

### 3. Node (NPM, Yarn)
You'll probably also need npm/yarn, I'm currently using the "serafinomb/node" docker image
(docker pull serafinomb/node). Usage can be as follows:
- docker run -it --rm -v $(PWD):/ws:delegated -w /ws serafinomb/node node -v
- docker run -it --rm -v $(PWD):/ws:delegated -w /ws serafinomb/node npm -v
- docker run -it --rm -v $(PWD):/ws:delegated -w /ws serafinomb/node yarn -v

You can add an alias or function to your bash profile/zshenv. For example:
```bash
function node() {
    docker run -it --rm -e "TERM=xterm-256color" -v $(PWD):/ws:delegated -w /ws serafinomb/node node $@
}
```

### 4. Database tunneling
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

## Notes

Mind that the `composer` container will probably fail the first time for reasons I'm not
sure about at the moment, I'm a little tired and I'm too lazy to re-run the `docker-compose up -d`
from a clean app to check. If you get the usual "cannot require composer"-something something
error just run `docker-compose composer up -d` again.
I've just re-run a "docker-compose up -d" on a clean project and composer didn't fail but is taking
its time to install the dependencies. So if it doesn't fail, wait till it's done (it will stop) to
run any command in your application.

---

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
