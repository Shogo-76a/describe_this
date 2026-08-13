class UsersController < ApplicationController

    def show
      @user = Current.user
    end

    def privacy_policy; end
    def terms; end
end
