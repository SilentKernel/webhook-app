# frozen_string_literal: true

class SourcesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_organization
  before_action :set_source, only: [ :show, :edit, :update, :destroy ]
  before_action :load_form_data, only: [ :new, :edit, :create, :update, :new_modal, :create_modal ]

  def index
    @pagy, @sources = pagy(:offset, current_organization.sources.includes(:source_type).order(created_at: :desc))
  end

  def show
    @connections = @source.connections.includes(:destination)
  end

  def new
    none_type = VerificationType.find_by(slug: "none")
    @source = current_organization.sources.build(verification_type: none_type)
  end

  def create
    @source = current_organization.sources.build(source_params)

    if @source.save
      redirect_to source_path(@source), notice: "Source created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @source.update(source_params)
      redirect_to source_path(@source), notice: "Source updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @source.destroy
    redirect_to sources_path, notice: "Source deleted successfully."
  end

  def new_modal
    none_type = VerificationType.find_by(slug: "none")
    @source = current_organization.sources.build(verification_type: none_type)
    render layout: false
  end

  def create_modal
    @source = current_organization.sources.build(source_params)

    if @source.save
      respond_to do |format|
        format.turbo_stream
      end
    else
      render :new_modal, layout: false, status: :unprocessable_entity
    end
  end

  private

  def set_source
    @source = current_organization.sources.find(params[:id])
  end

  def load_form_data
    @source_types = SourceType.active.includes(:verification_type)
    @verification_types = VerificationType.active
  end

  def source_params
    params.require(:source).permit(:name, :source_type_id, :verification_type_id, :verification_secret, :status)
  end
end
