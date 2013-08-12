class SitemapController < ApplicationController
	def index
		redirect_to sitemap_index
	end

	def sitemap
		redirect_to sitemap_url
	end
end

def sitemap_index
	"http://#{CarrierWave::Uploader::Base.fog_directory}.s3.amazonaws.com/sitemaps/sitemap_index.xml.gz"
end

def sitemap_url
	"http://#{CarrierWave::Uploader::Base.fog_directory}.s3.amazonaws.com/sitemaps/sitemap1.xml.gz"
end