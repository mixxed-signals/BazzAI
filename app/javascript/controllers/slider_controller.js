import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["value", "output", "input"];

  connect() {
    this.updateValue();
  }

  updateValue() {
    const sliderValue = this.inputTarget.value;
    const outputTarget = this.outputTarget;

    if (sliderValue === "120") {
      outputTarget.textContent = "120+ min";
    } else {
      outputTarget.textContent = sliderValue + " min";
    }
  }
}
