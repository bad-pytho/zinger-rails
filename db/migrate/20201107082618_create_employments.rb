class CreateEmployments < ActiveRecord::Migration[6.0]
  def change
    create_table :employments, id: false do |t|
      t.belongs_to :employee
      t.belongs_to :shop
      t.timestamps
    end
  end
end
