require File.expand_path("../../app", __FILE__)
require "sitespec"

Sitespec.configuration.application = App

describe "This site" do
  include Sitespec

  it "provides the following files" do
    get "/2013/11/10/hello-world.html"
    get "/2013/11/15/happy-pull-request.html"
    get "/2013/11/18/sitespec.html"
    get "/2013/11/27/rack-multiplexer.html"
    get "/2013/12/01/autodoc.html"
    get "/2013/12/08/asciinema.html"
    get "/2014/01/03/transcode.html"
    get "/2014/02/01/faraday-lazyable.html"
    get "/2014/02/13/includable-yaml.html"
    get "/2014/02/13/device-specific-api-design.html"
    get "/2014/02/14/apiary.html"
    get "/2014/02/18/private-paas-beach.html"
    get "/2014/02/26/etcd.html"
    get "/2014/02/27/gitreceive.html"
    get "/2014/02/28/atom-contribution-guideline.html"
    get "/2014/03/03/rest-in-piece.html"
    get "/2014/03/12/database-encryption.html"
    get "/2014/03/13/oauth-sign.html"
    get "/2014/06/21/ghq.html"
    get "/2014/06/23/go-misc.html"
    get "/2014/06/24/discoverd.html"
    get "/2014/06/26/flynn-host.html"
    get "/2014/06/29/gitreceived.html"
    get "/images/favicon.ico"
    get "/images/r7kamura.png"
    get "/images/2013-11-10-hello-world/build-pipeline.png"
    get "/images/2013-11-15-happy-pull-request/pull-request.png"
    get "/images/2013-11-27-rack-multiplexer/onion.png"
    get "/images/2013-11-27-rack-multiplexer/benchmark.png"
    get "/images/2013-12-01-autodoc/github.png"
    get "/images/2013-12-01-autodoc/toc.png"
    get "/images/2014-02-18/dockerui.png"
    get "/images/2014-06-21/ghq.gif"
    get "/index.html"
    get "/stylesheets/all.css"
    get "/feed.xml"
  end
end
