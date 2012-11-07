class Article < ActiveRecord::Base
  belongs_to :issue
  attr_accessible :author, :body, :publication, :teaser, :title, :trialarticle, :keynote

  include Tire::Model::Search
  include Tire::Model::Callbacks

  # Index name for Heroku Bonzai/elasticsearch
  index_name BONSAI_INDEX_NAME

  # Doesn't seem to list all of the articles when no params.
  # def self.search(params)
  #   tire.search(load: true) do
  #     query { string params[:query]} if params[:query].present?
  #   end
  # end

  # Setting up SOAP to import articles from Bricolage using Savon
  def import_articles_from_bricolage(bric_date)
    client = Savon::Client.new("https://bric-new.newint.org/soap?WSDL")
    client.http.auth.ssl.verify_mode = :none
    client.wsse_auth ENV["BRICOLAGE_USERNAME"], ENV["BRICOLAGE_PASSWORD"] #, :digest
    # TODO: Make this work with Bric Soap
    # response = client.request :web, :get_info_by_zip, body: { "USZip" => zip }
  end

end
