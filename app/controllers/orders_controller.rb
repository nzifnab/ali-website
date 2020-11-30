class OrdersController < ApplicationController
  def new
    @order = Order.order_for_form
  end

  def show
    @order = Order.get(params[:id])

    if params[:token] == @order.admin_token && params[:token].present?
      # TODO: use discord authentication here instead?
      # right now the only functionality is completing the order
      # (tho it also updates corp stock)
      @admin = true
    end
  end

  def create
    @order = Order.new(order_params)

    @order.save!
    redirect_to order_path(@order.token)
  end

  def index
    @orders = Order.preload(:line_items).left_outer_joins(:stock_modifier_queue).where("stock_modifier_queues.executed_at IS NULL").order(id: :asc)
  end

  def complete
    @order = Order.find(params[:id])

    if @order.admin_token == params[:token] && params[:token].present?
      @order.complete!
      redirect_to order_path(@order.token)
    else
      render action: 'show', notice: "Not authorized"
    end
  end

  private
  def order_params
    params.require(:order).permit(
      :player_name,
      line_items_attributes: [
        :corp_stock_id,
        :price,
        :quantity
      ]
    )
  end
end
