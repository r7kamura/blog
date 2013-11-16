require "padrino"
require "redcarpet"
require "sass"
require "slim"
require "yaml"

class App < Padrino::Application
  register Padrino::Helpers
  register Padrino::Rendering
  use Rack::Static, urls: ["/images"]

  set :author, "r7kamura"
  set :blog_description, "marking down about tech."
  set :blog_title, "r7kamura blog"
  set :scss, views: "#{root}/stylesheets", load_paths: ["#{root}/stylesheets"]
  set :show_exceptions, false
  set :site_url, "http://r7kamura.github.io/"
  set :slim, pretty: true

  disable :logging

  get "/stylesheets/all.css" do
    content_type "text/css"
    scss :all
  end

  get "/index.html" do
    articles = Dir.glob("#{articles_path}/*.md").sort.reverse.map {|path| Article.new(path) }
    slim :index, locals: { articles: articles }
  end

  get "/:year/:month/:day/:title.html" do
    path = "#{articles_path}/#{params[:year]}-#{params[:month]}-#{params[:day]}-#{params[:title]}.md"
    matters = {}
    content = File.read(path).sub(/\A(---\s*\n.*?\n?)^---\s*$\n?/m) { matters = YAML.load($1); "" }
    slim :show, locals: matters.merge(body: markdown(content))
  end

  error do |exception|
    raise exception
  end

  helpers do
    def articles_path
      "#{settings.root}/articles"
    end
  end

  class Article
    def initialize(path)
      @path = path
    end

    def title
      File.basename(segments[3], ".md")
    end

    def date
      Date.new(*segments[0, 3].map(&:to_i))
    end

    def path
      "/#{date.year}/#{date.month}/#{date.day}/#{title}.html"
    end

    private

    def segments
      @segments ||= File.basename(@path).split("-", 4)
    end
  end
end
