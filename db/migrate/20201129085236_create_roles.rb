class CreateRoles < ActiveRecord::Migration[5.2]
  def change
    create_table :roles do |t|
      t.string :name
      t.column :shop_id, 'BIGINT'
      t.integer :privileges, array: true, default: []
      t.timestamps

      t.index [:id, :shop_id]
      t.index [:name, :shop_id]
    end
  end
end
