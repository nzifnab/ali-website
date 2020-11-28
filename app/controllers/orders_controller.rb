class OrdersController < ApplicationController
  def new
    @order = Order.order_for_form
  end

  def show
  end
end
