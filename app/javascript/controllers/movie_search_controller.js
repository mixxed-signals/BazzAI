import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="movie-search"
export default class extends Controller {
  connect() {
    console.log("Search controller connected");
  }

  handleInput(event) {
    this.search();
  }
}

const omdbapiUrl = "http://www.omdbapi.com/";
const imgUrl = `http://img.omdbapi.com/?apikey=${apiKey}&`;
const searchForm = document.querySelector("#movie-name");
const movieDisplay = document.querySelector("#movie-cards");

const searchMovies = () => {
  // event.preventDefault();
  const title = document.querySelector("#movie-name").value;
  movieDisplay.innerHTML = "";
  const url = `${omdbapiUrl}?s=${encodeURIComponent(title)}&apikey=${apiKey}`;
  fetch(url)
    .then((response) => response.json())
    .then((data) => {
      console.log(data);
      if (data.Search) {
        const newList = data.Search.map((movie) => {
          if (movie.Poster === "N/A") {
            return `<div class="col-lg-3 col-md-4 col-sm-6 col-12"><div class="card mb-2"><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/No_image_available.svg/1024px-No_image_available.svg.png" class="card-img-top" alt="${movie.Title}"><div class="card-body"><span class="badge bg-primary mb-2">${movie.Year}</span><h5 class="card-title">${movie.Title}</h5></div></div></div>`;
          }
          return `<div class="col-lg-3 col-md-4 col-sm-6 col-12"><div class="card mb-2"><img src="${movie.Poster}" class="card-img-top" alt="${movie.Title}"><div class="card-body"><span class="badge bg-primary mb-2">${movie.Year}</span><h5 class="card-title">${movie.Title}</h5></div></div></div>`;
        }).join("");
        movieDisplay.innerHTML = newList;
      }
    })
    .catch((error) => {
      console.error(error);
    });
};
