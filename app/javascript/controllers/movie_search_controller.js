import { Controller } from "@hotwired/stimulus"

const movieCard = (movie) => {
  return `
  <div class="gray-box">
    <img src="${movie.poster}" />
    <p class="selected-movie">${movie.title} ( ${movie.year} )</p>
  </div>
  `
}

// Connects to data-controller="movie-search"
export default class extends Controller {
  static targets = [ "search" , "results" , "selected" ]

  connect() {
    console.log("Search controller connected");
  }

  handleInput(event) {
    fetch(``).then(response => response.json()).then((data) => {console.log(data)})
  }
}
