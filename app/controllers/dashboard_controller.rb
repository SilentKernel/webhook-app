# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_organization

  def index
    @organization = current_organization
    @membership = current_membership

    # Quick stats
    @sources_count = @organization.sources.active.count
    @destinations_count = @organization.destinations.status_active.count
    @events_24h_count = Event.joins(:source)
                             .where(sources: { organization_id: @organization.id })
                             .since(24.hours.ago)
                             .count
    @success_rate = calculate_success_rate
  end

  private

  def calculate_success_rate
    deliveries = Delivery.joins(event: :source)
                         .where(sources: { organization_id: @organization.id })
                         .where(status: [ :success, :failed ])
                         .where("deliveries.completed_at >= ?", 7.days.ago)

    total = deliveries.count
    return nil if total.zero?

    successful = deliveries.where(status: :success).count
    (successful.to_f / total * 100).round(1)
  end
end
