//= link_tree ../fonts
//= link_tree ../images

// Public site CSS (pre-built by Dart Sass into app/assets/builds/)
//= link_tree ../builds .css

// NOTE: admin_tailwind.css is built directly to public/assets/ by Tailwind CLI
// to bypass Sprockets/Sass processing (which fails on modern CSS syntax)

// JavaScript files for importmap
// These are served directly via Sprockets as ES modules
//= link application.js
//= link_tree ../../javascript/controllers .js

// Vendor JavaScript for importmap
//= link_tree ../../../vendor/javascript .js
