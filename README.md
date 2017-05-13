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

---

The docker-compose configuration from devigner/docker-compose-php has been
used as a starting point: <https://github.com/devigner/docker-compose-php>
