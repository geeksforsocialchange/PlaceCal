// Single entrypoint for both admin and public sites
// Loaded via importmap (no build step)

import "@hotwired/turbo-rails";
import { Application } from "@hotwired/stimulus";
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading";

// Start Stimulus
const application = Application.start();
application.debug = false;
window.Stimulus = application;

// Lazy load controllers — only fetched when data-controller appears in the DOM
lazyLoadControllersFrom("controllers", application);
