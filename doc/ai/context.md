# AI Agents Context

This project optionally supports AI coding assistants with specialized agents for Rails development.

## Project Information

- **Rails Version**: 7.2.3
- **Ruby Version**: 3.3.6
- **Project Type**: Full-stack Rails
- **Test Framework**: RSpec
- **GraphQL**: Enabled
- **Turbo/Stimulus**: Enabled

## Swarm Configuration

The agents-swarm.yml file defines specialized agents for different aspects of Rails development:

- Each agent has specific expertise and works in designated directories
- Agents collaborate to implement features across all layers
- The architect agent coordinates the team

## Development Guidelines

When working on this project:

- Follow Rails conventions and best practices
- Write tests for all new functionality
- Use strong parameters in controllers
- Keep models focused with single responsibilities
- Extract complex business logic to service objects
- Ensure proper database indexing for foreign keys and queries

## Asset Pipeline

This project uses a **hybrid asset strategy**:

- **Admin interface**: importmap-rails (native ES modules, no build step)
- **Public site**: esbuild bundle (jQuery legacy components)

### Admin JavaScript (importmap-rails)

- **Source**: `app/javascript/controllers/*.js`
- **Configuration**: `config/importmap.rb`
- **No build step required** - changes take effect on browser refresh
- External dependencies (tom-select, leaflet) are loaded from CDN
- Stimulus controllers are auto-loaded via `eagerLoadControllersFrom()`

### Public Site JavaScript (esbuild)

- **Source**: `app/javascript/application.js`
- **Output**: `app/assets/builds/application.js`
- **Build command**: `yarn build`
- Includes jQuery and legacy components (breadcrumb, navigation, paginator)

### Tailwind CSS (Admin interface)

- **Source**: `app/tailwind/admin_tailwind.css`
- **Output**: `public/assets/admin_tailwind.css`
- **Build command**: `yarn build:css:admin-tailwind`
- Referenced directly via `<link>` tag in `app/views/layouts/admin/application.html.erb`
- New Tailwind classes only work after rebuilding CSS (Tailwind scans templates)

### SCSS (Public site)

- **Source**: `app/assets/stylesheets/application.scss`
- **Output**: `app/assets/builds/application.css`
- **Build command**: `yarn build:css`

### Rebuilding Everything

```bash
yarn build:all  # Runs: yarn build && yarn build:css && yarn build:css:admin-tailwind
```

### Common Issues

1. **Admin JS changes not appearing**: Just refresh browser (no build needed)
2. **Public JS changes not appearing**: Run `yarn build`, restart Rails server, hard refresh browser
3. **New Tailwind classes not working**: Run `yarn build:css:admin-tailwind`, hard refresh browser
4. **Browser caching**: Use `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows) for hard refresh

### Development Workflow

When running `bin/dev`, the Procfile.dev starts watchers for public JS and Tailwind CSS. Admin JS doesn't need a watcher since it uses importmap.

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
