#!/bin/bash

mkdir -p ~/cache

cd ~/cache

if [ -d "opencollective-api/.git" ]; then
  cd opencollective-api
else
  rm -rf opencollective-api
  git clone https://github.com/opencollective/opencollective-api.git
  cd opencollective-api
fi

echo "> Matching frontend branch if it exists"
git checkout ${CIRCLE_BRANCH} 2>/dev/null

echo "> Pulling latest changes from GitHub"
git pull origin

echo "> Installing npm packages"
npm ci

echo "> Building API"
npm run build

echo "> Restoring opencollective_dvl database for e2e testing";
export PGPORT=5432
export PGHOST=localhost
export PGUSER=ubuntu
npm run db:setup
./scripts/db_restore.sh -U ubuntu -d opencollective_dvl -f test/dbdumps/opencollective_dvl.pgsql
./scripts/sequelize.sh db:migrate
if [ $? -ne 0 ]; then
  echo "Error with restoring opencollective_dvl, exiting"
  exit 1;
else
  echo "✓ API is setup";
fi
