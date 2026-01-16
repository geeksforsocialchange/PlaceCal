// Admin interface entrypoint - loaded via importmap (no build step)
// This replaces the old esbuild bundle for the admin interface
// See config/importmap.rb for package pins

import "@hotwired/turbo-rails";

// Import Stimulus application and load all controllers from importmap
import { application } from "controllers/application";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";

// Eager load all controllers defined in the import map under controllers/**/*_controller
// This parses the importmap and dynamically imports each controller
eagerLoadControllersFrom("controllers", application);
