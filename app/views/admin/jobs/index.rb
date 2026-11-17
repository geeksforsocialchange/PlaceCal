# frozen_string_literal: true

# Mission Control Jobs inside the admin layout, framed so its Bulma styles can't restyle the admin's own
class Views::Admin::Jobs::Index < Views::Admin::Base
  prop :dashboard_path, String, reader: :private

  def view_template
    content_for(:title) { t('admin.jobs.title') }
    div(class: 'mb-4') do
      h1(class: 'text-2xl font-bold') { t('admin.jobs.title') }
      p(class: 'text-sm text-gray-600 mt-1') { t('admin.jobs.description') }
    end
    iframe(src: dashboard_path, title: t('admin.jobs.title'), class: 'block w-full h-[calc(100vh-12rem)] border-0 rounded-box bg-base-100')
  end
end
