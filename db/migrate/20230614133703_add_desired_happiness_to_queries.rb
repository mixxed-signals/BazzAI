class AddDesiredHappinessToQueries < ActiveRecord::Migration[7.0]
  def change
    add_column :queries, :desired_happiness, :integer
  end
end
