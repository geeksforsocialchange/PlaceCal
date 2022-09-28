# frozen_string_literal: true

json.array! @collections, partial: "collections/collection", as: :collection
