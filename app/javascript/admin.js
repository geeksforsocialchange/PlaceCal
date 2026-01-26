// Admin interface entrypoint - loaded via importmap (no build step)
// This replaces the old esbuild bundle for the admin interface
// See config/importmap.rb for package pins

import "@hotwired/turbo-rails";

// Import Stimulus application and all controllers
// The index.js file explicitly registers all controllers
import "controllers";
