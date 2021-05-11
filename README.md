# Merritt Dashboard (Merritt UI)

[![Build Status](https://travis-ci.org/CDLUC3/mrt-dashboard.svg?branch=master)](https://travis-ci.org/CDLUC3/mrt-dashboard)

This microservice is part of the [Merritt Preservation System](https://github.com/CDLUC3/mrt-doc).

## Purpose

This microservice provides the User Interface for the Merritt Perservation System.

This microservice provides API functionality for the [Dryad](https://datadryad.org/)
and for the harvesting of Nuxeo content feeds for ingest into Merrit. 

## Component Diagram
[![Flowchart](https://github.com/CDLUC3/mrt-doc/raw/main/diagrams/ui.mmd.svg)](https://cdluc3.github.io/mrt-doc/diagrams/ui)

## Dependencies

This code depends on the following Merritt Libraries.
- [UC3 SSM Gem](https://github.com/CDLUC3/uc3-ssm)
- [Merritt Ingest Gem](https://github.com/CDLUC3/mrt-ingest-ruby)

## For external audiences
This code is not intended to be run apart from the Merritt Preservation System.

See [Merritt Docker](https://github.com/CDLUC3/merritt-docker) for a description of how to build a test instnce of Merritt.

## Build instructions
Ruby bundler is used to build this application.

## Test instructions
Travis.com is use to test this application.

RSpec and Capybara tests exist for this application.

## Internal Links


## Legacy README

This is the main UI application for the
[Merritt](https://merritt.cdlib.org/) repository service. For technical
documentation on Merritt's other components, please see the
[wiki](https://github.com/CDLUC3/mrt-doc/wiki).

## Table of contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Running the application](#running-the-application)
  - [Configuring LDAP and the database](#configuring-ldap-and-the-database)
  - [Starting the application](#starting-the-application)
- [Tests](#tests)
  - [Configuring the test database](#configuring-the-test-database)
  - [Running the tests](#running-the-tests)
  - [Running the tests with coverage](#running-the-tests-with-coverage)
- [Style checks](#style-checks)
- [Rake tasks and other commands](#rake-tasks-and-other-commands)
- [Continuous integration](#continuous-integration)
- [Puppet Automation](#puppet-automation)
- [Manual Deployment](#manual-deployment)

## Requirements

- Ruby 2.4+ (specifically 2.4.4, per [`.ruby-version`](.ruby-version), if using [RVM](https://rvm.io/) 
  or [rbenv](https://github.com/rbenv/rbenv))
- Bundler 1.16+
- MySQL 5.6+

## Installation

This project uses [Bundler](https://bundler.io/) for dependency management.
Run `bundle install` to install the required gems.

## Running the application

### Configuring LDAP and the database

Create a `.config-secret` directory at the root of the application. (This directory will
be ignored by git.) From the `config` directory, copy `database.yml.example` and `ldap.yml.example`
to `.config-secret`, removing the `.example` extension:

```
$ mkdir .config-secret
$ cp config/database.yml.example .config-secret/database.yml
$ cp config/ldap.yml.example .config-secret/ldap.yml
```

Next, edit `.config-secret/database.yml` to set the `password` field for the environments you're
interested in, and `.config-secret/ldap.yml` likewise to set the `admin_password` field.
(If you're not working with the UC3 MySQL and LDAP servers, you may also need to change
hostnames, ports, etc.)

Finally, symlink the `database.yml` and `ldap.yml` files from `.config-secret` back into the
`config` directory:

```
$ cd config
$ ln -s ../.config-secret/database.yml database.yml
$ ln -s ../.config-secret/ldap.yml ldap.yml
``` 

#### Alternative configuration methods

1. Instead of using `database.yml.example` and `ldap.yml.example`, you can copy files from
   any shared production, stage, or development environment. However, to run feature and
   controller tests, you'll need to edit the `test` configuration in `database.yml` to point
   to some database that's preloaded with the application schema and that it's safe for the
   tests to erase; this should not be a shared database. The `database.yml.example` file assumes
   a local database as described under [Tests](#tests), below.
2. Or, you can just copy `config/database.yml.example` / `config/ldap.yml.example`
   to `config/database.yml` / `config/ldap.yml` and edit those files directly. However, you'll 
   need to be careful not to run the `travis-prep.sh` script (and will have to configure your
   test database by hand). While the `travis-prep.sh` script will skip symlinks in `config`,
   it will copy over plain files. 

### Starting the application

To start the application in development mode, run 

```
bundle exec rails s
``` 

By default development mode (currently) uses the
[Thin](https://github.com/macournoyer/thin) web server, but you can also
run [Puma](https://github.com/puma/puma) in development mode with `bundle
exec puma`.

> **TODO:** Is `atom.yml` needed? Should we provide an `atom.yml.example`?)

## Tests

### Configuring the test database

The unit tests require a database, and one that can be safely cleared before each
test run. The `database.yml.example` file assumes a local MySQL database `mrt_dashboard_test`,
prepopulated with the database schema, with a user `travis` having all
privileges.

If your configuration files are symlinked as described above under 
[Configuring LDAP and the database](#configuring-ldap-and-the-database), you can
create and populate this database with the `travis-prep.sh` script used for
continuous integration. 

> **⚠️** If your configuration files are plain files rather than symlinks, the 
> `travis-prep.sh` script will overwrite them with the default files from `.config-travis`.) 

Alternatively, you can run the same commands manually:

```
mysql -u root -e 'CREATE DATABASE IF NOT EXISTS mrt_dashboard_test CHARACTER SET utf8'
mysql -u root -e 'GRANT ALL ON mrt_dashboard_test.* TO travis@localhost'
RAILS_ENV=test bundle exec rake db:schema:load
```

### Running the tests

To execute the tests, run:

```
bundle exec rake spec
```

Note that some of the tests run interactively in Chrome using
[ChromeDriver](https://sites.google.com/a/chromium.org/chromedriver/). The
[chromedriver-helper](https://github.com/flavorjones/chromedriver-helper)
gem should install ChromeDriver automatically. If not, or if you have an
old version of ChromeDriver installed, see chromedriver-helper’s “[Updating
to latest
Chromedriver](https://github.com/flavorjones/chromedriver-helper#updating-to-latest-chromedriver)”
documentation.

### Running the tests with coverage

To execute the tests with coverage checking, run:

```
bundle exec rake coverage
```

This will output the test coverage percentage, and will generate a coverage
report in `coverage/index.html`. 

> **⚠️ Coverage must be 100% for the continuous integration build to succeed.**

## Style checks

This project uses [RuboCop](https://github.com/rubocop-hq/rubocop) for
static code analysis and formatting. Most configuration and customization
is in the [root `.rubocop.yml` file](.rubocop.yml), with a few
directory-specific customization files elsewhere in the source tree.

To execute the RuboCop checks, run:

```
bundle exec rubocop
```

This will output a report on any style violations. You can also check just
a specific file, files, directory, or glob with `bundle exec rubocop <FILES>`.

RuboCop can fix many simple problems automatically, such as inconsistent
indentation, extra whitespace, unnecessary double quotes, pre-Ruby 1.9 hash
syntax, etc. To try to fix a file automatically, run:

```
bundle exec rubocop --auto-correct <FILE>
```

(Use caution, though, pay attention to the output, and make sure to run the
tests afterwards. Most RuboCop auto-fixes are smart enough not to change any
semantics, but occasionally it does make a mistake.)

> **⚠️ All style checks must pass for the continuous integration build to succeed.**
> **⚠️ All style checks must pass for the continuous integration build to succeed.**

## Rake tasks and other commands

Note that all commands are preceded with `bundle exec` to make sure they use
the gems configured by Bundler.

- `bundle exec rake`
  - default Rake task: runs tests (with coverage), and if the tests succeed,
    runs RuboCop style checks.
- `bundle exec rake spec`
  - runs the tests without coverage.
- `bundle exec rake coverage`
  - runs the tests with coverage.
- `bundle exec rubocop`
  - runs style checks.
- `bundle exec rails s`
  - starts the server in development mode.

## Continuous integration

This project uses [Travis CI](https://travis-ci.org/) for continous integration.
Build results can be viewed by clicking the badge at the top of this page, or
at [https://travis-ci.org/CDLUC3/mrt-dashboard](https://travis-ci.org/CDLUC3/mrt-dashboard).

The Travis build is configured in the [`.travis.yml`](.travis.yml) file.
It's a simple build, using the [`travis-prep.sh`](travis-prep.sh) script to
set up the test database and test configuration files, and then running
`bundle exec rake` -- the Travis default for a Ruby project.



## Puppet Automation

For 'stage' and 'production' rails environments, application deployment is
managed by puppet.  For full information on how to update a puppet managed
environment see the following:

- https://confluence.ucop.edu/display/UC3/Working+with+Puppet+Code
- `ias-puppet2-ops:/apps/puppet/environments/uc3/modules/uc3_mrt_ui/README.md`

### Updating Puppet Hiera Configs

Within your local clone of the uc3-data repository edit the appropriate `fqsn`
hiera data file for the particular service environment you are planning to
re-deploy.  Change the `revision` parameter in the `uc3_mrt_ui::config` stanza.

Example:

```
agould@uc3-aws2-ops:~/my_puppet_workspace/hiera-data/uc3-data> vi fqsn/uc3-mrt-ui-stg.yaml
agould@uc3-aws2-ops:~/my_puppet_workspace/hiera-data/uc3-data> git diff
diff --git a/fqsn/uc3-mrt-ui-stg.yaml b/fqsn/uc3-mrt-ui-stg.yaml
index 1feec25..c2ef712 100644
--- a/fqsn/uc3-mrt-ui-stg.yaml
+++ b/fqsn/uc3-mrt-ui-stg.yaml
@@ -6,7 +6,7 @@
 uc3_mrt_ui::config:
   stage:
     git_repo: https://github.com/CDLUC3/mrt-dashboard
-    revision: v1.0.3
+    revision: v1.0.4
```

Test your change and then deploy it to the puppet master as described in 
[Working with Puppet Code](https://confluence.ucop.edu/display/UC3/Working+with+Puppet+Code).


## Manual Deployment

This project is deployed with [Capistrano](https://capistranorb.com), as
controlled by the [`config/deploy.rb`](config/deploy.rb) file. Note that the
"environments" for Capistrano purposes are the individual service environment
files in the [`config/deploy`](config/deploy) directory.  See usage notes at
the head of each file.

Example:

```
$ head -5 config/deploy/uc3-mrt-ui-stg.rb
# For manually deploying to nodes in fqsn 'uc3-mrt-ui-stg'.
# We will always be deploying to localhost.
#
# Usage:
#   bundle exec cap uc3-mrt-ui-stg deploy BRANCH=<git-ref>

$ bundle exec cap uc3-mrt-ui-stg deploy BRANCH=v1.0.4
```

> **⚠️  You must disable puppet automation in order to perform manual
> deployment, or your deployment will be rolled back by puppet.**  Do this by
> setting `auto_deploy: flase` in the `uc3_mrt_ui::config` stanza in the
> appropriate hiera data file.


### Restarting Puma Service after Manual Deployment

Capistrano does not manage restarts of the puma service.  After deployment, you 
must restart puma manually.

For 'stage' and 'production' rails environments, use `systemctl` with `sudo`:

```
sudo systemctl reload puma
```

also useful:

```
sudo systemctl status puma
sudo systemctl start puma
sudo systemctl stop puma
sudo systemctl restart puma
```

For 'local' deployments, use `pumactl` with `bundle exec`:

```
/bin/bundle exec pumactl -F config/puma.rb phased-restart
```


### Configuration

Configuration for this project is stored in the `mrt-dashboard-config`
[private repository](https://github.com/cdlib/mrt-dashboard-config).

The configuration directory is are deployed by default as part of the
`mrt-dashboard` Capistrano deployment.

- To redeploy a change to the config files without redeploying the code,
  you can use `cap <ENV> deploy:update_config` in the `mrt-dashboard`
- To deploy a specific tag (not branch!) of this config repository, you
  can use the `$CONFIG_BRANCH` environment variable, either in a standalone
  config deployment:

  ```
  bundle exec cap ENV> deploy:update_config CONFIG_BRANCH=development
  ```

  or in a deployment of the code:

  ```
  bundle exec cap ENV> deploy:update_config CONFIG_BRANCH=development BRANCH=v1.0.4
  ````


## Notes

