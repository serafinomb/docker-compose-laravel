## A docker-compose configuration to set up a ready-to-use laravel environment.
- PHP 7
- MySQL
- Nginx
- Composer

### Usage
- Clone the repository
- Copy/clone your laravel project inside `/app`
- Check out the `/app/.env.docker-example` file for the database connection info
- Optional: Rename `.env.example` into `.env` and customize the variables
- Review and run the `deploy.sh` script
- Run `docker-compose up -d`

You should be able to view your laravel project at http://localhost or at http://VIRTUAL_HOST

---

The following docker-compose configuration has been used as a starting point:
<https://github.com/devigner/docker-compose-php>
