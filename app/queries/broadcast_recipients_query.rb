# frozen_string_literal: true

# Resolves who receives a broadcast (#3256 phase 4). Scoped by partnership
# now; neighbourhood and site scopes are planned extensions from #1440 and
# should slot in as additional initializer arguments — keep resolution here
# so they stay additive.
#
# `users` is everyone the scope reaches; `eligible` filters through the
# partnership_updates opt-in. The difference is surfaced to the sender so
# the consent filter is visible, not silent.
class BroadcastRecipientsQuery
  def initialize(partnership:)
    @partnership = partnership
  end

  # @return [Array<User>] all admins of partners in scope
  def users
    @users ||= User.joins(partners: :partner_tags)
                   .where(partner_tags: { tag_id: @partnership.id })
                   .distinct
                   .order(:id)
                   .to_a
  end

  # @return [Array<User>] those who have opted in to partnership_updates
  def eligible
    @eligible ||= EmailSubscription.subscribed_users(users, :partnership_updates)
  end

  # @return [Integer] reachable people excluded for lack of consent
  def excluded_count
    users.size - eligible.size
  end

  # @return [Integer] partners covered by the scope
  def partners_count
    @partnership.partners.distinct.count
  end
end
