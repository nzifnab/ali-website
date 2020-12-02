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
    @orders = Order.preload(:line_items).order(id: :asc)

    @status = params[:status]
    @status ||= "pending"

    # Don't want to just insert @status straight into the query
    # because a user could submit whatever and maybe we dont' want that.
    if @status == "complete"
      @orders = @orders.where(status: "complete")
    elsif @status == "cancelled"
      @orders = @orders.where(status: "cancelled")
    else
      @orders = @orders.where(status: "pending")
    end
  end

  def destroy
    @order = Order.find(params[:id])

    if @order.admin_token == params[:token] && params[:token].present? && @order.pending?
      @order.cancel!
      redirect_to order_path(@order.token, token: @order.admin_token)
    else
      render action: 'show', notice: "Not authorized"
    end
  end

  def complete
    @order = Order.find(params[:id])

    if @order.admin_token == params[:token] && params[:token].present? && @order.pending?
      @order.complete!
      redirect_to order_path(@order.token, token: @order.admin_token)
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
