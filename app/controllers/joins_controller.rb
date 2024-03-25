# frozen_string_literal: true

class JoinsController < ApplicationController
  before_action :set_site
  invisible_captcha only: %i[create update]

  def new
    @join = Join.new
  end

  def create
    @join = Join.new(join_params)

    if @join.submit
      redirect_to get_in_touch_path, notice: "Thank you for your interest in PlaceCal. We'll  be in touch with you shortly."
    else
      flash[:error] = 'Please fill out the required fields below'
      render :new
    end
  end

  private

  def join_params
    params.require(:join).permit(:name, :email, :phone, :job_title, :job_org, :area, :ringback, :more_info, :why)
  end
end
