# frozen_string_literal: true

# Keeps a user-entered slug on the in-memory record when validation fails.
#
# FriendlyId installs an `after_validation :unset_slug_if_invalid` callback that
# reverts the slug back to its previous value whenever the slug attribute itself
# is invalid (for example a duplicate slug). On a form round-trip that means the
# value the user typed is silently replaced with the old slug, so when the form
# is re-rendered after a failed save the user's input appears to have been lost
# (see issue #2358).
#
# We never persist on a failed validation, so reverting the slug only affects the
# unsaved object that gets handed back to the view. Suppressing the revert lets
# the form show what the user actually entered alongside the validation error.
#
# The override is prepended, so it shadows FriendlyId's `Slugged#unset_slug_if_invalid`
# regardless of whether `friendly_id ... use: :slugged` runs before or after this
# concern is included.
module SlugRetainable
  extend ActiveSupport::Concern

  module Override
    private

    # Override FriendlyId's revert behaviour: retain the user-entered slug so it
    # is preserved across a validation-failure re-render.
    def unset_slug_if_invalid
      # no-op: keep the submitted slug for the form round-trip
    end
  end

  included do
    prepend Override
  end
end
