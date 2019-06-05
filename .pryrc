Pry.config.editor = proc { |file, line| "atom --wait +#{line} #{file}" }
