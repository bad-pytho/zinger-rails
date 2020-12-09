class SetEmployeePrivileges
  include Sidekiq::Worker

  def perform(role_id)
    role = Role.find_by_id(role_id)
    return if role.nil?

    role.employees.each { |employee| employee.update(privileges: role.privileges_as_int) }
  end
end
