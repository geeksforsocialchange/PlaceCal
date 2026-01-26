import { Controller } from "@hotwired/stimulus";

// Multi-step form controller - manages step navigation without page reloads
export default class extends Controller {
	static targets = [
		"step",
		"stepButton",
		"progress",
		"prevButton",
		"nextButton",
	];
	static values = {
		currentStep: { type: Number, default: 0 },
		totalSteps: { type: Number, default: 1 },
	};

	connect() {
		this.totalStepsValue = this.stepTargets.length;
		this.showCurrentStep();
		this.updateNavigation();
	}

	goToStep(event) {
		const stepIndex = parseInt(event.currentTarget.dataset.step, 10);
		if (stepIndex >= 0 && stepIndex < this.totalStepsValue) {
			this.currentStepValue = stepIndex;
			this.showCurrentStep();
			this.updateNavigation();
		}
	}

	nextStep(event) {
		event.preventDefault();
		if (this.currentStepValue < this.totalStepsValue - 1) {
			this.currentStepValue++;
			this.showCurrentStep();
			this.updateNavigation();
			this.scrollToTop();
		}
	}

	prevStep(event) {
		event.preventDefault();
		if (this.currentStepValue > 0) {
			this.currentStepValue--;
			this.showCurrentStep();
			this.updateNavigation();
			this.scrollToTop();
		}
	}

	showCurrentStep() {
		this.stepTargets.forEach((step, index) => {
			if (index === this.currentStepValue) {
				step.classList.remove("hidden");
			} else {
				step.classList.add("hidden");
			}
		});

		// Update step buttons with daisyUI tab classes
		this.stepButtonTargets.forEach((button, index) => {
			if (index === this.currentStepValue) {
				button.classList.add("tab-active");
			} else {
				button.classList.remove("tab-active");
			}
		});
	}

	updateNavigation() {
		// Update prev button
		if (this.hasPrevButtonTarget) {
			if (this.currentStepValue === 0) {
				this.prevButtonTarget.classList.add("invisible");
			} else {
				this.prevButtonTarget.classList.remove("invisible");
			}
		}

		// Update next button
		if (this.hasNextButtonTarget) {
			if (this.currentStepValue === this.totalStepsValue - 1) {
				this.nextButtonTarget.classList.add("hidden");
			} else {
				this.nextButtonTarget.classList.remove("hidden");
			}
		}

		// Update progress bar (daisyUI progress element uses value attribute)
		if (this.hasProgressTarget) {
			const percentage =
				((this.currentStepValue + 1) / this.totalStepsValue) * 100;
			this.progressTarget.value = percentage;
		}
	}

	scrollToTop() {
		window.scrollTo({ top: 0, behavior: "smooth" });
	}
}
