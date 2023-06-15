import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["text"];

  connect() {
    this.animateText();
  }

  animateText() {
    const textElements = this.textTargets;
    textElements.forEach((text) => {
      const textContent = text.textContent;
      text.textContent = "";

      const delay = parseInt(text.getAttribute("data-typewriter-delay")) || 0; // Get the delay value from the data attribute

      setTimeout(() => {
        let i = 0;
        const typingAnimation = setInterval(() => {
          if (i < textContent.length) {
            text.textContent += textContent[i];
            i++;
          } else {
            clearInterval(typingAnimation);
          }
        }, 20);
      }, delay);
    });
  }
}
