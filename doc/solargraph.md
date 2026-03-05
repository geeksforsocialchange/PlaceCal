# Solargraph Setup

[Solargraph](https://solargraph.org/) provides Ruby intellisense (autocomplete, go-to-definition, inline docs, type checking) via the Language Server Protocol. It works with VS Code, VSCodium, Zed, and other LSP-compatible editors.

## What's included

- **solargraph** — Ruby language server
- **solargraph-rails** — Plugin that reads `db/schema.rb` for ActiveRecord model attributes, adds route helpers, etc.
- **.solargraph.yml** — Project config (checked into git so all devs share the same setup)

## Editor setup

### VS Code / VSCodium

Install the [Ruby Solargraph extension](https://marketplace.visualstudio.com/items?itemName=castwide.solargraph):

```
ext install castwide.solargraph
```

Recommended `settings.json` additions:

```json
{
	"solargraph.diagnostics": true,
	"solargraph.formatting": false,
	"solargraph.useBundler": true
}
```

Setting `useBundler: true` ensures Solargraph uses the project's bundled version rather than a globally installed gem.

### Zed

Zed has built-in Ruby LSP support. Add to your Zed settings (`~/.config/zed/settings.json`):

```json
{
	"languages": {
		"Ruby": {
			"language_servers": ["solargraph"]
		}
	},
	"lsp": {
		"solargraph": {
			"initialization_options": {
				"diagnostics": true,
				"formatting": false,
				"useBundler": true
			}
		}
	}
}
```

## First-time setup

After `bundle install`, generate the YARD documentation cache for your gems:

```bash
bundle exec yard gems
```

This gives Solargraph type information for all your dependencies. Re-run after adding new gems.

## Phlex support

Solargraph doesn't have a dedicated Phlex plugin, but it works well enough through YARD's type inference. The main limitation is that Kit shorthand methods (e.g. `Hero("title")`) won't autocomplete since they're dynamically defined. Use explicit `render Components::Hero.new("title")` if you need IDE navigation to the component class.

Phlex `prop` declarations are picked up as instance variables, so `@title` etc. will show their types if you add YARD annotations:

```ruby
# @return [String]
prop :title, String
```

## Troubleshooting

- **Restart Solargraph** after changing `.solargraph.yml` (VS Code: `Cmd+Shift+P` → "Solargraph: Restart")
- **Warnings about missing gems** (e.g. `claude-on-rails`) are harmless — those are optional gems not installed locally
- **Slow first load** is normal — Solargraph indexes the entire project on startup
- **Missing Rails methods**: Make sure `solargraph-rails` plugin is listed in `.solargraph.yml`
