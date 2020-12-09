class Role < ApplicationRecord
  PRIVILEGE_LIST = {
    'CUSTOMER_READ' => 1, 'CUSTOMER_UPDATE' => 2, 'CUSTOMER_DELETE' => 3, 
    'SHOP_CREATE' => 4, 'SHOP_READ' => 5, 'SHOP_UPDATE' => 6, 'SHOP_DELETE' => 7, 
    'ROLE_CREATE' => 8, 'ROLE_READ' => 9, 'ROLE_UPDATE' => 10, 'ROLE_DELETE' => 11
  }
  PRIVILEGE_KEYS = PRIVILEGE_LIST.invert

  PRIVILEGE_TEXT = {
    1 => 'View Customer Profile', 2 => 'Update Customer Profile', 3 => 'Delete Customer Profile', 
    4 => 'Add New Shop', 5 => 'View Shop Profile', 6 => 'Update Shop Profile', 7 => 'Delete Shop Profile', 
    8 => 'Add New Role', 9 => 'View Role Details', 10 => 'Update Role Details', 11 => 'Delete Role'
  }

  DEPENDENCIES = {
    PRIVILEGE_LIST['CUSTOMER_UPDATE'] => PRIVILEGE_LIST['CUSTOMER_READ'],
    PRIVILEGE_LIST['CUSTOMER_DELETE'] => PRIVILEGE_LIST['CUSTOMER_READ'],
    PRIVILEGE_LIST['SHOP_CREATE'] => PRIVILEGE_LIST['SHOP_READ'],
    PRIVILEGE_LIST['SHOP_UPDATE'] => PRIVILEGE_LIST['SHOP_READ'],
    PRIVILEGE_LIST['SHOP_DELETE'] => PRIVILEGE_LIST['SHOP_READ'],
    PRIVILEGE_LIST['ROLE_CREATE'] => PRIVILEGE_LIST['ROLE_READ'],
    PRIVILEGE_LIST['ROLE_UPDATE'] => PRIVILEGE_LIST['ROLE_READ'],
    PRIVILEGE_LIST['ROLE_DELETE'] => PRIVILEGE_LIST['ROLE_READ']
  }

  DEFAULT_ROLES = {
    'Shop Owner' => [PRIVILEGE_LIST['CUSTOMER_READ'], PRIVILEGE_LIST['CUSTOMER_UPDATE'], PRIVILEGE_LIST['CUSTOMER_DELETE'], 
      PRIVILEGE_LIST['SHOP_READ'], PRIVILEGE_LIST['SHOP_UPDATE'], PRIVILEGE_LIST['ROLE_CREATE'], PRIVILEGE_LIST['ROLE_READ'], 
      PRIVILEGE_LIST['ROLE_UPDATE'], PRIVILEGE_LIST['ROLE_DELETE']],

    'Employee' => [PRIVILEGE_LIST['CUSTOMER_READ'], PRIVILEGE_LIST['CUSTOMER_UPDATE'], PRIVILEGE_LIST['CUSTOMER_DELETE'], 
      PRIVILEGE_LIST['SHOP_READ'], PRIVILEGE_LIST['ROLE_READ']],

    'Delivery' => [PRIVILEGE_LIST['CUSTOMER_READ'], PRIVILEGE_LIST['SHOP_READ'], PRIVILEGE_LIST['ROLE_READ']]
  }

  NAME_REGEX = /^[A-Za-z0-9 ]+$/

  validate :create_validations, on: :create
  validate :save_validations
  before_update :save_model_changes
  after_update_commit :set_privileges
  after_commit :clear_cache

  has_many :employments
  has_many :employees, through: :employments
  belongs_to :shop

  def as_json purpose = nil
    case purpose
    when 'admin_role'
      return { id: self.id, name: self.name }
    end
  end

  def privileges_as_int
    self.privileges.inject(0) { |result, privilege| 2**privilege | result }
  end

  def self.fetch_by_id id
    Core::Redis.fetch(Core::Redis::ROLE_BY_ID % { id: id }, { type: Role }) { Role.find_by_id(id) }
  end

  def self.verify employee_privileges, controller, action
    privilege_key = PrivilegeConfig[controller].to_h[action]
    return true if privilege_key.nil?

    privilege = PRIVILEGE_LIST[privilege_key]
    return (employee_privileges & 2**privilege) > 0
  end

  private

  def create_validations
    role_limit = PlatformConfig['role_limit']
    errors.add(:role, I18n.t('role.validation.limit_reached', limit: role_limit)) if self.shop.roles.count >= role_limit
  end

  def save_validations
    self.name = self.name.to_s.strip
    return errors.add(:name, I18n.t('validation.required', param: 'Name')) if self.name.blank?
    return errors.add(:name, I18n.t('validation.invalid', param: 'name')) unless self.name.match(NAME_REGEX)

    if self.changes[:name].present?
      name_changes = self.changes[:name].map { |value| value.to_s.downcase }
      errors.add(:name, I18n.t('role.validation.already_exist', value: self.name)) if name_changes[0] != name_changes[1] && 
        self.shop.roles.exists?(['lower(name) = ?', name_changes[1]])
    end

    self.privileges = self.privileges.sort.uniq
    errors.add(:privileges, I18n.t('validation.required', param: 'Privileges')) if self.privileges.blank?
    missing = self.privileges.map do |privilege|
      PRIVILEGE_TEXT[DEPENDENCIES[privilege]] if DEPENDENCIES[privilege].present? && !self.privileges.include?(DEPENDENCIES[privilege])
    end.compact
    errors.add(:privileges, "Missing dependent #{'privilege'.pluralize(missing.length)}: #{missing.join(', ')}") if missing.present?
  end

  def save_model_changes
    @model_changes = self.changes
  end

  def set_privileges
    SetEmployeePrivileges.perform_async(self.id) if @model_changes.to_h['privileges'].present?
  end

  def clear_cache
    Core::Redis.delete(Core::Redis::ROLE_BY_ID % { id: self.id })
  end
end
