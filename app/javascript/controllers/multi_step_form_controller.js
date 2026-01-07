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

		// Update step buttons
		this.stepButtonTargets.forEach((button, index) => {
			button.classList.remove(
				"bg-placecal-orange",
				"text-white",
				"bg-gray-100",
				"text-gray-600"
			);
			if (index === this.currentStepValue) {
				button.classList.add("bg-placecal-orange", "text-white");
			} else if (index < this.currentStepValue) {
				button.classList.add("bg-green-100", "text-green-800");
			} else {
				button.classList.add("bg-gray-100", "text-gray-600");
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

		// Update next button text
		if (this.hasNextButtonTarget) {
			if (this.currentStepValue === this.totalStepsValue - 1) {
				this.nextButtonTarget.classList.add("hidden");
			} else {
				this.nextButtonTarget.classList.remove("hidden");
			}
		}

		// Update progress bar if present
		if (this.hasProgressTarget) {
			const percentage =
				((this.currentStepValue + 1) / this.totalStepsValue) * 100;
			this.progressTarget.style.width = `${percentage}%`;
		}
	}

	scrollToTop() {
		window.scrollTo({ top: 0, behavior: "smooth" });
	}
}
