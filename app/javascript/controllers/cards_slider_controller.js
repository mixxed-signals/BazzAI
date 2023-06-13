import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="cards-slider"
export default class extends Controller {
  static targets = ['slide'];

  connect() {
    this.slideTarget.style.transition = 'transform 0.8s ease-in-out';
  }
  rightSlide(event) {
    const translateX = this.slideTarget.style.transform;
    this.slideTarget.style.transform = `translateX(${
      translateX ? parseInt(translateX.match(/-?\d+/)[0]) - 500 : -500
    }px)`;
    this.element.querySelector('.left-button').disabled = false;
    if (this.slideTarget.style.transform === 'translateX(-5000px)') {
      event.currentTarget.disabled = true;
    }
  }
  leftSlide(event) {
    const translateX = this.slideTarget.style.transform;
    this.slideTarget.style.transform = `translateX(${
      translateX ? parseInt(translateX.match(/-?\d+/)[0]) + 500 : 500
    }px)`;
    this.element.querySelector('.right-button').disabled = false;
    if (this.slideTarget.style.transform === 'translateX(0px)') {
      event.currentTarget.disabled = true;
    }
  }
}
