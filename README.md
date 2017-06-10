## A docker-compose configuration to set up a ready-to-use laravel environment.
- PHP 7
- MySQL
- Nginx
- Composer

### Usage
- Clone the repository
- Copy/clone your laravel project inside `/app`
- Review the `/app/.env.docker-example` file for the database connection info
- Optional: Rename `.env.example` into `.env` and customize the variables
- Run `docker-compose up -d`
- Review and run the `deploy.sh` script

You should be able to view your laravel project at http://localhost or at http://VIRTUAL_HOST

### Run multiple applications
Run a single nginx-proxy with
```
$ docker network create nginx-proxy
$ docker run -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro --net nginx-proxy jwilder/nginx-proxy
```

(WIP)

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
