//= link_tree ../fonts
//= link_tree ../images

// Public site CSS (compiled by Sprockets from SCSS)
//= link application.css

// NOTE: admin_tailwind.css is built directly to public/assets/ by Tailwind CLI
// to bypass Sprockets/Sass processing (which fails on modern CSS syntax)

// Site-specific stylesheets (compiled via Sprockets)
//= link home.css
//= link_directory ../stylesheets/themes .css
//= link_directory ../stylesheets/themes/custom .css
//= link print.css

// JavaScript for public site (esbuild bundle from app/assets/builds)
// NOTE: This resolves to app/assets/builds/application.js first due to asset path order
//= link application.js

// JavaScript files for importmap (admin interface)
// These are served directly via Sprockets as ES modules
//= link admin.js
//= link_tree ../../javascript/controllers .js

// Vendor JavaScript for importmap
//= link_tree ../../../vendor/javascript .js
