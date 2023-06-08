import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ["value", "output", "input"];

  connect() {
    this.updateValue();
  }

  updateValue() {
    const sliderValue = this.inputTarget.value;
    const outputTarget = this.outputTarget;
    console.log("Slider value:", sliderValue);
    outputTarget.textContent = sliderValue;
  }
}
