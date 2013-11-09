require "slim"

set :blog_title, "r7kamura"
set :build_dir, "blog"
set :layout_engine, :slim

page "/feed.xml", layout: false

Time.zone = "Tokyo"

activate :blog do |blog|
  blog.calendar_template = "calendar.html"
  blog.day_link = ":year/:month/:day"
  blog.month_link = ":year/:month"
  blog.permalink = ":year/:month/:day/:title"
  blog.sources = "articles/:year-:month-:day-:title.html"
  blog.tag_template = "tag.html"
  blog.taglink = "tags/:tag"
  blog.year_link = ":year"
  blog.paginate = false
  # blog.layout = "layout"
  # blog.page_link = "page/:num"
  # blog.per_page = 10
  # blog.prefix = "blog"
  # blog.summary_length = 250
  # blog.summary_separator = /(READMORE)/
end
