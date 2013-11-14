require "slim"

set :blog_title, "r7kamura blog"
set :blog_description, "marking down about tech."
set :author, "r7kamura"
set :site_url, "http://r7kamura.github.io/"
set :layout_engine, :slim

page "/articles/*.html", layout: :article_layout
page "/feed.xml", layout: false

Time.zone = "Tokyo"
Slim::Engine.set_default_options pretty: true

activate :blog do |blog|
  blog.calendar_template = "calendar.html"
  blog.paginate = false
  blog.sources = "articles/:year-:month-:day-:title.html"
  blog.tag_template = "tag.html"
end
