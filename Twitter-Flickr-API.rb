
require 'twitter'
require 'net/http'

### Twitter gem is used to handle the OAuth and API request to Twitter
### Understanding the Twitter API along with OAuth took the longest time
### in this exercise. This portion took about 2 hours to go over the
### documentation.

### Array to store all photos within past month from Twitter and Flickr.

@all_photos = []

### Tweets are retrieved using search method from Twitter gem
### 'q' parameter is accepted which is a query with operators
### Current query is for all '#dctech' hashtags within the last month that are
### images. Figuring out the query was simple as Twitter provides great
### documentation. It took about 15 minutes to complete this portion.

def retrieve_tweets
  client = Twitter::REST::Client.new do |config|
    config.consumer_key        = "GTvnHEwckh5HdjVhCHrXhC5X8"
    config.consumer_secret     = "YCEnOTJ55Kat9aySMbMnX4IbObiOntPtbEWJlEURatzA6aShLZ"
    config.access_token        = "869602481101254657-B5lPR0aJOSL9LQps6hc3wPdUlRhM2zG"
    config.access_token_secret = "XJsm2As76jegYXr3JDfBA7YqGy9fhtEdquDpD1K7xzDwf"
  end

  tweets = client.search("#dctech since:#{(Date.today - 30).to_s} until:#{Date.today.to_s} filter:images")

  collect_tweets_and_retweets(tweets)
end

### Iterating through all tweets and keeping tweet URL and re-tweet count,
### storing them in all photos array.
### This also took about 15 minutes look through the data and choosing what to store

def collect_tweets_and_retweets(tweets)
  tweets.each do |tweet|
    @all_photos.push(tweet.url.to_s => tweet.retweet_count)
  end
end

### Retrieve all photos within the past month with #dctech
### This took about 30 minutes to understand flickr's API

def retrieve_flickr
  url = URI("https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=9d0358bdb316fb63337122f6d5f8a8a5&text=%23dctech&min_upload_date=#{(Date.today - 30).to_s}&max_upload_date=#{Date.today.to_s}&media=photo&format=json&nojsoncallback=1")
  request = Net::HTTP::Get.new(url.to_s)
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  photos = JSON.parse(http.request(request).body)

  collect_flickr_url_and_comments(photos["photos"]["photo"])
end

### Flickr doesn't have the ability to return comment counts from photo
### searches so we have to additional requests with each photo for their comment
### details. This portion seems unnecessary, but unfortunately I was unable to
### find anything in their documentation to allow to retrieve everything I needed
### in one query.

def collect_flickr_url_and_comments(photos)
  photos.each do |photo|
    url = URI("https://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=9d0358bdb316fb63337122f6d5f8a8a5&photo_id=#{photo['id']}&format=json&nojsoncallback=1")
    request = Net::HTTP::Get.new(url.to_s)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    data = JSON.parse(http.request(request).body)

    url = data["photo"]["urls"]["url"][0]["_content"]
    comment_count = data["photo"]["comments"]["_content"].to_i

    @all_photos.push(url => comment_count)
  end
end

### Method to retrieve photos from both Twitter and Flickr and sort by retweets/comments

def retrieve_photos_by_jibe
  retrieve_flickr
  retrieve_tweets

  @all_photos.sort_by! do |photo|
    -photo.values[0]
  end

  puts @all_photos
end

retrieve_photos_by_jibe
