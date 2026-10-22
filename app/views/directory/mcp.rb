# frozen_string_literal: true

# What a person sees on opening the MCP server's address in a browser.
class Views::Directory::Mcp < Views::Base
  T = 'directory.pages.mcp'

  prop :server_url, String

  def view_template
    content_for(:title) { t("#{T}.heading") }

    Directory::PageHero(breadcrumb_label: t("#{T}.heading"), kicker: t("#{T}.heading"),
                        title: t("#{T}.hero_title"), subtitle: t("#{T}.hero_lede"))

    div(class: 'mx-auto max-w-[820px] px-6 pt-11 pb-12 flex flex-col gap-10') do
      render_address
      render_connect
      render_examples
      p(class: 'my-0 text-tertiary') do
        raw safe(t("#{T}.developers_html", link: view_context.link_to(t("#{T}.developers_link"), '/llms.txt', class: 'with-no-sass underline')))
      end
    end
  end

  private

  def render_address
    section(data: { controller: 'copy', copy_copied_label_value: t("#{T}.copied") }) do
      label(for: 'mcp-server-url', class: 'allcaps-label text-tertiary block mb-2') { t("#{T}.address_label") }
      div(class: 'flex gap-2') do
        input(id: 'mcp-server-url', type: 'text', readonly: true, value: @server_url,
              class: 'flex-1 min-w-0 rounded-card border border-rules bg-background px-4 py-3 font-mono text-foreground',
              data: { copy_target: 'source' })
        button(type: 'button', class: 'btn-primary-outline cursor-pointer', data: { copy_target: 'button', action: 'copy#copy' }) { t("#{T}.copy") }
      end
    end
  end

  def render_connect
    section do
      h2(class: 'font-serif font-regular text-section text-foreground mt-0 mb-4') { t("#{T}.connect_heading") }
      ul(class: 'my-0 pl-5 list-disc flex flex-col gap-3 text-foreground leading-[1.6]') do
        li { raw safe(t("#{T}.chatgpt_html")) }
        li { raw safe(t("#{T}.claude_html")) }
        li { raw safe(t("#{T}.gemini_html")) }
        li { t("#{T}.others") }
      end
    end
  end

  def render_examples
    section do
      h2(class: 'font-serif font-regular text-section text-foreground mt-0 mb-4') { t("#{T}.try_heading") }
      ul(class: 'my-0 pl-0 list-none flex flex-col gap-2 text-foreground italic') do
        t("#{T}.examples").each { |example| li { example } }
      end
    end
  end
end
