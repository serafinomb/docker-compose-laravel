## A docker-compose configuration to set up a ready-to-use laravel environment.
- PHP 7
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

You should be able to view your laravel project at http://localhost or at http://VIRTUAL_HOST

### 1. Run multiple applications
I've not tested this deeply but this should allow us to have multiple nxing-app running at the
same time, with different virtual hosts, allowing us to have multiple applications with
different domains.

```
$ docker network create nginx-proxy
$ docker run -d -p 80:80 -v /var/run/docker.sock:/tmp/docker.sock:ro --net nginx-proxy jwilder/nginx-proxy
```

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
