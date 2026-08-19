class DocumentsController < ApplicationController
  allow_unauthenticated_access only: %i[ privacy_policy terms ]

  def privacy_policy; end
  def terms; end
end
