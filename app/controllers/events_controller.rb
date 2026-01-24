# frozen_string_literal: true

class EventsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_organization
  before_action :set_event, only: [ :show, :replay ]

  def index
    @sources = current_organization.sources
    events = Event.joins(:source)
                  .where(sources: { organization_id: current_organization.id })
                  .includes(:source, :deliveries)
                  .recent

    events = events.where(source_id: params[:source_id]) if params[:source_id].present?
    events = events.by_event_type(params[:event_type]) if params[:event_type].present?
    events = events.since(Time.zone.parse(params[:since])) if params[:since].present?
    events = events.until(Time.zone.parse(params[:until])) if params[:until].present?

    @pagy, @events = pagy(:offset, events)
  end

  def show
    @deliveries = @event.deliveries.includes(:destination, :connection)
  end

  def replay
    connections = @event.source.connections.active

    if connections.empty?
      redirect_to event_path(@event), alert: "No active connections to replay to."
      return
    end

    connections.each do |connection|
      delivery = @event.deliveries.create!(
        connection: connection,
        destination: connection.destination,
        status: :queued,
        max_attempts: 5
      )
      DeliverWebhookJob.perform_later(delivery.id)
    end

    redirect_to event_path(@event), notice: "Event queued for replay to #{connections.count} destination(s)."
  end

  private

  def set_event
    @event = Event.joins(:source)
                  .where(sources: { organization_id: current_organization.id })
                  .find(params[:id])
  end
end
