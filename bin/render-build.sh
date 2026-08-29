#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install


bundle exec rails assets:precompile
bundle exec rails assets:clean

# メイン（Neon）のマイグレーションを実行
bundle exec rails db:migrate

# メイン（Neon）の初期データ作成
bundle exec rails db:seed

# Render内部DB（cache）にテーブルを一括作成
bundle exec rails db:schema:load:cache SCHEMA=db/cache_schema.rb

# Render内部DB（queue）にテーブルを一括作成
bundle exec rails db:schema:load:queue SCHEMA=db/queue_schema.rb