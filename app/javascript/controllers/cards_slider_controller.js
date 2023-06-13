import { Controller } from '@hotwired/stimulus';

const regex = /-?\d+/;

// Connects to data-controller="cards-slider"
export default class extends Controller {
  static targets = ['slide'];

  connect() {
    this.slideTarget.style.transition = 'transform 0.8s ease-in-out';
    if (this.slideTarget.offsetWidth <= this.element.offsetWidth) {
      this.element.querySelector('.right-button').disabled = true;
    }
  }
  rightSlide(event) {
    const translateX = this.slideTarget.style.transform;
    this.slideTarget.style.transform = `translateX(${ translateX ? parseInt(translateX.match(/-?\d+/)[0]) - 680 : -680 }px)`;
    this.element.querySelector('.left-button').disabled = false;

    if (parseInt(this.slideTarget.style.transform.match(regex)[0]) <= -this.slideTarget.offsetWidth + 500) {
      event.currentTarget.disabled = true;
    }
  }
  leftSlide(event) {
    const translateX = this.slideTarget.style.transform;
    this.slideTarget.style.transform = `translateX(${
      translateX ? parseInt(translateX.match(/-?\d+/)[0]) + 680 : 680
    }px)`;
    this.element.querySelector('.right-button').disabled = false;
    if (this.slideTarget.style.transform === `translateX(0px)`) {
      event.currentTarget.disabled = true;
    }
  }
}
