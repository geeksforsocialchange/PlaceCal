import { Controller } from "@hotwired/stimulus";

// Markdown preview controller for article body editing
// Provides live side-by-side markdown preview with formatting toolbar
export default class extends Controller {
	static targets = [
		"input",
		"output",
		"toolbar",
		"container",
		"editorPane",
		"previewPane",
		"resizer",
	];

	connect() {
		// Render initial preview if there's content
		this.renderPreview();

		// Bind resize handlers
		this.handleResize = this.handleResize.bind(this);
		this.stopResize = this.stopResize.bind(this);

		// Initialize undo stack for toolbar actions
		this.undoStack = [];
		this.redoStack = [];
	}

	disconnect() {
		// Clean up resize listeners
		document.removeEventListener("mousemove", this.handleResize);
		document.removeEventListener("mouseup", this.stopResize);
	}

	// Resizable panes
	startResize(event) {
		event.preventDefault();
		this.isResizing = true;
		this.startX = event.clientX;
		this.startEditorWidth = this.editorPaneTarget.offsetWidth;
		this.containerWidth = this.containerTarget.offsetWidth;

		document.addEventListener("mousemove", this.handleResize);
		document.addEventListener("mouseup", this.stopResize);

		// Prevent text selection while resizing
		document.body.style.userSelect = "none";
		document.body.style.cursor = "col-resize";
	}

	handleResize(event) {
		if (!this.isResizing) return;

		const delta = event.clientX - this.startX;
		const newEditorWidth = this.startEditorWidth + delta;

		// Calculate percentage (accounting for resizer width of 16px)
		const availableWidth = this.containerWidth - 16;
		const minWidth = 256; // min-w-64 = 16rem = 256px

		// Clamp the editor width
		const clampedWidth = Math.max(
			minWidth,
			Math.min(newEditorWidth, availableWidth - minWidth)
		);
		const editorPercent = (clampedWidth / availableWidth) * 100;

		this.editorPaneTarget.style.flex = `0 0 ${editorPercent}%`;
		this.previewPaneTarget.style.flex = `0 0 ${100 - editorPercent}%`;
	}

	stopResize() {
		this.isResizing = false;
		document.removeEventListener("mousemove", this.handleResize);
		document.removeEventListener("mouseup", this.stopResize);

		document.body.style.userSelect = "";
		document.body.style.cursor = "";
	}

	updatePreview() {
		this.renderPreview();
	}

	// Keyboard shortcuts
	handleKeydown(event) {
		if ((event.ctrlKey || event.metaKey) && event.key === "b") {
			event.preventDefault();
			this.insertBold();
		} else if ((event.ctrlKey || event.metaKey) && event.key === "i") {
			event.preventDefault();
			this.insertItalic();
		} else if ((event.ctrlKey || event.metaKey) && event.key === "k") {
			event.preventDefault();
			this.insertLink();
		} else if ((event.ctrlKey || event.metaKey) && event.key === "z") {
			if (event.shiftKey) {
				// Cmd+Shift+Z = Redo
				if (this.redoStack.length > 0) {
					event.preventDefault();
					this.redo();
				}
			} else {
				// Cmd+Z = Undo
				if (this.undoStack.length > 0) {
					event.preventDefault();
					this.undo();
				}
				// If no toolbar actions to undo, let browser handle native undo
			}
		}
	}

	// Toolbar actions
	insertBold() {
		this.wrapSelection("**", "**", "bold text");
	}

	insertItalic() {
		this.wrapSelection("*", "*", "italic text");
	}

	insertLink() {
		const selection = this.getSelection();
		const url = "https://";
		if (selection) {
			this.replaceSelection(`[${selection}](${url})`);
			// Position cursor inside the URL
			const start = this.inputTarget.selectionStart - url.length - 1;
			this.inputTarget.setSelectionRange(start, start + url.length);
		} else {
			this.replaceSelection(`[link text](${url})`);
			// Select "link text" for easy replacement
			const end = this.inputTarget.selectionStart;
			const start = end - `[link text](${url})`.length + 1;
			this.inputTarget.setSelectionRange(start, start + 9);
		}
		this.inputTarget.focus();
	}

	insertH2() {
		this.insertAtLineStart("## ", "Heading");
	}

	insertH3() {
		this.insertAtLineStart("### ", "Heading");
	}

