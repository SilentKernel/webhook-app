class ApplicationMailer < ActionMailer::Base
  default from: "HookStack.io <#{Rails.application.credentials.dig(:mailer, :from) || 'app@notif.hookstack.io'}>"
  layout "mailer"
end
