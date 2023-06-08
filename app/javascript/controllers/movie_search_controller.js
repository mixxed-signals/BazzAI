import { Controller } from '@hotwired/stimulus';

const omdbapiUrl = 'http://www.omdbapi.com/';
const omdbapiKey = 'adf1f2d7';

const createMovieCard = (movie) => {
  return `
  <div class="search-boxes-container-results-card">
    <img src="${movie.Poster}" class="search-boxes-container-results-card-image" />
    <p class="search-boxes-container-results-card-infos">${movie.Title} ( ${movie.Year} )</p>
  </div>
  `;
};

const createContent = (data) => {
  return data.Search.map((movie) => createMovieCard(movie)).join('');
};

const createUrl = (search) => {
  return `${omdbapiUrl}?apikey=${omdbapiKey}&s=${search}`;
};

// Connects to data-controller="movie-search"
export default class extends Controller {
  static targets = ['search', 'results', 'selected'];

  connect() {
    console.log('Search controller connected');
  }

  handleInput(event) {
    fetch(createUrl(event.target.value))
      .then((response) => response.json())
      .then((data) => {
        if (data.Search) return this.resultsTarget.innerHTML = createContent(data);
        this.resultsTarget.innerHTML = '';
      });
  }
}
