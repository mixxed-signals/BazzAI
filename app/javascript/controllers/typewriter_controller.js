import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['text'];

  connect() {
    console.log("Typewriter controller connected...");
    this.animateText();
  }

  animateText() {
    const textElement = this.textTarget;
    const textContent = textElement.textContent;
    textElement.textContent = "";

    let i = 0;
    const typingAnimation = setInterval(() => {
      if (i < textContent.length) {
        textElement.textContent += textContent[i];
        i++;
      } else {
        clearInterval(typingAnimation);
      }
    }, 20);
  }
}
