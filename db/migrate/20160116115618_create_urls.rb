class CreateUrls < ActiveRecord::Migration
  def change
    create_table :urls do |t|
      t.text :twitter_uri
      t.text :url

      t.timestamps null: false
    end
  end
end
