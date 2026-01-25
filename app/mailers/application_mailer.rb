class ApplicationMailer < ActionMailer::Base
  default from: ->(_mailer) { Rails.application.credentials.dig(:mailer, :from) || "app@notif.hookstack.io" }
  layout "mailer"
end
