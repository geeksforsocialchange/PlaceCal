import { Controller } from "@hotwired/stimulus";

// Signs an email address up to a Ghost site's newsletter from another site,
// the same two calls Ghost's own embed makes. Without JS the form falls back
// to its action (Ghost's portal sign-up page).
export default class extends Controller {
	static targets = ["email", "fields", "message", "hideOnSuccess"];
	static values = {
		site: String,
		label: String,
		successMessage: String,
		errorMessage: String,
	};

	async submit(event) {
		event.preventDefault();
		const email = this.emailTarget.value.trim();
		if (!email) return;

		this.element.classList.add("is-busy");
		try {
			const integrityToken = await this.fetchIntegrityToken();
			await this.sendMagicLink(email, integrityToken);
			this.fieldsTarget.hidden = true;
			this.hideOnSuccessTargets.forEach((el) => (el.hidden = true));
			this.showMessage(this.successMessageValue);
		} catch {
			this.showMessage(this.errorMessageValue);
		} finally {
			this.element.classList.remove("is-busy");
		}
	}

	async fetchIntegrityToken() {
		const response = await fetch(this.endpoint("integrity-token"));
		if (!response.ok) throw new Error(response.statusText);
		return response.text();
	}

	async sendMagicLink(email, integrityToken) {
		const response = await fetch(this.endpoint("send-magic-link"), {
			method: "POST",
			headers: { "Content-Type": "application/json" },
			body: JSON.stringify({
				email,
				emailType: "signup",
				labels: this.labelValue ? [this.labelValue] : [],
				urlHistory: this.urlHistory(),
				integrityToken,
			}),
		});
		if (!response.ok) throw new Error(response.statusText);
	}

	// Same entry as Ghost's embed, so the member shows this site as their sign-up source.
	urlHistory() {
		const { protocol, host, pathname } = window.location;
		return [
			{
				time: Date.now(),
				referrerSource: host,
				referrerMedium: "Embed",
				referrerUrl: `${protocol}//${host}${pathname}`,
			},
		];
	}

	endpoint(resource) {
		return `${this.siteValue.replace(/\/$/, "")}/members/api/${resource}/`;
	}

	showMessage(text) {
		this.messageTarget.textContent = text;
		this.messageTarget.hidden = false;
	}
}
