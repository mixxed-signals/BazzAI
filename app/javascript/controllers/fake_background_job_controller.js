import { Controller } from "@hotwired/stimulus"

const loadingContainer = `
<div class="container my-2 p-0 min-vh-100">
    <div class="prompt-container">
      <div class="bazzy-display">
        <img alt="Show case of BazzAI" id="bazzy-index" src="/assets/bazzy_avatar-7da12086e56e24cb0264b41a60efcf36f7c4c639f1ffaeaa6869a8f0c0dc9d8a.png">
      </div>
      <div data-controller="typewriter" class="typewriter-container">
        <div data-typewriter-target="text">
          Hi, I'm Bazzy! I'm thinking about your recommendations... It might take me a while...
        </div>
      </div>
    </div>
    <hr class="w-75"/>
    <div class="container d-flex">
      <div class="d-flex flex-column align-item-start justify-content-start gap-4 w-100 my-4">
        <div class="d-flex flex-column align-item-center justify-content-center gap-3">
          <div class="movie-card">
            <div class="container-loading container-loading-image"></div>
            <div class="movie-card-infos-container movie-card-infos-container-loading w-100">
              <div class="container-loading container-loading-title"></div>
              <div class="container-loading container-loading-description"></div>
              <div class="container-loading container-loading-button"></div>
            </div>
          </div>
          <div class="movie-card">
            <div class="container-loading container-loading-image"></div>
            <div class="movie-card-infos-container movie-card-infos-container-loading w-100">
              <div class="container-loading container-loading-title"></div>
              <div class="container-loading container-loading-description"></div>
              <div class="container-loading container-loading-button"></div>
            </div>
          </div>
          <div class="movie-card">
            <div class="container-loading container-loading-image"></div>
            <div class="movie-card-infos-container movie-card-infos-container-loading w-100">
              <div class="container-loading container-loading-title"></div>
              <div class="container-loading container-loading-description"></div>
              <div class="container-loading container-loading-button"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
`

// Connects to data-controller="fake-background-job"
export default class extends Controller {
  static targets = [ "content" ]

  connect() {
  }
  fakeSubmit(event) {
    console.log(event.target);
    // debugger
    this.contentTarget.innerHTML = loadingContainer
    window.scrollTo(0, 0);
  }
}
