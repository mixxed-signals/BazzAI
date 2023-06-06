class AddOtherYearColumnsToQueries < ActiveRecord::Migration[7.0]
  def change
    add_column :queries, :year_option, :integer
  end
end
