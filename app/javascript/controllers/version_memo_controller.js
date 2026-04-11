import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form"]

  edit() {
    this.displayTarget.style.display = "none"
    this.formTarget.style.display = "block"
    this.formTarget.querySelector("input[type=text]").focus()
  }

  cancel() {
    this.formTarget.style.display = "none"
    this.displayTarget.style.display = "block"
  }
}
