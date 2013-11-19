xml.instruct!
xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
  xml.title settings.blog_title
  xml.subtitle settings.blog_description
  xml.id settings.site_url
  xml.link "href" => settings.site_url
  xml.link "href" => URI.join(settings.site_url, request.path), "rel" => "self"
  xml.updated articles.first.date.to_time.iso8601 unless articles.empty?
  xml.author { xml.name settings.author }

  articles[0..5].each do |article|
    xml.entry do
      xml.title article.front_matter["title"]
      xml.link "rel" => "alternate", "href" => URI.join(settings.site_url, article.url)
      xml.id URI.join(settings.site_url, article.url)
      xml.published article.date.to_time.iso8601
      xml.updated File.mtime(article.path).iso8601
      xml.author { xml.name settings.author }
      xml.content markdown(article.body), "type" => "html"
    end
  end
end
