import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ["checkbox", "container"];

  connect() {
    this.updateSelectedCount();
  }

  updateSelectedCount() {
    const maxSelections = 5;
    const selectedCount = this.selectedCheckboxes.length;
    console.log(this.selectedCheckboxes.length);

    if (selectedCount > maxSelections) {
      this.uncheckLastSelectedCheckboxes(selectedCount - maxSelections);
    }
  }

  uncheckLastSelectedCheckboxes(count) {
    const lastSelectedCheckboxes = this.selectedCheckboxes.slice(-count);

    lastSelectedCheckboxes.forEach((checkbox) => {
      checkbox.checked = false;
    });
  }

  get selectedCheckboxes() {
    return this.checkboxTargets.filter((checkbox) => checkbox.checked);
  }
}
