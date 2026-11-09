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

function feedUrl(value) {
	const url = parseUrl(value);
	if (!url || !isGoogleCalendar(url)) return null;

	const id = calendarId(url);
	if (!id || !CALENDAR_ID.test(id)) return null;

	return `https://calendar.google.com/calendar/ical/${encodeURIComponent(id)}/public/basic.ics`;
}

/**
 * Google Calendar Source Controller
 * Swaps a Google Calendar embed or share link for its .ics feed address
 */
export default class extends Controller {
	static targets = ["input", "notice"];

	rewrite(event) {
		// Typed links wait for the change event, so the text doesn't move mid-word.
		if (event.inputType === "insertText") return;

		const feed = feedUrl(this.inputTarget.value.trim());
		if (feed) {
			this.inputTarget.value = feed;
			this.rewrittenUrl = feed;
			this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }));
		}

		this.noticeTarget.classList.toggle(
			"hidden",
			this.inputTarget.value !== this.rewrittenUrl,
		);
	}
}
