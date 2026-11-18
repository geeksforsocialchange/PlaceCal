# frozen_string_literal: true

class ImportRunDatatable < Datatable
  OUTCOME_GROUPS = { 'failed' => %w[error bad_source interrupted] }.freeze
  BADGES = { 'imported' => 'badge-success', 'unchanged' => 'badge-ghost', 'skipped' => 'badge-warning', 'error' => 'badge-error',
             'bad_source' => 'badge-error', 'interrupted' => 'badge-error', 'running' => 'badge-info' }.freeze
  COUNTS = %i[events_added events_changed events_removed events_skipped].freeze
  # The failed run's row and its error line read as one block: a tint and a bar down the left edge
  FAILED_ROW = '[&>td]:bg-red-50 [&>td:first-child]:shadow-[inset_4px_0_0_var(--color-error)]'

  def_delegator :@view, :admin_import_run_path

  def view_columns
    @view_columns ||= {
      started_at: { source: 'ImportRun.started_at', searchable: false, orderable: true },
      calendar: { source: 'Calendar.name', cond: :like, searchable: true, orderable: true },
      outcome: { source: 'ImportRun.outcome', searchable: false, orderable: false },
      importer: { source: 'ImportRun.importer', searchable: false, orderable: true },
      **COUNTS.index_with { |column| { source: "ImportRun.#{column}", searchable: false, orderable: true } },
      took: { source: 'ImportRun.finished_at', searchable: false, orderable: false }
    }
  end

  def data
    records.map do |run|
      row = {
        started_at: render_when(run),
        calendar: render_calendar(run.calendar),
        outcome: render_outcome(run),
        importer: ERB::Util.html_escape(importer_name(run.importer)),
        **COUNTS.index_with { |column| render_count(run, column) },
        took: render_took(run)
      }
      row.merge(failed?(run) ? { DT_RowClass: FAILED_ROW, DT_RowDetail: render_error(run) } : {})
    end
  end

  def get_raw_records
    runs = ImportRun.joins(:calendar).includes(:calendar)
    outcome = params.dig(:filter, :outcome)
    case outcome
    when nil, '' then runs
    when 'running' then runs.unfinished
    else runs.where(outcome: OUTCOME_GROUPS.fetch(outcome, outcome))
    end
  end

  def records_total_count
    ImportRun.count
  end

  private

  def failed?(run) = run.outcome.in?(OUTCOME_GROUPS['failed'])

  def outcome_key(run) = run.finished_at ? run.outcome.to_s : 'running'

  # The run's number links to its page, so a run can be named when talking about it
  def render_when(run)
    link = %(<a href="#{admin_import_run_path(run)}" class="text-xs font-mono text-gray-500 hover:text-orange-600">##{run.id}</a>)
    %(<div class="flex flex-col whitespace-nowrap">#{render_time_ago(run.started_at)}#{link}</div>).html_safe # rubocop:disable Rails/OutputSafety
  end

  def render_calendar(calendar)
    %(<a href="#{edit_admin_calendar_path(calendar)}" class="font-medium text-gray-900 hover:text-orange-600">#{ERB::Util.html_escape(calendar.name)}</a>).html_safe # rubocop:disable Rails/OutputSafety
  end

  def render_outcome(run)
    key = outcome_key(run)
    %(<span class="badge badge-sm whitespace-nowrap #{BADGES[key]}">#{ERB::Util.html_escape(I18n.t("admin.import_runs.outcomes.#{key}"))}</span>).html_safe # rubocop:disable Rails/OutputSafety
  end

  # Only an import changes events, so other runs show a dash rather than a row of zeros
  def render_count(run, column)
    return '<span class="text-gray-400">-</span>'.html_safe unless run.outcome == 'imported' # rubocop:disable Rails/OutputSafety

    %(<span class="tabular-nums">#{run.public_send(column)}</span>).html_safe # rubocop:disable Rails/OutputSafety
  end

  def render_took(run)
    return '' unless run.finished_at

    %(<span class="text-sm text-gray-600 whitespace-nowrap">#{ERB::Util.html_escape(ImportRun.duration_label(run.finished_at - run.started_at))}</span>).html_safe # rubocop:disable Rails/OutputSafety
  end

  def render_error(run)
    message = run.error.presence || I18n.t("admin.import_runs.default_errors.#{run.outcome}")
    %(<span class="block whitespace-normal break-words text-sm text-red-700">#{ERB::Util.html_escape(message)}</span>).html_safe # rubocop:disable Rails/OutputSafety
  end

  def importer_name(key)
    return '' if key.blank?

    parser = CalendarImporter::CalendarImporter.parser_for_key(key)
    parser ? parser::NAME : key.titleize
  end
end
