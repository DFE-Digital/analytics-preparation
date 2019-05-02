# Schools Experience Analytics

## Enhancing data for analytics

This repository contains some DDL that is used to generate database objects
that are more-digestible by PowerBI, which doesn't support [geography
datatypes](https://postgis.net/workshops/postgis-intro/geography.html) or
[arrays](https://www.postgresql.org/docs/current/arrays.html).

## How does it work?

To concatenate all of the scripts into `full.sql` run the following command:

```bash
$ make
```

## And how do I apply it to my freshly-imported Schools Experience database?

```bash
$ psql --host [your-host] --username [your-username] [your-database] < full.sql
```

This step is intended to be run as part of the automated analytics data refresh
that happens nightly.

Newly-added scripts can just be dropped into the `scripts` directory, **but
please remember** to run `make` before committing. The current version of the
updater simply grabs the `full.sql` file from this repo.
