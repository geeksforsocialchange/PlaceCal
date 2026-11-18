# frozen_string_literal: true

module Admin
  class ImportRunsController < Admin::ApplicationController
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped
    before_action { redirect_to admin_root_path unless current_user.root? }

    def index
      render json: ImportRunDatatable.new(params, view_context:)
    end

    def show
      run = ImportRun.includes(:calendar).find(params[:id])
      render Views::Admin::ImportRuns::Show.new(run:, events: run.events.order(:title).to_a)
    end
  end
end
