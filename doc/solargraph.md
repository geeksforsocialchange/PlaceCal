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

### Vim / Neovim

With [coc.nvim](https://github.com/neoclide/coc.nvim), add to `:CocConfig`:

```json
{
	"solargraph.useBundler": true,
	"solargraph.diagnostics": true,
	"solargraph.formatting": false
}
```

With [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) (Neovim native LSP):

```lua
require('lspconfig').solargraph.setup({
  cmd = { "bundle", "exec", "solargraph", "stdio" },
  settings = {
    solargraph = {
      diagnostics = true,
      formatting = false,
    },
  },
})
```

## First-time setup

After `bundle install`, run these two commands to give Solargraph full type information:

```bash
bundle exec yard gems              # YARD docs for gem dependencies
bundle exec rbs collection install  # RBS type definitions (Rails, ActiveRecord, etc.)
```

Re-run after adding new gems. The RBS collection config (`rbs_collection.yaml`) is checked into git but the downloaded types (`.gem_rbs_collection/`) are gitignored.

## Phlex support

Solargraph doesn't have a dedicated Phlex plugin, but it works well enough through YARD's type inference. The main limitation is that Kit shorthand methods (e.g. `Hero("title")`) won't autocomplete since they're dynamically defined. Use explicit `render Components::Hero.new("title")` if you need IDE navigation to the component class.

Phlex `prop` declarations are picked up as instance variables, so `@title` etc. will show their types if you add YARD annotations:

```ruby
# @return [String]
prop :title, String
```

### Alternative: ruby-lsp

[ruby-lsp](https://github.com/Shopify/ruby-lsp) is a separate language server from Shopify. Phlex has a **built-in ruby-lsp addon** (via `phlex-rails`) that provides go-to-definition and intellisense for Phlex components, including Kit shorthand methods. If Phlex support is a priority, ruby-lsp may be a better fit.

The two language servers can coexist — Solargraph is stronger for YARD-documented gems, while ruby-lsp has better support for gems with native addons (Phlex, Rails itself). See the [ruby-lsp docs](https://shopify.github.io/ruby-lsp/) for editor setup.

## Troubleshooting

- **Restart Solargraph** after changing `.solargraph.yml` (VS Code: `Cmd+Shift+P` → "Solargraph: Restart")
- **Warnings about missing gems** (e.g. `claude-on-rails`) are harmless — those are optional gems not installed locally
- **Slow first load** is normal — Solargraph indexes the entire project on startup
- **Missing Rails methods**: Make sure `solargraph-rails` plugin is listed in `.solargraph.yml`
