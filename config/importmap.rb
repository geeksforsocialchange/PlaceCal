# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap
# Both admin and public interfaces use importmap-rails

# Single application entrypoint for both admin and public
pin 'application'

# Hotwired packages
# stimulus and stimulus-loading are provided by stimulus-rails gem assets
pin '@hotwired/stimulus', to: 'stimulus.min.js'
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js'
# turbo-rails from CDN (gem asset has compatibility issues with importmap)
pin '@hotwired/turbo-rails', to: 'https://cdn.jsdelivr.net/npm/@hotwired/turbo-rails@8.0.12/+esm'
pin '@hotwired/turbo', to: 'https://cdn.jsdelivr.net/npm/@hotwired/turbo@8.0.12/+esm'

# External dependencies
# Using esm.sh which auto-bundles sub-dependencies (sifter, unicode-variants)
pin 'tom-select', to: 'https://esm.sh/tom-select@2.4.3'
pin 'leaflet', to: 'https://esm.sh/leaflet@1.9.4'

# MapLibre GL for vector tile rendering with custom styles
pin 'maplibre-gl', to: 'https://esm.sh/maplibre-gl@4.7.1'
pin '@maplibre/maplibre-gl-leaflet', to: 'https://esm.sh/@maplibre/maplibre-gl-leaflet@0.0.22'

# Lodash (ES module version) - used by opening_times, partner_form_validation controllers
pin 'lodash', to: 'https://esm.sh/lodash-es@4.17.21'
pin 'lodash/isEqual', to: 'https://esm.sh/lodash-es@4.17.21/isEqual'
pin 'lodash/orderBy', to: 'https://esm.sh/lodash-es@4.17.21/orderBy'

# Stimulus controllers - pinned from app/javascript/controllers
pin_all_from 'app/javascript/controllers', under: 'controllers'

# Controller mixins - shared utilities for controllers
pin_all_from 'app/javascript/controllers/mixins', under: 'controllers/mixins'
