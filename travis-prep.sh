#!/usr/bin/env bash

# ############################################################
# Setup

# Make sure we know where we are
PROJECT_ROOT=`pwd`

# Fail fast
set -e

# ############################################################
# Test database

echo "Initializing database:"
set -x
mysql -u root -e 'CREATE DATABASE IF NOT EXISTS mrt_dashboard_test'
mysql -u root -e 'GRANT ALL ON mrt_dashboard_test.* TO travis@localhost'
{ set +x; } 2>/dev/null


# ############################################################
# Configuration

echo "Copying configuration files:"
cd .config-travis
CONFIG_FILES=$(find . -type f | sed "s|^\./||")
cd ${PROJECT_ROOT}
for CONFIG_FILENAME in ${CONFIG_FILES}; do
  SOURCE_FILE=.config-travis/${CONFIG_FILENAME}
  DEST_FILE=config/${CONFIG_FILENAME}
  if [ -L ${DEST_FILE} ]; then
    echo "  skipping symlink ${DEST_FILE}"
  else
    set -x
    mkdir -p $(dirname ${DEST_FILE})
    cp ${SOURCE_FILE} ${DEST_FILE}
    { set +x; } 2>/dev/null
  fi
done

# ############################################################
# Install dependencies

bundle install

# ############################################################
# Load database schema

RAILS_ENV=test bundle exec rake db:schema:load
