import { Controller } from "@hotwired/stimulus"

// Rails helpfully adds a "multiple" attribute if there is a has_many relationship.
// If you need to select multiple but aren't getting that option add a multiple: "true"
// attirubute to the template.
// If you need a single selection but are getting multiple this controller will need updating
// to make this option more explicit.
export default class extends Controller {
  connect() {
		$(this.element).select2();
  }
  disconnect() {
		$(this.element).select2("destroy");
  }
}
