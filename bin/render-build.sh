#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install


bundle exec rails assets:precompile
bundle exec rails assets:clean

# 1. メイン（Neon）のマイグレーションを実行
bin/rails exec rails db:migrate

# 2. Render内部DB（cache）にテーブルを一括作成
bin/rails exec rails db:schema:load:cache SCHEMA=db/cache_schema.rb

# 3. Render内部DB（queue）にテーブルを一括作成
bin/rails exec rails db:schema:load:queue SCHEMA=db/queue_schema.rb