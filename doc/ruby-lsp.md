# Ruby LSP Setup

[Ruby LSP](https://github.com/Shopify/ruby-lsp) provides Ruby intellisense (autocomplete, go-to-definition, inline docs) via the Language Server Protocol. It's built by Shopify and has first-class support for Rails and Phlex.

## What's included

- **ruby-lsp** — Ruby language server
- **ruby-lsp-rails** — Rails addon (model attributes, route helpers, etc.)
- **Phlex support** — Built-in via `phlex-rails` addon (go-to-definition, intellisense for components including Kit shorthand methods)

## Editor setup

### VS Code / VSCodium

Install the [Ruby LSP extension](https://marketplace.visualstudio.com/items?itemName=Shopify.ruby-lsp):

```
ext install Shopify.ruby-lsp
```

It should work out of the box after `bundle install`.

### Zed

Add to your Zed settings (`~/.config/zed/settings.json`):

```json
{
	"languages": {
		"Ruby": {
			"language_servers": ["ruby-lsp"]
		}
	}
}
```

### Vim / Neovim

With [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) (Neovim native LSP):

```lua
require('lspconfig').ruby_lsp.setup({})
```

With [coc.nvim](https://github.com/neoclide/coc.nvim), add to `:CocConfig`:

```json
{
	"languageserver": {
		"ruby-lsp": {
			"command": "ruby-lsp",
			"filetypes": ["ruby"],
			"rootPatterns": ["Gemfile"]
		}
	}
}
```

## First-time setup

Just run `bundle install` — no extra setup steps required. Ruby LSP uses the Prism parser and discovers addons (Rails, Phlex) automatically from your bundle.

## Phlex support

Works out of the box via the `phlex-rails` gem's built-in ruby-lsp addon. You get:

- Go-to-definition for Phlex components
- Intellisense for Kit shorthand methods (e.g. `Hero("title")`)
- Component prop completions

## Alternative: Solargraph

[Solargraph](https://solargraph.org/) is another Ruby language server. It's stronger for YARD-documented gems but has no Phlex plugin. If you prefer Solargraph, add `solargraph` and `solargraph-rails` to the development group in the Gemfile.

## Troubleshooting

- **Restart ruby-lsp** after changing the Gemfile (VS Code: `Cmd+Shift+P` → "Ruby LSP: Restart")
- **Warnings about missing gems** (e.g. `claude-on-rails`) are harmless — those are optional gems not installed locally
- **Addons not loading**: Check `ruby-lsp` output for addon discovery errors
