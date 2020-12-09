class Admin::RoleController < AdminController
  before_action :set_title
  before_action :load_role, except: [:index, :create, :add_role]

  def index
    @header[:title] = 'Access Control'
    @header[:links].map{ |link| link[:active] = false }
    @roles = Shop.find_by_id(params['id']).roles
    @error = nil
  end

  def create
  end

  def show
    @header[:title] = @role.name
    @header[:links].map{ |link| link[:active] = false }
  end

  def add_role
    @header[:title] = 'Add New Role'
    @header[:links].map{ |link| link[:active] = false }
    @header[:links][0][:active] = true
  end

  def update
    @role.update(name: params['name'], privileges: [1, 2])
    if @role.errors.any?
      flash[:error] = @role.errors.messages.values.flatten.first
    else
      flash[:success] = 'Role update is successful'
    end
    redirect_to role_index_path(id: params['id'])
  end

  def destroy
    @role.destroy!
    redirect_to role_index_path(id: params['id'])
  end

  private

  def set_title
    @header = { links: [ { title: 'Add Role', path: add_role_role_index_path } ] }
  end

  def load_role
    @role = Shop.find_by_id(params['id']).roles.fetch_by_id(params['role_id'])
    if @role.nil?
      flash[:error] = 'Role is not found'
      return redirect_to role_index_path(id: params['id'])
    end
  end
end
