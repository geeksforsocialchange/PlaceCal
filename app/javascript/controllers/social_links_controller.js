import { Controller } from "@hotwired/stimulus";

// Names the platform of each social link row as it's typed, using the rules SocialLink serialises.
export default class extends Controller {
	static values = { rules: Object };

	detect(event) {
		const row = event.target.closest(".nested-fields");
		const platform = row?.querySelector(
			"[data-social-links-target='platform']",
		);
		if (platform) platform.textContent = this.platformName(event.target.value);
	}

	platformName(value) {
		const typed = value.trim();
		if (!typed) return "";
		let url;
		try {
			url = new URL(
				/^[a-z][a-z\d+.-]*:\/\//i.test(typed) ? typed : `https://${typed}`,
			);
		} catch {
			return "";
		}
		if (!["http:", "https:"].includes(url.protocol) || !url.hostname) return "";

		const host = url.hostname.toLowerCase().replace(/^www\./, "");
		const { hosts, fediverse, not_fediverse: notFediverse } = this.rulesValue;
		const known = Object.keys(hosts).find(
			(domain) => host === domain || host.endsWith(`.${domain}`),
		);
		if (known) return hosts[known];
		if (
			notFediverse.some(
				(domain) => host === domain || host.endsWith(`.${domain}`),
			)
		)
			return host;
		if (/^\/@[\w.-]+(@[\w.-]+\.[a-z]{2,})?\/?$/i.test(url.pathname))
			return fediverse;
		return host;
	}
}
