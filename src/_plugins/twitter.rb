# This is a plugin for embedding tweets that avoids using Twitter's native
# embedding.  Rendering tweets as static HTML reduces page weight, load times,
# and is resilient against tweets being deleted.
#
# Auth is with a set of Twitter API keys, in a file `_tweets/auth.yml` in
# in the root of your Jekyll site.  The file should have four lines:
#
#     consumer_key: "<CONSUMER_KEY>"
#     consumer_secret: "<CONSUMER_SECRET>"
#     access_token: "<ACCESS_TOKEN>"
#     token_secret: "<TOKEN_SECRET>"
#
# Don't check in this auth file!
#
# Tweet data will be cached in `_tweets` -- you can check in these files.
#
# To embed a tweet, place a Liquid tag of the following form anywhere in a
# source file:
#
#     {% tweet https://twitter.com/raibgovuk/status/905355951557013506 %}
#

require 'fileutils'
require 'json'
require 'open-uri'
require 'twitter'


module Jekyll
  class TwitterTag < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
      @tweet_url = text
      @tweet_id = @tweet_url.split("/").last.strip

      if not File.exists? cache_file()
        puts("Caching #{@tweet_url}")
        client = setup_api_client()
        tweet = client.status(@tweet_url)
        json_string = JSON.pretty_generate(tweet.attrs)
        File.open(cache_file(), 'w') { |f| f.write(json_string) }
        download_avatar(tweet)
      end
    end

    def cache_file()
      "_tweets/#{@tweet_id}.json"
    end

    def avatar_path(avatar_url, screen_name)
      extension = avatar_url.split(".").last  # ick
      "images/twitter/#{screen_name}_#{@tweet_id}.#{extension}"
    end

    def download_avatar(tweet)
      # I should really get the original using the lookup method, but
      # it kept breaking when I tried to use it.
      avatar_url = tweet.user.profile_image_url_https().to_str.sub("_normal", "")

      FileUtils::mkdir_p 'images/twitter'
      File.open(avatar_path(avatar_url, tweet.user.screen_name), "wb") do |saved_file|
        # the following "open" is provided by open-uri
        open(avatar_url, "rb") do |read_file|
          saved_file.write(read_file.read)
        end
      end
    end

    def setup_api_client()
      auth = YAML.load(File.read('_tweets/auth.yml'), :safe => true)
      Twitter::REST::Client.new do |config|
        config.consumer_key        = auth["consumer_key"]
        config.consumer_secret     = auth["consumer_secret"]
        config.access_token        = auth["access_token"]
        config.access_token_secret = auth["access_secret"]
      end
    end

    def render(context)
      tweet_data = JSON.parse(File.read(cache_file()))

      name = tweet_data["user"]["name"]
      screen_name = tweet_data["user"]["screen_name"]
      avatar_url = tweet_data["user"]["profile_image_url_https"]

      timestamp = DateTime
        .parse(tweet_data["created_at"], "%a %b %d %H:%M:%S %z %Y")
        .strftime("%-I:%M&nbsp;%p - %-d %b %Y")

      text = tweet_data["text"]
      tweet_data["entities"]["urls"].each { |u|
        text = text.sub(
          u["url"],
          "<a href=\"#{u["expanded_url"]}\">#{u["display_url"]}</a>"
        )
      }

<<-EOT
<div class="tweet">
  <blockquote>
    <div class="header">
      <div class="author">
        <a class="link link_blend" href="https://twitter.com/#{screen_name}">
          <span class="avatar">
            <img src="/#{avatar_path(avatar_url, screen_name)}">
          </span>
          <span class="name" title="#{name}">#{name}</span>
          <span class="screen_name" title="@#{screen_name}">@#{screen_name}</span>
        </a>
      </div>
    </div>
    <div class="body">
      <p class="text">#{text}</p>
      <div class="metadata">
        <a class="link_blend" href="https://twitter.com/#{screen_name}/status/#{@tweet_id}">#{timestamp}</a>
      </div>
    </div>
  </blockquote>
</div>
EOT
    end
  end
end

Liquid::Template.register_tag('tweet', Jekyll::TwitterTag)
