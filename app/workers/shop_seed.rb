class ShopSeed
  include Sidekiq::Worker

  def perform shop_id
    shop = Shop.find_by_id(shop_id)
    return if shop.nil?

    # TODO - Send welcome email
    # TODO - Create employees
    
    Role::DEFAULT_ROLES.each do |name, privileges|
      role = shop.roles.new(name: name, privileges: privileges)
      role.save(validate: false)
    end
  end
end
