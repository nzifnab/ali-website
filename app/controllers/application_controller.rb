class ApplicationController < ActionController::Base
  helper_method :corp_member?
  def corp_member?
    corp_member_token == Rails.application.config.corp_member_token
  end

  def corp_member_token
    if params[:corp_member].present?
      session[:corp_token] = params[:corp_member]
    end

    session[:corp_token]
  end
end
