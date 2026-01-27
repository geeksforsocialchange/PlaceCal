// Single entrypoint for both admin and public sites
// Loaded via importmap (no build step)

import "@hotwired/turbo-rails";
import { Application } from "@hotwired/stimulus";
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";

// Start Stimulus
const application = Application.start();
application.debug = false;
window.Stimulus = application;

// Eager load all controllers from the importmap
eagerLoadControllersFrom("controllers", application);
