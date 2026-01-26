// Public site entrypoint - loaded via importmap (no build step)
// See config/importmap.rb for package pins

import "@hotwired/turbo-rails";

// Import Stimulus application and all controllers
// Controllers are shared between admin and public sites
import "controllers";
