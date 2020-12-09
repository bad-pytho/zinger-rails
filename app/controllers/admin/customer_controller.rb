class Admin::CustomerController < AdminController
  before_action :set_title
  before_action :load_customer, except: :index

  def index
    @title = 'Customers'
    if params['q'].present?
      @customers = if params['q'].match(EMAIL_REGEX)
        Customer.unscoped.where(email: params['q'])
      elsif params['q'].match(MOBILE_REGEX)
        Customer.unscoped.where(mobile: params['q'])
      else
        Customer.unscoped.where(id: params['q'])
      end
    end
  end

  def update
    @customer.update(name: params['name'], status: params['status'])
    if @customer.errors.any?
      flash[:error] = @customer.errors.messages.values.flatten.first
    else
      flash[:success] = 'Update is successful'
    end
    
    redirect_to customer_index_path(q: params['id'])
  end

  def destroy
    @customer.update!(deleted: true)
    redirect_to customer_index_path(q: params['id'])
  end

  def set_title
    @header = { links: [] }
  end

  def load_customer
    @customer = Customer.fetch_by_id(params['id'])
    if @customer.nil?
      flash[:error] = 'Customer is not found'
      return redirect_to customer_index_path(q: params['id'])
    end
  end
end
