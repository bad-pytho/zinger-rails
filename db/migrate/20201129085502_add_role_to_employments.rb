class AddRoleToEmployments < ActiveRecord::Migration[6.0]
  def up
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE employments
        ADD COLUMN role_id BIGINT,
        ADD COLUMN privileges BIGINT"
    )
  end

  def down
    ActiveRecord::Base.connection.execute(
      "ALTER TABLE employments 
        DROP COLUMN privileges, 
        DROP COLUMN role_id"
    )
  end
end
