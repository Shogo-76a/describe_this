class GenerateImageJob < ApplicationJob
  queue_as :default

  def perform(description)
    Rails.logger.info "ジョブが実行されました: #{description}"

  end
end
