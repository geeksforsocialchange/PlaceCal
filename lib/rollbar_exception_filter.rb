# frozen_string_literal: true

module RollbarExceptionFilter
  module_function

  IGNORABLE_PATHS = [
    # originals
    %r{\A/old},
    %r{\A/gate\.php},
    %r{\A/wp-includes},
    %r{\A/mifs},
    %r{\A/vendor},
    %r{\A/epa},

    # GFSC specific
    %r{\A/radio.php\z},
    %r{\A/partner/x\z},
    %r{\A/wordpress},
    %r{\A/assets/}
  ].freeze

  def muffle_routing_error(error)
    error.message =~ /No route matches \[[A-Z]+\] "(.+)"/
    path = Regexp.last_match(1).to_s.downcase

    found = IGNORABLE_PATHS.find { |regex| regex.match(path) }

    found.present? ? 'ignore' : 'warning'
  end
end
