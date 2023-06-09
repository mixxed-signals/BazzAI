import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="omdb-request"
export default class extends Controller {
  static targets = [
    'omdb',
    'movie_name',
    'movie_title',
    'movie_description',
    'movie_post',
  ];

  connect() {
    fetch(
      `http://www.omdbapi.com/?t=${this.movie_nameTarget.value}&apikey=${this.omdbTarget.value}`
    )
      .then((response) => response.json())
      .then((data) => {
        this.movie_titleTarget.innerHTML = `${data.Title} (${data.Year})`;
        this.movie_descriptionTarget.innerHTML = data.Plot;
        this.movie_postTarget.src = data.Poster;
        this.movie_postTarget.alt = data.Title;
      });


  }
}
