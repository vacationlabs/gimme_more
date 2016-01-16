class Url < ActiveRecord::Base

  def self.find_twitter_url_or_add(url)
    uri = Url.where(:twitter_uri => url)
    if(uri.blank?)
      puts "not found #{url}"
      uri = Url.get_redirected_url(url)
      Url.create(:twitter_uri => url, :url => uri)
      return uri
    else
      puts "found"
      return uri.first.url
    end
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
