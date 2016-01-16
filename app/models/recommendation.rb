class Recommendation < ActiveRecord::Base

  def self.get_recommendations(url)
    return false if url.blank?

    puts "Got the URL #{url}"
    puts "Building document from the url"
    doc = self.get_pages(url).first
    puts "Document build"

    puts "Getting tweets for #{doc.title}"
    tweets = self.search_for_tweet(doc.title)
    puts "Found #{tweets.count}"

    puts "Extracting links from tweets"
    related_links = self.get_links_from_tweets(tweets)
    puts "Found #{related_links.count} unique links in tweets"

    puts "Decoding twitter links"
    decoded_urls = self.decode_twitter_urls(related_links)
    puts "Decoded and found #{decoded_urls.count} unique links"

    puts "Getting pages"
    related_pages = self.get_pages(decoded_urls)
    puts "Found #{related_pages.count}"

    # computing similarity
    corpus = (related_pages << doc).collect{|page| TfIdfSimilarity::Document.new(page.body)}
    model = TfIdfSimilarity::TfIdfModel.new(corpus, :library => :narray)
    matrix = model.similarity_matrix

    puts "similarity_matrix #{matrix.inspect}"
    articles = self.find_di_similar(model, doc,related_pages)
    puts "final di similar articles #{articles.inspect}"
    return articles
  end

  def self.find_di_similar(model,article, related_pages, offset=0, limit=10)
    matrix = model.similarity_matrix
    result = []
    related_pages.each do |page|
      result.push({
        :title => page.title,
        :meta_description => page.description,
        :url => page.url,
        :similarity => matrix[model.document_index(article), model.document_index(page)]
        })
    end

    result = result.collect{|item| item if item[:similarity] > 0 }
    result.sort_by {|hash| hash[:similarity]}.reverse
  end

  def self.compute_similarity(master_url, slave_url)

  end

  def self.remove_stopwords(text)

  end

  def self.get_pages(urls)
    return false if urls.blank?
    begin
      return (Array(urls) || []).reduce([]) do |memo, url|
        memo.push Pismo::Document.new(url)
      end
    rescue
      return false
    end
  end

  def self.get_twitter_client
    client = Twitter::REST::Client.new do |config|
      config.consumer_key    = "9xfZqLW4Va9io3jkCfkn9BcQZ"
      config.consumer_secret = "VPPq3ysrgRDTt4YvcRSW1mtLUxnnf2Yri4pIPyJSobY0AYXl58"
    end
  end

  def self.search_for_tweet(text)
    # todo: stamming and remove stop words
    self.get_twitter_client.search(text).take(15)
  end

  def self.get_links_from_tweets(tweets)
    (tweets || []).collect {|tweet| URI.extract(tweet.text)}.flatten.compact.uniq
  end

  def self.decode_twitter_urls(urls)
    # urls.collect{|url| get_redirected_url(url)}.flatten.compact.uniq
    urls.collect{|url| Url.find_twitter_url_or_add(url) }.flatten.compact.uniq
    # (urls || []).reduce([]) do |memo, url|
      # memo.push get_redirected_url url
    # end
  end

  def self.get_redirected_url(your_url)
    begin
      result = Curl::Easy.perform(your_url) do |curl|
        curl.follow_location = true
      end
      return result.last_effective_url
    rescue
      return nil
    end
  end 


end
