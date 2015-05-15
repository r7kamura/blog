require File.expand_path("../../app", __FILE__)
require "sitespec/rspec"

describe "This site", :sitespec do
  let(:app) do
    App
  end

  %w[
    /
    /2013/11/10/hello-world
    /2013/11/15/happy-pull-request
    /2013/11/18/sitespec
    /2013/11/27/rack-multiplexer
    /2013/12/01/autodoc
    /2013/12/08/asciinema
    /2014/01/03/transcode
    /2014/02/01/faraday-lazyable
    /2014/02/13/device-specific-api-design
    /2014/02/13/includable-yaml
    /2014/02/14/apiary
    /2014/02/18/private-paas-beach
    /2014/02/26/etcd
    /2014/02/27/gitreceive
    /2014/02/28/atom-contribution-guideline
    /2014/03/03/rest-in-piece
    /2014/03/12/database-encryption
    /2014/03/13/oauth-sign
    /2014/06/21/ghq
    /2014/06/23/go-misc
    /2014/06/24/discoverd
    /2014/06/26/flynn-host
    /2014/06/29/gitreceived
    /2014/06/30/sql-translator
    /2014/07/10/scheman
    /2014/07/16/slugbuilder
    /2014/07/17/flynn-overview
    /2014/07/20/golang-reverse-proxy
    /2014/08/01/atom-git-integration
    /2014/08/03/as-standard-function-keys
    /feed.xml
    /images/2013-11-10-hello-world/build-pipeline.png
    /images/2013-11-15-happy-pull-request/pull-request.png
    /images/2013-11-27-rack-multiplexer/benchmark.png
    /images/2013-11-27-rack-multiplexer/onion.png
    /images/2013-12-01-autodoc/github.png
    /images/2013-12-01-autodoc/toc.png
    /images/2014-02-18/dockerui.png
    /images/2014-06-21/ghq.gif
    /images/2014-07-10/database_name.png
    /images/2014-07-10/space.png
    /images/2014-07-10/sql.png
    /images/2014-07-10/uml.png
    /images/2014-07-17/flynn-overview.png
    /images/favicon.ico
    /images/r7kamura.png
    /stylesheets/all.css
  ].each do |path|
    describe "GET #{path}" do
      subject do
        get(path)
      end

      it "returns 200" do
        expect(subject.status).to eq 200
      end
    end
  end
end
