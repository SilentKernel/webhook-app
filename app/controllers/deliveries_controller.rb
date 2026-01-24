# frozen_string_literal: true

class DeliveriesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_organization
  before_action :set_delivery, only: [ :show, :replay ]

  def index
    @destinations = current_organization.destinations
    deliveries = Delivery.joins(event: :source)
                         .where(sources: { organization_id: current_organization.id })
                         .includes(:event, :destination, :connection)
                         .order(created_at: :desc)

    deliveries = deliveries.where(status: params[:status]) if params[:status].present?
    deliveries = deliveries.where(destination_id: params[:destination_id]) if params[:destination_id].present?
    deliveries = deliveries.where(event_id: params[:event_id]) if params[:event_id].present?

    @pagy, @deliveries = pagy(:offset, deliveries)
  end

  def show
    @attempts = @delivery.delivery_attempts.order(attempt_number: :asc)
  end

  def replay
    unless @delivery.can_replay?
      redirect_to delivery_path(@delivery), alert: "This delivery cannot be replayed."
      return
    end

    new_delivery = Delivery.create!(
      event: @delivery.event,
      connection: @delivery.connection,
      destination: @delivery.destination,
      status: :pending,
      max_attempts: @delivery.max_attempts
    )

    DeliverWebhookJob.perform_later(new_delivery.id)

    redirect_to delivery_path(new_delivery), notice: "A new delivery has been created."
  end

  private

  def set_delivery
    @delivery = Delivery.joins(event: :source)
                        .where(sources: { organization_id: current_organization.id })
                        .find(params[:id])
  end
end
