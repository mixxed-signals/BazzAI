import { Controller } from "@hotwired/stimulus"

const alert = (movieName) => `
<div class="add-button mt-3">
  <a href="/user" class="text-decoration-none">
    <p class="m-0 text-white">${movieName} are added to your <strong class="font-weight-bold">watch list</strong></p>
  </a>
</div>
`

// Connects to data-controller="add-watch-list"
export default class extends Controller {
  static targets = [ "text", "movie" ]
  connect() {
  }
  acceptPopUp() {
    const movieName = this.movieTarget.value
    this.textTarget.innerHTML = alert(movieName)
  }
}