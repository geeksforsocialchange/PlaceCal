# AI Agents Context

This project optionally supports AI coding assistants with specialized agents for Rails development.

## Project Information

- **Rails Version**: 8.x
- **Ruby Version**: 3.3.6
- **Project Type**: Full-stack Rails
- **Test Framework**: RSpec
- **GraphQL**: Enabled
- **Turbo/Stimulus**: Enabled

## Development Guidelines

When working on this project:

- Follow Rails conventions and best practices
- Write tests for all new functionality
- Use strong parameters in controllers
- Keep models focused with single responsibilities
- Extract complex business logic to service objects (e.g., `app/queries/`)
- Ensure proper database indexing for foreign keys and queries

## Asset Pipeline

### JavaScript (importmap-rails)

Both admin and public interfaces use **importmap-rails** with native ES modules (no build step required).

- **Entrypoint**: `app/javascript/application.js`
- **Controllers**: `app/javascript/controllers/*.js`
- **Controller mixins**: `app/javascript/controllers/mixins/*.js`
- **Configuration**: `config/importmap.rb`
- Changes take effect on browser refresh (no build needed)
- External dependencies loaded from CDN (esm.sh, jsdelivr):
  - `tom-select` - Enhanced select inputs
  - `leaflet` - Map rendering
  - `maplibre-gl` - Vector tile map styling
  - `@hotwired/turbo-rails` - Turbo Drive/Frames/Streams
- Stimulus controllers are shared between admin and public sites
- No lodash or jQuery - use native JS instead

### Tailwind CSS (Admin interface)

- **Source**: `app/tailwind/admin_tailwind.css`
- **Output**: `public/assets/admin_tailwind.css`
- **Build command**: `yarn build` (or `yarn css-admin`)
- Referenced directly via `<link>` tag in `app/views/layouts/admin/application.html.erb`
- New Tailwind classes only work after rebuilding CSS (Tailwind scans templates)

### SCSS (Public site)

- **Source**: `app/assets/stylesheets/application.scss`
- **Vendor CSS**: `vendor/assets/stylesheets/` (e.g., maplibre-gl.css)
- Processed by Sprockets (no separate build command)

### Common Issues

1. **JS changes not appearing**: Just refresh browser (no build needed for JS)
2. **New Tailwind classes not working**: Run `yarn build`, hard refresh browser
3. **Browser caching**: Use `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows) for hard refresh

### Development Workflow

When running `bin/dev`, the Procfile.dev starts a watcher for Tailwind CSS. JavaScript doesn't need a watcher since it uses importmap.

## Tailwind CSS Best Practices

### Component Classes vs Utility Classes

For reusable UI patterns with hover/focus states, **create component classes** in `app/tailwind/_components.css` instead of relying on JIT-generated utility classes:

```css
/* Good: Reliable, always generated */
.btn-clear-filters {
  @apply inline-flex items-center gap-1.5 px-2.5 py-1.5;
  @apply bg-gray-100 text-gray-600 border border-gray-300;
}
.btn-clear-filters:hover {
  @apply bg-red-50 text-red-600;
}

/* Avoid: JIT classes may not be generated if not scanned */
class="hover:bg-red-50 hover:text-red-600"
```

### Stimulus Controller Visibility Toggling

When toggling element visibility in Stimulus controllers, prefer `style.display` over `classList.toggle("hidden")` when using flexbox:

```javascript
// Good: Works reliably with inline-flex
element.style.display = visible ? "inline-flex" : "none";

// Problematic: CSS specificity issues with Tailwind's hidden class
element.classList.toggle("hidden", !visible);
```
