class SitemapController < ApplicationController
	def index
		redirect_to sitemap_index
	end
end

def sitemap_index
	"http://#{CarrierWave::Uploader::Base.fog_directory}.s3.amazonaws.com/sitemaps/sitemap.xml.gz"
end