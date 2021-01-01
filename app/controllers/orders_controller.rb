class OrdersController < ApplicationController
  def new
    @order = Order.order_for_form(!corp_member?)
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

    if @order.save
      redirect_to order_path(@order.token)
    else
      @order.rebuild_for_form(!corp_member?)
      render action: :new
    end
  end

  def index
    @status = params[:status]
    @status ||= "pending"

    @orders = Order.filter(@status).preload(:line_items).order(id: :asc)
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
    prm = params.require(:order).permit(
      :player_name,
      :corp_member_type,
      line_items_attributes: [
        :corp_stock_id,
        :price,
        :quantity,
        :blueprint_provided
      ]
    )

    if corp_member?
      # Don't trust what users send. If they have the corp member cookie they may choose
      # between AL (contracted items), or ALI (corp donation + free contract + audit timer)
      prm[:corp_member_type] = (prm[:corp_member_type] == "donation" ? 'donation' : "contract")
    else
      prm[:corp_member_type] = 'external'
    end
    prm
  end
end
