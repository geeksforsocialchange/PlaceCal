## AI Agent Configuration

This file configures AI coding assistants for PlaceCal. Review the context file at @doc/ai/context.md

## Development URLs

The admin interface uses a subdomain. Access it at:

- **Admin**: http://admin.lvh.me:3000
- **Public site**: http://lvh.me:3000

Note: `lvh.me` resolves to localhost but allows subdomain routing to work.

## Development Server

You can restart the dev server whenever needed without prompting. Use:

```bash
pkill -9 -f "rails|puma|foreman" 2>/dev/null
rm -rf tmp/cache/assets  # if asset issues
bin/dev > /tmp/placecal-dev.log 2>&1 &
```
