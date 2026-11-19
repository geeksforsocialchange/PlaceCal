import { Controller } from "@hotwired/stimulus";

const CALENDAR_ID = /^[^\s@/]+@[^\s@/]+\.[^\s@/]+$/;

function parseUrl(value) {
	try {
		return new URL(value);
	} catch {
		return null;
	}
}

function isGoogleCalendar(url) {
	return (
		url.hostname === "calendar.google.com" ||
		(url.hostname === "www.google.com" && url.pathname.startsWith("/calendar/"))
	);
}

function decodeCid(cid) {
	if (CALENDAR_ID.test(cid)) return cid;

	try {
		return atob(cid.replace(/[ -]/g, "+").replace(/_/g, "/"));
	} catch {
		return null;
	}
}

function calendarId(url) {
	const sources = url.searchParams.getAll("src");
	// An embed showing several calendars has no single feed.
	if (sources.length > 1) return null;
	if (sources.length === 1) return sources[0];

	const cid = url.searchParams.get("cid");
	return cid ? decodeCid(cid) : null;
}

function googleFeedUrl(value) {
	const url = parseUrl(value);
	if (!url || !isGoogleCalendar(url)) return null;

	const id = calendarId(url);
	if (!id || !CALENDAR_ID.test(id)) return null;

	return `https://calendar.google.com/calendar/ical/${encodeURIComponent(id)}/public/basic.ics`;
}

// Links whose feed only the server can look up
const SERVER_RESOLVED = [
	/^https?:\/\/www\.eventbrite\.(com|co\.uk)\/e\//,
	/^https?:\/\/(www\.)?(lu\.ma|luma\.com)\/[\w-]+\/?([?#]|$)/,
];

/**
 * Calendar Source Controller
 * Swaps a link to a calendar page or a single event for the feed PlaceCal can import
 */
export default class extends Controller {
	static targets = ["input", "notice"];
	static values = { resolveUrl: String, notices: Object };

	rewrite(event) {
		// Typed links wait for the change event, so the text doesn't move mid-word.
		if (event.inputType === "insertText") return;

		const value = this.inputTarget.value.trim();
		const feed = googleFeedUrl(value);
		if (feed) {
			this.swap(feed, "google");
		} else if (SERVER_RESOLVED.some((pattern) => pattern.test(value))) {
			this.resolve(value);
		}

		this.updateNotice();
	}

	async resolve(value) {
		if (value === this.pendingValue) return;

		this.lookup?.abort();
		this.lookup = new AbortController();
		this.pendingValue = value;

		const url = new URL(this.resolveUrlValue, window.location.origin);
		url.searchParams.set("source", value);

		try {
			const response = await fetch(url, {
				headers: { Accept: "application/json" },
				signal: this.lookup.signal,
			});
			if (!response.ok) return;

			const { source, kind } = await response.json();
			if (source && this.inputTarget.value.trim() === value) {
				this.swap(source, kind);
			}
		} catch {
			// A failed lookup leaves the link as typed
		} finally {
			if (this.pendingValue === value) this.pendingValue = null;
		}
	}

	swap(feed, kind) {
		this.inputTarget.value = feed;
		this.rewrittenUrl = feed;
		this.rewrittenKind = kind;
		this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }));
	}

	updateNotice() {
		const rewritten = this.inputTarget.value === this.rewrittenUrl;
		if (rewritten) {
			this.noticeTarget.textContent = this.noticesValue[this.rewrittenKind];
		}
		this.noticeTarget.classList.toggle("hidden", !rewritten);
	}
}
