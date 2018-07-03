# Merritt Dashboard

[![Build Status](https://travis-ci.org/CDLUC3/mrt-dashboard.svg?branch=master)](https://travis-ci.org/CDLUC3/mrt-dashboard)

This is the main UI application for the
[Merritt](https://merritt.cdlib.org/) repository service. For technical
documentation on Merritt's other components, please see the
[wiki](https://github.com/CDLUC3/mrt-doc/wiki).

## Table of contents

- [Installation](#installation)
- [Running the application](#running-the-application)
- [Tests](#tests)
- [Style checks](#style-checks)
- [Rake tasks](#rake-tasks)
- [Continuous integration](#continuous-integration)

## Requirements

- Ruby 2.4+ (specifically 2.4.4, if using rvm or rbenv)
- Bundler 1.16+
- MySQL 5.6+

## Installation

This project uses [Bundler](https://bundler.io/) for dependency management.
Run `bundle install` to install the required gems.

## Running the application

Configure the application to talk to the database:

- Copy `config/database.yml.example` to `config/database.yml` and set the
  `password` field as needed.

Configure the application to talk to LDAP:

- Copy `config/ldap.yml.example` to `config/ldap.yml` and set the
  `admin_password` field as needed.

To start the application in development mode, run 

```
bundle exec rails s
``` 

By default this (currently) uses the
[Thin](https://github.com/macournoyer/thin) web server, but you can also
run [Puma](https://github.com/puma/puma) in development mode with `bundle
exec puma`.

> #### TODO
> Is `atom.yml` needed? Should we provide an `atom.yml.example`?)

## Tests

The unit tests require a local MySQL database `mrt_dashboard_test`,
prepopulated with the database schema, with a user `travis` having all
privileges. You can create these with the following commands:

```
mysql -u root -e 'CREATE DATABASE IF NOT EXISTS mrt_dashboard_test CHARACTER SET utf8'
mysql -u root -e 'GRANT ALL ON mrt_dashboard_test.* TO travis@localhost'
RAILS_ENV=test bundle exec rake db:schema:load
```

(These commands are also run by the `travis-prep.sh` script in the application
root directory.

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
Chromedriver](https://github.com/flavorjones/chromedriver-helper#updating-to-latest-chromedriver)
documentation.

### Test coverage

To execute the tests with coverage checking, run:

```
bundle exec rake coverage
```

This will output the test coverage percentage, and will generate a coverage
report in `coverage/index.html`. 

**Coverage must be 100% for the continuous integration build to succeed.**

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
tests afterwords. Most RuboCop auto-fixes are smart enough not to change any
semantics, but occasionally it does make a mistake.)

**All style checks must pass for the continuous integration build to succeed.**

## Rake tasks

Note that all commands are preceded with `bundle exec` to make sure they use
the gems configured by Bundler.

- `bundle exec rake`
  - default Rake task; runs tests (with coverage), and if the tests succeed,
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
