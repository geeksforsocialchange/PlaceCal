# frozen_string_literal: true

namespace :data do
  desc 'Fix fields that need to be rendered to HTML'
  task render_html_fields: :environment do
    PaperTrail.enabled = false

    @bad_count = 0

    fix_model Article do |article|
      article.author.present?
    end

    fix_model Site
    fix_model Partner

    fix_model Event do |event|
      next if event.description_html.to_s.length > 0

      description_text = Kramdown::Document.new(event.description.to_s, input: 'html').to_kramdown.strip
      event.description = description_text

      event.partner.present?
    end

    puts "done. there were #{@bad_count} bad records that did not save"
  end

  def fix_model(model)
    # model.transaction do
    if true
      model.record_timestamps = false
      puts "#{model}s (#{model.count})..."
      model.find_each do |record|
        puts "  #{record.id}"
        record.force_html_generation!

        saved = false
        if block_given?
          saved = record.save if yield(record)

        else
          saved = record.save
        end

        @bad_count += 1 unless saved
      end
    end
  end
end
