## Local dev environment for Woo

Based on docker setup, with on-demand debug capabilities.

Exposes two sites - `w.test` and `d.w.test` connected to same database. `w.test` is relatively fast site, while `d.w.test` has xdebug installed for tricky situations. They both are configured with same database and codebase, so all you have to is replace `w.test` with `d.w.test` in browser to switch into debug environment.

#### Install

1. Clone this repo.
1. `cd woo_dev` and run `sh install.sh`.
1. Add following lines to `/etc/hosts`:
    ```bash
    127.0.0.1	w.db
    127.0.0.1	w.test
    127.0.0.1	d.w.test
    ```
1. Visit `https://w.test`, accept security exception and complete the WordPress setup.
1. Visit `https://d.w.test` and accept security exception.
1. (Optional) Debug server will connect on port 9001 with server name `Woo-Test`, configure your IDE to listen to this port.
1. (Optional) Replace `host.docker.internal` with your local IP address in `./docker-compose.yml` if you have configured Docker to run on a custom network. You should not need to do this on OSX.

#### Commands

1. `sh install.sh` to install and start setup.
1. `sh start.sh` to start containers.
1. `sh stop.sh` to stop running containers.
1. `sh access_log.sh` to tail access logs along with request times.
1. `sh slow_query_log.sh` to tail slow DB queries. Currently this is setup to `0.001`s, you can configure this in `./docker-compose.yml` by search-replacing `--long_query_time=0.001` param.
1. `clean-log.sh` to clean custom log files.
1. `docker-compose exec w.test bash` to open a shell in main (faster) server.
1. `docker-compose exec d.w.test bash` to open a shell in debug server.

#### Directory structure

Root directory `woo_dev` will contain:

1. `WordPress` - WordPress main install files. This is sourced control using Git to easy switch version. `cd` into the directory to manage. This is mounted to `/usr/src/public_html/wordpress` inside docker containers.

1. `plugins` - Plugin directory. This will have `woocommerce` downloaded during the install step. Mounted to `/usr/src/public_html/wp-content/plugins` inside docker containers.
**Note: For build files and dependencies, you can directly run commands like `composer install` or `npm install` from host after `cd`'ing into directory. You can also open a shell inside docker to run these, but its not required.**

1. `themes` - Theme directory. This will be empty, so you would have to add a theme after fresh install. Mounted to `/usr/src/public_html/wp-content/themes` inside docker containers.

#### Links

Mailcatcher is at `127.0.0.1:1080` from main server and `127.0.0.1:1081` from debug server. All sent mails to any address will end up here.
