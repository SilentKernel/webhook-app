# frozen_string_literal: true

class DeliveriesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_organization
  before_action :set_delivery, only: [ :show, :retry ]

  def index
    @destinations = current_organization.destinations
    @deliveries = Delivery.joins(event: :source)
                          .where(sources: { organization_id: current_organization.id })
                          .includes(:event, :destination, :connection)
                          .order(created_at: :desc)

    @deliveries = @deliveries.where(status: params[:status]) if params[:status].present?
    @deliveries = @deliveries.where(destination_id: params[:destination_id]) if params[:destination_id].present?
    @deliveries = @deliveries.where(event_id: params[:event_id]) if params[:event_id].present?

    @deliveries = @deliveries.limit(50)
  end

  def show
    @attempts = @delivery.delivery_attempts.order(attempt_number: :asc)
  end

  def retry
    unless @delivery.can_retry?
      redirect_to delivery_path(@delivery), alert: "This delivery cannot be retried."
      return
    end

    @delivery.update!(status: :pending, next_attempt_at: nil)

    redirect_to delivery_path(@delivery), notice: "Delivery queued for retry."
  end

  private

  def set_delivery
    @delivery = Delivery.joins(event: :source)
                        .where(sources: { organization_id: current_organization.id })
                        .find(params[:id])
  end
end
