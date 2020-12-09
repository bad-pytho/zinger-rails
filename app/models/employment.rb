class Employment < ApplicationRecord
  belongs_to :employee
  belongs_to :shop
  belongs_to :role
end
