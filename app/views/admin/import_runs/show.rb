# frozen_string_literal: true

class Views::Admin::ImportRuns::Show < Views::Admin::Base
  include Phlex::Rails::Helpers::TimeAgoInWords

  LOCATION_BADGES = { 'matched_venue' => 'badge-success', 'event_address' => 'badge-info', 'default_location' => 'badge-warning',
                      'room' => 'badge-info', 'none' => 'badge-ghost', 'failed' => 'badge-error', 'skipped' => 'badge-ghost' }.freeze
  RECENT_RUNS = 10

  prop :run, ImportRun, reader: :private
  prop :events, Array, reader: :private

  def view_template
    div(class: 'space-y-6') do
      render_summary
      render_events if run.outcome == 'imported'
      render_recent_runs
    end
  end

  private

  def card(&)
    div(class: 'bg-white shadow-sm rounded-xl overflow-hidden border border-gray-200', &)
  end

  def render_summary
    card do
      div(class: 'px-6 py-5 border-b border-gray-200 bg-gradient-to-r from-gray-50 to-white') do
        p(class: 'text-sm') { link_to t('admin.jobs.title'), admin_jobs_path, class: 'link link-hover text-gray-600' }
        h1(class: 'text-xl font-semibold text-gray-900 mt-1') { t('admin.import_runs.show.title', id: run.id) }
        p(class: 'mt-1 text-sm text-gray-600') do
          link_to run.calendar.name, edit_admin_calendar_path(run.calendar), class: 'link link-hover font-medium text-gray-900'
          plain " · #{I18n.l(run.started_at, format: :long)} (#{t('admin.time.ago', time: time_ago_in_words(run.started_at))})"
        end
      end
      div(class: 'px-6 py-4 flex flex-wrap items-center gap-x-6 gap-y-2 text-sm') do
        span { raw safe(outcome_badge(run)) }
        summary_item(:importer, importer_name) if run.importer
        summary_item(:took, ImportRun.duration_label(run.finished_at - run.started_at)) if run.finished_at
        if run.outcome == 'imported'
          summary_item(:changes, t('admin.import_runs.show.changes_summary', added: run.events_added, changed: run.events_changed,
                                                                             removed: run.events_removed, skipped: run.events_skipped))
        end
      end
      render_error
      render_notices
    end
  end

  def summary_item(key, value)
    span do
      span(class: 'text-gray-600') { "#{t("admin.import_runs.show.#{key}")}: " }
      span(class: 'font-medium') { value }
    end
  end

  def render_error
    return unless run.outcome.in?(ImportRunDatatable::OUTCOME_GROUPS['failed'])

    div(class: 'px-6 py-4 border-t border-gray-200 bg-red-50 shadow-[inset_4px_0_0_var(--color-error)]') do
      p(class: 'text-sm text-red-700 whitespace-pre-line break-words') { run.error.presence || t("admin.import_runs.default_errors.#{run.outcome}") }
    end
  end

  def render_notices
    return if run.notices.blank?

    div(class: 'px-6 py-4 border-t border-gray-200') do
      h2(class: 'text-sm font-semibold text-gray-900 mb-2') { t('admin.import_runs.show.notices', count: run.notices.size) }
      ul(class: 'space-y-1 text-sm text-gray-700 list-disc pl-5') { run.notices.each { |notice| li { notice } } }
    end
  end

  def render_events
    card do
      div(class: 'px-6 py-4 border-b border-gray-200') do
        h2(class: 'text-lg font-semibold text-gray-900') { t('admin.import_runs.show.events_title', count: events.size) }
        p(class: 'mt-1 text-sm text-gray-600') { t('admin.import_runs.show.events_kept') }
      end
      if events.any?
        div(class: 'overflow-x-auto') do
          table(class: 'table table-sm') do
            thead { tr { %i[event location placed occurrences note].each { |column| th { t("admin.import_runs.show.columns.#{column}") } } } }
            tbody { events.each { |event| render_event(event) } }
          end
        end
      else
        p(class: 'px-6 py-4 text-sm text-gray-600') { t('admin.import_runs.show.events_gone') }
      end
    end
  end

  def render_event(event)
    tr do
      td(class: 'font-medium') { event.title.presence || t('admin.import_runs.show.untitled') }
      td(class: 'text-sm text-gray-600 whitespace-normal') { event.location }
      td { span(class: "badge badge-sm whitespace-nowrap #{LOCATION_BADGES[event.location_result]}") { t("admin.import_runs.location_results.#{event.location_result}") } }
      td(class: 'text-right tabular-nums') { event.occurrences.to_s }
      td(class: 'text-sm text-gray-600 whitespace-normal') { event.reason }
    end
  end

  def render_recent_runs
    others = run.calendar.import_runs.where.not(id: run.id).latest_first.limit(RECENT_RUNS)
    return if others.none?

    card do
      h2(class: 'px-6 py-4 border-b border-gray-200 text-lg font-semibold text-gray-900') { t('admin.import_runs.show.recent_runs') }
      ul(class: 'divide-y divide-gray-100') do
        others.each do |other|
          li(class: 'px-6 py-2 flex flex-wrap items-center gap-3 text-sm') do
            link_to "##{other.id}", admin_import_run_path(other), class: 'font-mono text-gray-500 hover:text-orange-600'
            span(class: 'text-gray-600') { t('admin.time.ago', time: time_ago_in_words(other.started_at)) }
            raw safe(outcome_badge(other))
          end
        end
      end
    end
  end

  def outcome_badge(run)
    key = run.finished_at ? run.outcome.to_s : 'running'
    %(<span class="badge badge-sm whitespace-nowrap #{ImportRunDatatable::BADGES[key]}">#{ERB::Util.html_escape(t("admin.import_runs.outcomes.#{key}"))}</span>)
  end

  def importer_name
    parser = CalendarImporter::CalendarImporter.parser_for_key(run.importer)
    parser ? parser::NAME : run.importer.titleize
  end
end
