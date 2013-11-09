require "slim"

set :blog_title, "r7kamura blog"
set :blog_description, "marking down about tech and journal."
set :layout_engine, :slim

page "/feed.xml", layout: false

Time.zone = "Tokyo"

activate :blog do |blog|
  # blog.day_link = ":year/:month/:day"
  # blog.layout = "layout"
  # blog.month_link = ":year/:month"
  # blog.page_link = "page/:num"
  # blog.per_page = 10
  # blog.prefix = "blog"
  # blog.summary_length = 250
  # blog.summary_separator = /(READMORE)/
  # blog.year_link = ":year"
  blog.calendar_template = "calendar.html"
  blog.paginate = false
  blog.sources = "articles/:year-:month-:day-:title.html"
  blog.tag_template = "tag.html"
end
