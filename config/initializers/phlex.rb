# frozen_string_literal: true

# Configure Phlex namespaces for Zeitwerk autoloading.
#
# Views (full-page renders from controllers):
#   app/views/base.rb => Views::Base
#   app/views/articles/index.rb => Views::Articles::Index
#
# Components (reusable UI pieces):
#   app/components/base.rb => Components::Base
#   app/components/admin/alert.rb => Components::Admin::Alert

module Views; end

module Components
  extend Phlex::Kit

  # Kit names from before components were namespaced; theme gems still call them.
  LEGACY_KIT_NAMES = {
    Address: 'Shared::Address', ContactDetails: 'Shared::ContactDetails', Flash: 'Shared::Flash',
    Hero: 'Shared::Hero', Map: 'Shared::Map', Navigation: 'Shared::Navigation',
    Breadcrumb: 'Sites::Breadcrumb', Event: 'Sites::Event', EventFilter: 'Sites::EventFilter',
    EventList: 'Sites::EventList', Filter: 'Sites::Filter', Footer: 'Sites::Footer',
    HelpCard: 'Sites::HelpCard', HeroSection: 'Sites::HeroSection', Meta: 'Sites::Meta',
    PartnerFilter: 'Sites::PartnerFilter', PartnerPreview: 'Sites::PartnerPreview',
    Profile: 'Sites::Profile', Timeline: 'Sites::Timeline'
  }.freeze

  LEGACY_KIT_NAMES.each do |name, target|
    define_method(name) do |*args, **kwargs, &block|
      # A section kit's own component of this name (Admin::Flash, Directory::Hero) wins.
      kit = self.class.ancestors.find { |mod| mod.singleton_class.include?(Phlex::Kit) && mod != Components && mod.const_defined?(name, false) }
      constant = kit ? kit.const_get(name) : Components.const_get(target)
      render(constant.new(*args, **kwargs), &block)
    end
  end
end

Rails.autoloaders.main.push_dir(
  Rails.root.join('app/views'),
  namespace: Views
)

Rails.autoloaders.main.push_dir(
  Rails.root.join('app/components'),
  namespace: Components
)
