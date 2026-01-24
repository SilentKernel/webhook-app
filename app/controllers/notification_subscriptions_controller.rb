# frozen_string_literal: true

class NotificationSubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def destroy
    subscription = current_user.destination_notification_subscriptions.find(params[:id])
    subscription.destroy

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(subscription) }
      format.html { redirect_to edit_user_registration_path, notice: "Unsubscribed from failure notifications." }
    end
  end
end
