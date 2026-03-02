import { Controller } from "@hotwired/stimulus";

// https://stimulus.hotwired.dev/reference/controllers
// https://www.typescriptlang.org/docs/handbook/jsdoc-supported-types.html

// `Controller` subclass typing is not great and jsdoc typing is a bit limited. i don't think there's a way to add runtime private props to the typedef (they can be marked that way above the prop declaration but we don't have a `declare` in jsdoc to tell typescript that `inputTarget` etc exist) or override the class type directly. need to declare `this` as `TypedThis` above each method.
/** @typedef {{
 *    state: boolean,
 *    focus: boolean,
 *    abortController: AbortController,
 * 		inputTarget: HTMLInputElement,
 * 		buttonTarget: HTMLButtonElement,
 * 		hasShowTarget: boolean,
 * 		showTarget: HTMLElement | undefined,
 * 		hasHideTarget: boolean,
 * 		hideTarget: HTMLElement | undefined,
 *    updateIcons: () => void,
 *    updateInput: () => void,
 *    updateButton: () => void,
 *    handleButtonClick: () => void,
 *    handleInputFocus: () => void,
 *    handleInputBlur: () => void,
 *  }} TypedThis
 * */

/**
 * use on a password toggle
 * see `app/views/devise/sessions/new.html.erb` for an example
 */
export default class extends Controller {
	/**  the target elements for the controller
	 * - input: an input[type="password"]
	 * - button: the toggle button
	 * - show: optional icon etc to show when toggle is enabled
	 * - hide: optional icon etc to show when toggle is disabled
	 *
	 * they're hooked up to the controller using either:
	 * 	- a data attrib in the markup: `data-password-toggle-target="button"`, or
	 *  - a data attrib (note `-` -> `#`) to a function which renders markup: `<%= f.password#field :password, autocomplete: "off", data: { password#toggle#target: 'input'} %>`
	 *
	 * they're exposed on the class instance as `${name}Target` at runtime but do not appear on the classes' type. use `has${Name}Target` to test if an optional target is present
	 *
	 * alternatively, use `this.targets.find` or `this.targets.has`
	 *  */
	static targets = ["input", "button", "show", "hide"];

	/** toggle state */
	state = false;
	/** whether we have focus within */
	focus = false;
	/** for event listener teardown */
	abortController = new AbortController();

	/** @this TypedThis */
	updateIcons() {
		if (this.hasShowTarget)
			this.showTarget.style.display = this.state ? "unset" : "none";
		if (this.hasHideTarget)
			this.hideTarget.style.display = this.state ? "none" : "unset";
	}

	/** @this TypedThis */
	updateInput() {
		this.inputTarget.type = this.state && this.focus ? "text" : "password";
	}

	/** @this TypedThis */
	updateButton() {
		this.buttonTarget.ariaChecked = this.state ? "checked" : undefined;
		this.buttonTarget.ariaDescription = this.state
			? "Password is shown"
			: "Password is hidden";
	}

	/** @this TypedThis */
	handleButtonClick() {
		this.state = !this.state;
		// show immediately despite the input no longer having focus
		if (this.state) this.focus = true;
		this.updateIcons();
		this.updateInput();
		this.updateButton();
	}

	/** @this TypedThis */
	handleInputFocus() {
		this.focus = true;
		this.updateInput();
	}

	/** @this TypedThis */
	handleInputBlur() {
		this.focus = false;
		this.updateInput();
	}

	// stimulus mount/unmount
	/** @this TypedThis */
	connect() {
		// js has `this` quirks. if we don't explicitly bind `this` or wrap `handleX` in an arrow function, it will try to access properties on the event caller
		this.buttonTarget.addEventListener(
			"click",
			this.handleButtonClick.bind(this),
			{
				signal: this.abortController.signal,
			},
		);
		this.inputTarget.addEventListener(
			"focus",
			this.handleInputFocus.bind(this),
			{
				signal: this.abortController.signal,
			},
		);
		this.inputTarget.addEventListener("blur", this.handleInputBlur.bind(this), {
			signal: this.abortController.signal,
		});
		this.updateIcons();
		this.updateInput();
		this.updateButton();
	}

	/** @this TypedThis */
	disconnect() {
		this.abortController.abort();
	}
}
