Time.zone = "Tokyo"

activate :blog do |blog|
  blog.calendar_template = "calendar.html"
  blog.tag_template = "tag.html"
  # blog.day_link = ":year/:month/:day.html"
  # blog.default_extension = ".markdown"
  # blog.layout = "layout"
  # blog.month_link = ":year/:month.html"
  # blog.page_link = "page/:num"
  # blog.paginate = true
  # blog.per_page = 10
  # blog.permalink = ":year/:month/:day/:title.html"
  # blog.prefix = "blog"
  # blog.sources = ":year-:month-:day-:title.html"
  # blog.summary_length = 250
  # blog.summary_separator = /(READMORE)/
  # blog.taglink = "tags/:tag.html"
  # blog.year_link = ":year.html"
end

page "/feed.xml", :layout => false

set :css_dir, "stylesheets"
set :images_dir, "images"
set :js_dir, "javascripts"