	insertBulletList() {
		this.insertAtLineStart("- ", "List item");
	}

	insertBlockquote() {
		this.insertAtLineStart("> ", "Quote");
	}

	insertCode() {
		const selection = this.getSelection();
		if (selection && selection.includes("\n")) {
			// Multi-line: use code fence
			this.wrapSelection("```\n", "\n```", "code");
		} else {
			// Single line: use inline code
			this.wrapSelection("`", "`", "code");
		}
	}

	// Helper methods
	getSelection() {
		const start = this.inputTarget.selectionStart;
		const end = this.inputTarget.selectionEnd;
		return this.inputTarget.value.substring(start, end);
	}

	wrapSelection(before, after, placeholder) {
		const start = this.inputTarget.selectionStart;
		const end = this.inputTarget.selectionEnd;
		const selection = this.inputTarget.value.substring(start, end);
		const text = selection || placeholder;

		this.replaceSelection(`${before}${text}${after}`);

		// Select the text (not the wrapper)
		const newStart = start + before.length;
		const newEnd = newStart + text.length;
		this.inputTarget.setSelectionRange(newStart, newEnd);
		this.inputTarget.focus();
	}

	replaceSelection(text) {
		const input = this.inputTarget;
		const start = input.selectionStart;
		const end = input.selectionEnd;
		const value = input.value;

		// Save state for undo
		this.undoStack.push({
			value: value,
			selectionStart: start,
			selectionEnd: end,
		});
		this.redoStack = []; // Clear redo stack on new action

		// Perform the replacement
		input.value = value.substring(0, start) + text + value.substring(end);

		// Position cursor after inserted text
		const newPos = start + text.length;
		input.setSelectionRange(newPos, newPos);

		// Trigger preview update
		this.updatePreview();
	}

	undo() {
		if (this.undoStack.length === 0) return;

		const input = this.inputTarget;

		// Save current state for redo
		this.redoStack.push({
			value: input.value,
			selectionStart: input.selectionStart,
			selectionEnd: input.selectionEnd,
		});

		// Restore previous state
		const state = this.undoStack.pop();
		input.value = state.value;
		input.setSelectionRange(state.selectionStart, state.selectionEnd);
		input.focus();

		this.updatePreview();
	}

	redo() {
		if (this.redoStack.length === 0) return;

		const input = this.inputTarget;

		// Save current state for undo
		this.undoStack.push({
			value: input.value,
			selectionStart: input.selectionStart,
			selectionEnd: input.selectionEnd,
		});

		// Restore redo state
		const state = this.redoStack.pop();
		input.value = state.value;
		input.setSelectionRange(state.selectionStart, state.selectionEnd);
		input.focus();

		this.updatePreview();
	}

	insertAtLineStart(prefix, placeholder) {
		const input = this.inputTarget;
		const start = input.selectionStart;
		const end = input.selectionEnd;
		const value = input.value;

		// Save state for undo
		this.undoStack.push({
			value: value,
			selectionStart: start,
			selectionEnd: end,
		});
		this.redoStack = []; // Clear redo stack on new action

		// Find the start of the current line
		let lineStart = start;
		while (lineStart > 0 && value[lineStart - 1] !== "\n") {
			lineStart--;
		}

		const selection = this.getSelection();
		const text = selection || placeholder;
		const insertText = prefix + text;

		// Perform the replacement
		input.value =
			value.substring(0, lineStart) + insertText + value.substring(end);

		// Position cursor to select the text portion
		const newStart = lineStart + prefix.length;
		const newEnd = newStart + text.length;
		input.setSelectionRange(newStart, newEnd);
		input.focus();

		this.updatePreview();
	}

	renderPreview() {
		const markdown = this.inputTarget.value;

		if (!markdown.trim()) {
			this.outputTarget.innerHTML =
				'<p class="text-gray-500 italic">Start typing to see preview...</p>';
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
			'<a href="$2" target="_blank" rel="noopener" class="link underline text-placecal-teal-dark">$1</a>'
		);

		// Auto-link bare URLs (not already in a tag)
		html = html.replace(
			/(?<!href="|">)(https?:\/\/[^\s<]+)/g,
			'<a href="$1" target="_blank" rel="noopener" class="link underline text-placecal-teal-dark">$1</a>'
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
