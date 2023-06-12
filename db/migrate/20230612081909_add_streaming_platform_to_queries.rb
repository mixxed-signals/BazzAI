class AddStreamingPlatformToQueries < ActiveRecord::Migration[7.0]
  def change
    add_column :queries, :streaming_platform, :string
  end
end
