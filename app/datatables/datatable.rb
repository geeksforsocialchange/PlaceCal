class Datatable < AjaxDatatablesRails::ActiveRecord
  extend Forwardable

  def_delegator :@view, :link_to
  def_delegator :@view, :edit_admin_article_path
  def_delegator :@view, :edit_admin_neighbourhood_path
  def_delegator :@view, :edit_admin_user_path
  def_delegator :@view, :edit_admin_partner_path
  def_delegator :@view, :edit_admin_site_path
  def_delegator :@view, :edit_admin_tag_path
  def_delegator :@view, :edit_admin_calendar_path

  def initialize(params, opts = {})
    @view = opts[:view_context]
    super
  end
end
