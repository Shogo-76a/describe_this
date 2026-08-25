# spec/support/current_attributes_support.rb
module CurrentAttributesSupport
  extend ActiveSupport::Concern

  included do
    around(:each, type: :system) do |example|
      original_adapter = ActiveJob::Base.queue_adapter
      original_session = Current.session
      
      # ジョブ実行時に Current.session を保持するカスタムアダプタ
      class PreservingInlineAdapter < ActiveJob::QueueAdapters::InlineAdapter
        attr_accessor :session_to_preserve
        
        def execute_job(job)
          old_session = Current.session
          Current.session = session_to_preserve
          begin
            super(job)
          ensure
            Current.session = old_session
          end
        end
      end
      
      adapter = PreservingInlineAdapter.new
      adapter.session_to_preserve = original_session
      ActiveJob::Base.queue_adapter = adapter
      
      example.run
      
      ActiveJob::Base.queue_adapter = original_adapter
    end
  end
end