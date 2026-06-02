class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  #---------本番環境ではコメントアウト消して、有効にしておくこと----------#
  #  allow_browser versions: :modern
  #---------本番環境ではコメントアウト消して、有効にしておくこと----------#


  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
