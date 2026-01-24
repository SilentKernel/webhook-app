# frozen_string_literal: true

class DestinationsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_organization
  before_action :set_destination, only: [ :show, :edit, :update, :destroy ]
  before_action :load_org_members, only: [ :new, :edit, :create, :update, :new_modal, :create_modal ]

  def index
    @pagy, @destinations = pagy(:offset, current_organization.destinations.order(created_at: :desc))
  end

  def show
    @connections = @destination.connections.includes(:source)
  end

  def new
    @destination = current_organization.destinations.build
  end

  def create
    @destination = current_organization.destinations.build(destination_params)

    if @destination.save
      redirect_to destination_path(@destination), notice: "Destination created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @destination.update(destination_params)
      redirect_to destination_path(@destination), notice: "Destination updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @destination.destroy
    redirect_to destinations_path, notice: "Destination deleted successfully."
  end

  def new_modal
    @destination = current_organization.destinations.build
    render layout: false
  end

  def create_modal
    @destination = current_organization.destinations.build(destination_params)

    if @destination.save
      respond_to do |format|
        format.turbo_stream
      end
    else
      render :new_modal, layout: false, status: :unprocessable_entity
    end
  end

  private

  def set_destination
    @destination = current_organization.destinations.find(params[:id])
  end

  def load_org_members
    @org_members = current_organization.confirmed_members.order(:first_name, :last_name)
  end

  def destination_params
    params.require(:destination).permit(
      :name, :url, :http_method, :auth_type, :auth_value,
      :status, :timeout_seconds, :max_delivery_rate, :expected_status_code,
      notification_subscriber_ids: []
    ).tap do |p|
      if params[:destination][:headers].present?
        p[:headers] = JSON.parse(params[:destination][:headers])
      end
    rescue JSON::ParserError
      # Let validation handle invalid JSON
    end
  end
end
