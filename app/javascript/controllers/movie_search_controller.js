import { Controller } from '@hotwired/stimulus';

const omdbapiUrl = 'https://www.omdbapi.com/';
const omdbapiKey = 'b02e181b';
const cardOrder = [false, false, false];
let counter = 0;

const createMovieCard = (movie) => {
  let poster = movie.Poster;
  if (poster === 'N/A') {
    poster =
      'https://cdn.discordapp.com/attachments/1105433122998325278/1116723284348772453/Group_46.png';
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
    this.searchTarget.value = '';
    counter = 0;
  }

  async handleInput(event) {
    try {
      const response = await fetch(createUrl(event.target.value));
      const data = await response.json();

      if (data.Search) {
        this.resultsTarget.innerHTML = createContent(data);
      } else {
        this.resultsTarget.innerHTML = '';
      }
    } catch (error) {
      console.error('Error:', error);
    }
  }

  selectMovie(event) {
    const image = event.currentTarget.querySelector('img').src;
    const title = event.currentTarget.querySelector('p').innerHTML;
    const dbTitle = event.currentTarget.querySelector('input').value;

    if (counter === 0) {
      this.selectedOneTarget.querySelector('img').src = image;
      this.selectedOneTarget.querySelector('p').innerHTML = title;
      this.selectedOneTarget.querySelector('input').value = dbTitle;
      this.selectedOneTarget.classList.add('selected');
      cardOrder[0] = true;
      counter++;
    } else if (counter === 1) {
      this.selectedTwoTarget.querySelector('img').src = image;
      this.selectedTwoTarget.querySelector('p').innerHTML = title;
      this.selectedTwoTarget.querySelector('input').value = dbTitle;
      this.selectedTwoTarget.classList.add('selected');
      cardOrder[1] = true;
      counter++;
    } else if (counter === 2) {
      this.selectedThreeTarget.querySelector('img').src = image;
      this.selectedThreeTarget.querySelector('p').innerHTML = title;
      this.selectedThreeTarget.querySelector('input').value = dbTitle;
      this.selectedThreeTarget.classList.add('selected');
      cardOrder[2] = true;
    }
  }

  removeMovie(event) {
    const selected = event.currentTarget;

    if (selected.id === 'selected-one') {
      this.selectedOneTarget.querySelector('img').src =
        'https://cdn.discordapp.com/attachments/1105433122998325278/1116395162105552946/bazzy_avatar.png';
      this.selectedOneTarget.querySelector('p').innerHTML = 'Pick a movie';
      this.selectedOneTarget.querySelector('input').value = '';
      this.selectedOneTarget.classList.remove('selected');
      cardOrder[0] = false;
      counter--;
    } else if (selected.id === 'selected-two') {
      this.selectedTwoTarget.querySelector('img').src =
        'https://cdn.discordapp.com/attachments/1105433122998325278/1116395162105552946/bazzy_avatar.png';
      this.selectedTwoTarget.querySelector('p').innerHTML = 'Pick a movie';
      this.selectedTwoTarget.querySelector('input').value = '';
      this.selectedTwoTarget.classList.remove('selected');
      cardOrder[0] = false;
      counter--;
    } else if (selected.id === 'selected-three') {
      this.selectedThreeTarget.querySelector('img').src =
        'https://cdn.discordapp.com/attachments/1105433122998325278/1116395162105552946/bazzy_avatar.png';
      this.selectedThreeTarget.querySelector('p').innerHTML = 'Pick a movie';
      this.selectedThreeTarget.querySelector('input').value = '';
      this.selectedThreeTarget.classList.remove('selected');
      cardOrder[0] = false;
    }
  }
}
