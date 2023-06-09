import { Controller } from '@hotwired/stimulus';

const omdbapiUrl = 'http://www.omdbapi.com/';
const omdbapiKey = 'adf1f2d7';
const numberCounters = ['one', 'two', 'three'];
let counter = 0;

const createMovieCard = (movie) => {
  let poster = movie.Poster;
  if (poster === "N/A") {
    poster =
      "https://cdn.discordapp.com/attachments/1105433122998325278/1116723284348772453/Group_46.png";
  }
  return `
  <div class="search-boxes-container-results-card" data-action='click->movie-search#selectMovie'>
    <input type="hidden" value="${movie.Title}">
    <img src="${poster}" class="search-boxes-container-results-card-image" />
    <p class="search-boxes-container-results-card-infos">
      ${movie.Title}
      <br/>
      ( ${movie.Year} )
    </p>
  </div>
  `;
};

const createContent = (data) => {
  const cards = data.Search.filter((movie, index) => {
    if (index < 5) return movie;
  });
  return cards.map((movie) => createMovieCard(movie)).join('');
};

const createUrl = (search) => {
  return `${omdbapiUrl}?apikey=${omdbapiKey}&s=${search}`;
};

// Connects to data-controller="movie-search"
export default class extends Controller {
  static targets = [
    'search',
    'results',
    'selected',
    'recentOne',
    'recentTwo',
    'recentThree',
    'selectedOne',
    'selectedTwo',
    'selectedThree',
  ];

  connect() {
    this.resultsTarget.innerHTML = '';
  }

  handleInput(event) {
    fetch(createUrl(event.target.value))
      .then((response) => response.json())
      .then((data) => {
        if (data.Search)
          return (this.resultsTarget.innerHTML = createContent(data));
        this.resultsTarget.innerHTML = '';
      });
  }

  selectMovie(event) {
    event.currentTarget.classList.add('selected');
    counter += 1;

    const image = event.currentTarget.querySelector('img').src;
    const title = event.currentTarget.querySelector('p').innerHTML;
    const dbTitle = event.currentTarget.querySelector('input').value;

    this.recents = [this.recentOneTarget, this.recentTwoTarget, this.recentThreeTarget];
    this.selecteds = [this.selectedOneTarget, this.selectedTwoTarget, this.selectedThreeTarget];

    this.recents[counter - 1].value = dbTitle;
    this.selecteds[counter - 1].querySelector('img').src = image;
    this.selecteds[counter - 1].querySelector('p').innerHTML = title;
  }

  removeMovie(event) {
    const selected = event.currentTarget;

    const image = selected.querySelector('img');
    const title = selected.querySelector('p');

    counter -= 1;
    image.src =
      "https://cdn.discordapp.com/attachments/1105433122998325278/1116395162105552946/bazzy_avatar.png";
    title.innerHTML = 'Pick a movie';
  }
}
