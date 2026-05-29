#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install

# Solid Queueテーブルの存在確認・スキーマロード
SOLID_QUEUE_EXISTS=$(bundle exec rails runner "
begin
 tables = ActiveRecord::Base.connection.tables.grep(/solid_queue/)
 puts tables.size >= 10 ? 'true' : 'false'
rescue
 puts 'false'
end
")

if [ "$SOLID_QUEUE_EXISTS" = "false" ]; then
 DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:schema:load SCHEMA=db/queue_schema.rb
fi

bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
