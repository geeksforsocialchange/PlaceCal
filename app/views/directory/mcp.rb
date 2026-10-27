# frozen_string_literal: true

# What a person sees on opening the MCP server's address in a browser.
class Views::Directory::Mcp < Views::Base
  T = 'directory.pages.mcp'

  prop :server_url, String

  def view_template
    content_for(:title) { t("#{T}.heading") }

    Directory::PageHero(breadcrumb_label: t("#{T}.heading"), kicker: t("#{T}.heading"),
                        title: t("#{T}.hero_title"), subtitle: t("#{T}.hero_lede"))

    div(class: 'container-public py-8 flex flex-col gap-8') do
      render_address
      Directory::MarkdownContent(slug: 'mcp')
    end
  end

  private

  def render_address
    section(class: 'max-w-(--width-prose-lg)', data: { controller: 'copy', copy_copied_label_value: t("#{T}.copied") }) do
      label(for: 'mcp-server-url', class: 'allcaps-label text-tertiary block mb-2') { t("#{T}.address_label") }
      div(class: 'flex gap-2') do
        input(id: 'mcp-server-url', type: 'text', readonly: true, value: @server_url,
              class: 'flex-1 min-w-0 rounded-card border border-rules bg-background px-4 py-3 font-mono text-foreground',
              data: { copy_target: 'source' })
        UI::Button(variant: :outline, data: { copy_target: 'button', action: 'copy#copy' }) { t("#{T}.copy") }
      end
    end
  end
end
