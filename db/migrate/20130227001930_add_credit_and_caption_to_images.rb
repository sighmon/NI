class AddCreditAndCaptionToImages < ActiveRecord::Migration
  def change
    add_column :images, :credit, :string
    add_column :images, :caption, :text
  end
end
