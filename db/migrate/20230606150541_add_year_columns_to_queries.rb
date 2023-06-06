class AddYearColumnsToQueries < ActiveRecord::Migration[7.0]
  def change
    add_column :queries, :year_before, :integer
    add_column :queries, :year_after, :integer
  end
end
