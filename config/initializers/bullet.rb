# frozen_string_literal: true

# Bullet flags N+1 queries, unused eager loading, and missing counter caches
# during development. It's advisory here (logs + the in-page footer) rather than
# raising, so it never blocks work — read its warnings and add the missing
# `includes`/`preload`. See https://github.com/flyerhzm/bullet
if defined?(Bullet)
  Rails.application.config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true     # log/bullet.log
    Bullet.rails_logger = true      # also in the dev server log
    Bullet.add_footer = true        # small overlay in the page corner
    Bullet.n_plus_one_query_enable = true
    Bullet.unused_eager_loading_enable = true
  end
end
