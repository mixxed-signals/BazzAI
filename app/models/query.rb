class Query < ApplicationRecord
  belongs_to :user
  has_many :recommendations
  MEDIUMS = ["Movie", "TV Show"]
  AUDIENCE = ["Just Me", "Couple", "Family"]
  STREAMING_PLATFORMS = ["netflix", "hulu", "prime", "hbo", "disney", "apple", "peacock", "youtube", "wow", "mubi"]
  GENRES = [
    "Acclaimed",
    "Action",
    "Adventure",
    "Animation",
    "Anime",
    "Biography",
    "Classic",
    "Comedy",
    "Crime",
    "Cult",
    "Documentary",
    "Drama",
    "Experimental",
    "Family",
    "Fantasy",
    "Film-Noir",
    "Gangster",
    "History",
    "Horror",
    "Independent",
    "International",
    "Music",
    "Mystery",
    "Musical",
    "Noir",
    "Psychological",
    "Queer",
    "Reality",
    "Romance",
    "Rom-Com",
    "Satire",
    "Sci-Fi",
    "Space",
    "Sports",
    "Spy",
    "Superhero",
    "Supernatural",
    "Suspense",
    "Thriller",
    "True Crime",
    "Western",
    "Youth"
  ]
  MOOD = [
    "Depressed",
    "Sad",
    "Melancholic",
    "Bummed Out",
    "Pensive",
    "Okay",
    "Chill",
    "Neutral",
    "Happy",
    "Excited",
    "Thrilled",
    "Over the Moon"
  ]
end
