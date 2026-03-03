# frozen_string_literal: true

class Views::Collections::Index < Views::Base
  prop :collections, _Any, reader: :private

  def view_template
    p(id: 'notice') { view_context.notice }

    h1 { 'Collections' }

    table do
      thead do
        tr do
          th { 'Name' }
          th { 'Description' }
          th(colspan: '3')
        end
      end

      tbody do
        collections.each do |collection|
          tr do
            td { collection.name }
            td { collection.description }
            td { link_to 'Show', collection }
            td { link_to 'Edit', edit_collection_path(collection) }
            td { link_to 'Destroy', collection, data: { turbo_method: :delete, turbo_confirm: 'Are you sure?' } }
          end
        end
      end
    end

    br

    link_to 'New Collection', new_collection_path
  end
end
