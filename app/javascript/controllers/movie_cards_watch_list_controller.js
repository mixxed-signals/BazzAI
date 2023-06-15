import { Controller } from "@hotwired/stimulus"

const alert = () => `
  <a href="/user" class="movie-card-button movie-card-button-watch-list">
    Added to your watch list
  </a>
`

// Connects to data-controller="movie-cards-watch-list"
export default class extends Controller {
  static targets = [ "text" ]

  connect() {
  }
  acceptPopUp() {
    this.textTarget.innerHTML = alert()
  }
}
