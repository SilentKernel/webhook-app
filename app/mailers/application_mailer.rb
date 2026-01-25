class ApplicationMailer < ActionMailer::Base
  default from: -> { Rails.application.credentials.dig(:mailer, :from) || "app@notif.hookstack.io" }
  layout "mailer"
end
