# frozen_string_literal: true

namespace :dev do
  desc "Send a test delivery failure notification email (opens in letter_opener)"
  task send_failure_email: :environment do
    unless Rails.env.development?
      abort "This task is only available in development"
    end

    # Find or specify user
    email = ENV.fetch("EMAIL", "ludo@hey.com")
    user = User.find_by(email: email)

    if user.nil?
      abort "User not found: #{email}. Run `bin/rails db:seed` first or specify EMAIL=<email>"
    end

    puts "Found user: #{user.email}"

    # Find a failed delivery or any delivery with a destination
    delivery = Delivery.failed.joins(:destination).first ||
               Delivery.joins(:destination).first

    if delivery.nil?
      abort "No deliveries found. Create some test data first."
    end

    puts "Using delivery ##{delivery.id} (status: #{delivery.status}) to #{delivery.destination.name}"

    # Reset rate limit to ensure email sends
    if user.last_failure_email_sent_at.present?
      puts "Resetting rate limit (was: #{user.last_failure_email_sent_at})"
      user.update_column(:last_failure_email_sent_at, nil)
    end

    # Send email synchronously so letter_opener opens immediately
    puts "Sending failure notification email..."
    DeliveryMailer.failure_notification(user: user, delivery: delivery).deliver_now

    puts "Done! Email should have opened in your browser via letter_opener."
  end
end
