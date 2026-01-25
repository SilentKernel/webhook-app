# frozen_string_literal: true

class ConnectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_organization
  before_action :set_connection, only: [ :show, :edit, :update, :destroy ]
  before_action :load_sources_and_destinations, only: [ :new, :edit, :create, :update ]

  def index
    connections = Connection.joins(:source)
                            .where(sources: { organization_id: current_organization.id })
                            .includes(:source, :destination)
                            .order(created_at: :desc)
    @pagy, @connections = pagy(:offset, connections)
  end

  def show
  end

  def new
    @connection = Connection.new
  end

  def create
    @connection = Connection.new(connection_params)

    # Verify source belongs to current org
    unless current_organization.sources.exists?(id: @connection.source_id)
      redirect_to connections_path, alert: "Invalid source."
      return
    end

    # Verify destination belongs to current org
    unless current_organization.destinations.exists?(id: @connection.destination_id)
      redirect_to connections_path, alert: "Invalid destination."
      return
    end

    if @connection.save
      redirect_to connection_path(@connection), notice: "Connection created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Verify source belongs to current org if changing
    if connection_params[:source_id].present?
      unless current_organization.sources.exists?(id: connection_params[:source_id])
        redirect_to connections_path, alert: "Invalid source."
        return
      end
    end

    # Verify destination belongs to current org if changing
    if connection_params[:destination_id].present?
      unless current_organization.destinations.exists?(id: connection_params[:destination_id])
        redirect_to connections_path, alert: "Invalid destination."
        return
      end
    end

    if @connection.update(connection_params)
      redirect_to connection_path(@connection), notice: "Connection updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @connection.destroy
    redirect_to connections_path, notice: "Connection deleted successfully."
  end

  private

  def set_connection
    @connection = Connection.joins(:source)
                            .where(sources: { organization_id: current_organization.id })
                            .find(params[:id])
  end

  def load_sources_and_destinations
    @sources = current_organization.sources.active
    @destinations = current_organization.destinations.where(status: [ :active, :paused ])
    @connections_with_rules = Connection.joins(:source)
      .where(sources: { organization_id: current_organization.id })
      .where.not(rules: [ nil, [] ])
      .select(:id, :name, :rules)
  end

  def connection_params
    params.require(:connection).permit(:source_id, :destination_id, :name, :status, :priority, :forward_all_headers, :forward_headers).tap do |p|
      if params[:connection][:rules].present?
        p[:rules] = JSON.parse(params[:connection][:rules])
      end

      # Convert comma-separated string to array
      if params[:connection][:forward_headers].present?
        p[:forward_headers] = params[:connection][:forward_headers]
          .split(",")
          .map(&:strip)
          .reject(&:blank?)
      else
        p[:forward_headers] = []
      end
    rescue JSON::ParserError
      # Let validation handle invalid JSON
    end
  end
end
