import { Controller } from "@hotwired/stimulus";

// Markdown preview controller for article body editing
// Provides live side-by-side markdown preview
export default class extends Controller {
	static targets = ["input", "output"];

	connect() {
		// Render initial preview if there's content
		this.renderPreview();
	}

	updatePreview() {
		this.renderPreview();
	}

	renderPreview() {
		const markdown = this.inputTarget.value;

		if (!markdown.trim()) {
			this.outputTarget.innerHTML =
				'<p class="text-base-content/50 italic">Start typing to see preview...</p>';
			return;
		}

		// Simple client-side markdown rendering
		// For full compatibility, we'd use a library like marked.js
		// This covers common cases for basic markdown
		let html = this.parseMarkdown(markdown);
		this.outputTarget.innerHTML = html;
	}

	parseMarkdown(text) {
		// Escape HTML first
		let html = text
			.replace(/&/g, "&amp;")
			.replace(/</g, "&lt;")
			.replace(/>/g, "&gt;");

		// Code blocks (fenced) - do this early to protect content
		html = html.replace(
			/```(\w*)\n([\s\S]*?)```/g,
			'<pre><code class="language-$1">$2</code></pre>'
		);

		// Inline code - protect from other processing
		const codeBlocks = [];
		html = html.replace(/`([^`]+)`/g, (match, code) => {
			codeBlocks.push(`<code>${code}</code>`);
			return `%%CODE${codeBlocks.length - 1}%%`;
		});

		// Headers
		html = html.replace(/^######\s+(.*)$/gm, "<h6>$1</h6>");
		html = html.replace(/^#####\s+(.*)$/gm, "<h5>$1</h5>");
		html = html.replace(/^####\s+(.*)$/gm, "<h4>$1</h4>");
		html = html.replace(/^###\s+(.*)$/gm, "<h3>$1</h3>");
		html = html.replace(/^##\s+(.*)$/gm, "<h2>$1</h2>");
		html = html.replace(/^#\s+(.*)$/gm, "<h1>$1</h1>");

		// Bold and italic
		html = html.replace(/\*\*\*(.+?)\*\*\*/g, "<strong><em>$1</em></strong>");
		html = html.replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>");
		html = html.replace(/\*(.+?)\*/g, "<em>$1</em>");
		html = html.replace(/___(.+?)___/g, "<strong><em>$1</em></strong>");
		html = html.replace(/__(.+?)__/g, "<strong>$1</strong>");
		html = html.replace(/_(.+?)_/g, "<em>$1</em>");

		// Images (before links to avoid conflicts)
		html = html.replace(
			/!\[([^\]]*)\]\(([^)]+)\)/g,
			'<img src="$2" alt="$1" class="max-w-full">'
		);

		// Markdown links
		html = html.replace(
			/\[([^\]]+)\]\(([^)]+)\)/g,
			'<a href="$2" target="_blank" rel="noopener" class="link text-placecal-teal">$1</a>'
		);

		// Auto-link bare URLs (not already in a tag)
		html = html.replace(
			/(?<!href="|">)(https?:\/\/[^\s<]+)/g,
			'<a href="$1" target="_blank" rel="noopener" class="link text-placecal-teal">$1</a>'
		);

		// Blockquotes
		html = html.replace(/^&gt;\s+(.*)$/gm, "<blockquote>$1</blockquote>");
		// Merge consecutive blockquotes
		html = html.replace(/<\/blockquote>\n<blockquote>/g, "<br>");

		// Horizontal rules
		html = html.replace(/^---+$/gm, "<hr>");
		html = html.replace(/^\*\*\*+$/gm, "<hr>");

		// Unordered lists
		html = html.replace(/^\s*[-*+]\s+(.*)$/gm, "<li>$1</li>");
		html = html.replace(/(<li>.*<\/li>)\n(?=<li>)/g, "$1");
		html = html.replace(/(<li>[\s\S]*?<\/li>)(?!\n<li>)/g, "<ul>$1</ul>");

		// Ordered lists
		html = html.replace(/^\s*\d+\.\s+(.*)$/gm, "<oli>$1</oli>");
		html = html.replace(/(<oli>.*<\/oli>)\n(?=<oli>)/g, "$1");
		html = html.replace(
			/(<oli>[\s\S]*?<\/oli>)(?!\n<oli>)/g,
			(match) =>
				"<ol>" +
				match.replace(/<\/?oli>/g, (m) => m.replace("oli", "li")) +
				"</ol>"
		);
		html = html.replace(/<\/?oli>/g, (m) => m.replace("oli", "li"));

		// Split into paragraphs by double newlines
		const blocks = html.split(/\n\n+/);
		html = blocks
			.map((block) => {
				block = block.trim();
				if (!block) return "";
				// Don't wrap block-level elements
				if (/^<(h[1-6]|ul|ol|li|blockquote|pre|hr|div|p)/.test(block)) {
					return block;
				}
				// Wrap text in paragraphs, converting single newlines to <br>
				return `<p>${block.replace(/\n/g, "<br>")}</p>`;
			})
			.join("\n");

		// Restore inline code blocks
		html = html.replace(/%%CODE(\d+)%%/g, (match, index) => codeBlocks[index]);

		return html;
	}
}
