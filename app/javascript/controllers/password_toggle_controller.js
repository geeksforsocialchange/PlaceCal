import { Controller } from "@hotwired/stimulus";

// https://stimulus.hotwired.dev/reference/controllers

/**
 * use on a password toggle
 * see `app/views/devise/sessions/new.html.erb` for an example
 */
export default class extends Controller {
	/**  the target elements for the controller
	 *
	 * they're exposed on the class instance as `${name}Target` at runtime but do not appear on the classes' type. use `has${Name}Target` to test if an optional target is present
	 *
	 * they're hooked up to the controller using either:
	 * 	- a data attrib in the markup: `data-password-toggle-target="button"`, or
	 *  - a data attrib (note `-` -> `#`) to a function which renders markup: `<%= f.password#field :password, autocomplete: "off", data: { password#toggle#target: 'input'} %>`
	 *
	 * the targets are:
	 * - input: an input[type="password"]
	 * - button: the toggle button
	 * - show: optional icon etc to show when toggle is enabled
	 * - hide: optional icon etc to show when toggle is disabled
	 *  */
	static targets = ["input", "button", "show", "hide"];

	/** toggle state */
	#state = false;
	/** whether we have focus within */
	#focus = false;
	/** for event listener teardown */
	#abortController = new AbortController();

	#updateIcons() {
		// @ts-ignore
		// `hide` and `show` are optional so we need to test for their existence
		// @ts-ignore
		if (this.hasShowTarget)
			// @ts-ignore
			this.showTarget.style.display = this.#state ? "unset" : "none";
		// @ts-ignore
		if (this.hasHideTarget)
			// @ts-ignore
			this.hideTarget.style.display = this.#state ? "none" : "unset";
	}

	#updateInput() {
		// @ts-ignore
		this.inputTarget.type = this.#state && this.#focus ? "text" : "password";
	}

	#handleButtonClick() {
		this.#state = !this.#state;
		// @ts-ignore
		this.buttonTarget.ariaChecked = this.#state;
		// show immediately despite the input no longer having focus
		if (this.#state) this.#focus = true;
		this.#updateIcons();
		this.#updateInput();
	}

	#handleInputFocus() {
		this.#focus = true;
		this.#updateInput();
	}

	#handleInputBlur() {
		this.#focus = false;
		this.#updateInput();
	}

	// stimulus mount/unmount
	connect() {
		// @ts-ignore
		this.buttonTarget.addEventListener(
			"click",
			() => this.#handleButtonClick(),
			{
				signal: this.#abortController.signal,
			},
		);
		// @ts-ignore
		this.inputTarget.addEventListener("focus", () => this.#handleInputFocus(), {
			signal: this.#abortController.signal,
		});
		// @ts-ignore
		this.inputTarget.addEventListener("blur", () => this.#handleInputBlur(), {
			signal: this.#abortController.signal,
		});
		this.#updateIcons();
		this.#updateInput();
	}

	disconnect() {
		this.#abortController.abort();
	}
}
