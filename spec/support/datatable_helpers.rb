# frozen_string_literal: true

# Shared helpers for datatable request specs
module DatatableHelpers
  extend ActiveSupport::Concern

  included do
    let(:admin_host) { "admin.lvh.me" }
  end

  # Build datatable column params from an array of column definitions
  # @param columns [Array<Hash>] Array of column definitions with :data, :searchable (default false), :orderable (default false)
  # @return [Hash] DataTables-formatted columns hash
  def build_datatable_columns(columns)
    columns.each_with_index.to_h do |col, idx|
      [
        idx.to_s,
        {
          "data" => col[:data].to_s,
          "name" => col[:data].to_s,
          "searchable" => (col[:searchable] || false).to_s,
          "orderable" => (col[:orderable] || false).to_s,
          "search" => { "value" => "", "regex" => "false" }
        }
      ]
    end
  end

  # Build base datatable request params
  # @param columns [Array<Hash>] Column definitions
  # @param default_sort_column [Integer] Index of default sort column (default 0)
  # @param default_sort_dir [String] Default sort direction (default "desc")
  # @return [Hash] Base params for datatable request
  def build_datatable_params(columns:, default_sort_column: 0, default_sort_dir: "desc")
    {
      "draw" => "1",
      "start" => "0",
      "length" => "25",
      "search" => { "value" => "", "regex" => "false" },
      "columns" => build_datatable_columns(columns),
      "order" => { "0" => { "column" => default_sort_column.to_s, "dir" => default_sort_dir } }
    }
  end

  # Shared examples for basic datatable functionality
  module SharedExamples
    extend ActiveSupport::Concern

    included do
      shared_examples "datatable JSON structure" do
        it "returns JSON with datatable structure" do
          datatable_request

          expect(response).to have_http_status(:success)
          json = response.parsed_body
          expect(json).to have_key("draw")
          expect(json).to have_key("recordsTotal")
          expect(json).to have_key("recordsFiltered")
          expect(json).to have_key("data")
        end
      end

      shared_examples "datatable search" do |search_field:, matching_value:, non_matching_value:|
        it "filters by search term" do
          datatable_request("search" => { "value" => matching_value })

          json = response.parsed_body
          values = json["data"].map { |d| d[search_field.to_s] }
          expect(values.join).to include(matching_value)
          expect(values.join).not_to include(non_matching_value)
        end

        it "search is case insensitive" do
          datatable_request("search" => { "value" => matching_value.upcase })

          json = response.parsed_body
          values = json["data"].map { |d| d[search_field.to_s] }
          expect(values.join).to include(matching_value)
        end
      end

      shared_examples "datatable sorting" do |column_index:, field:, first_value:, last_value:|
        it "sorts ascending" do
          datatable_request("order" => { "0" => { "column" => column_index.to_s, "dir" => "asc" } })

          json = response.parsed_body
          values = json["data"].map { |d| d[field.to_s] }
          expect(values.join).to match(/#{Regexp.escape(first_value)}.*#{Regexp.escape(last_value)}/m)
        end

        it "sorts descending" do
          datatable_request("order" => { "0" => { "column" => column_index.to_s, "dir" => "desc" } })

          json = response.parsed_body
          values = json["data"].map { |d| d[field.to_s] }
          expect(values.join).to match(/#{Regexp.escape(last_value)}.*#{Regexp.escape(first_value)}/m)
        end
      end

      shared_examples "datatable yes/no filter" do |filter_name:, field:, yes_value:, no_value:|
        it "filters with 'yes' value" do
          datatable_request("filter" => { filter_name => "yes" })

          json = response.parsed_body
          values = json["data"].map { |d| d[field.to_s] }
          expect(values.join).to include(yes_value)
          expect(values.join).not_to include(no_value)
        end

        it "filters with 'no' value" do
          datatable_request("filter" => { filter_name => "no" })

          json = response.parsed_body
          values = json["data"].map { |d| d[field.to_s] }
          expect(values.join).to include(no_value)
          expect(values.join).not_to include(yes_value)
        end
      end

      shared_examples "datatable renders relative time" do |field:|
        it "renders updated_at as relative time" do
          datatable_request

          json = response.parsed_body
          expect(json["data"].first[field.to_s]).to include("Today")
        end
      end

      shared_examples "datatable renders edit button" do
        it "renders actions with edit button" do
          datatable_request

          json = response.parsed_body
          expect(json["data"].first["actions"]).to include("Edit")
          expect(json["data"].first["actions"]).to include("href=")
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include DatatableHelpers, type: :request
  config.include DatatableHelpers::SharedExamples, type: :request
end
