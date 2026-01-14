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

This project has a **multi-step asset build process**. Changes to JS or CSS require specific build commands:

### JavaScript (Stimulus controllers, etc.)

- **Source**: `app/javascript/controllers/*.js`
- **Output**: `app/assets/builds/admin.js`
- **Build command**: `yarn build`
- Assets are fingerprinted in production; restart Rails server to pick up changes in development

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

1. **JS changes not appearing**: Run `yarn build`, restart Rails server, hard refresh browser
2. **New Tailwind classes not working**: Run `yarn build:css:admin-tailwind`, hard refresh browser
3. **Browser caching**: Use `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows) for hard refresh
4. **Asset fingerprinting**: In development, restart Rails server after rebuilding assets
