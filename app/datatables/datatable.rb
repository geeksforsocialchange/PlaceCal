class Datatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegator :@view, :link_to
  def_delegator :@view, :edit_admin_neighbourhood_path
  def_delegator :@view, :edit_admin_user_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end
end