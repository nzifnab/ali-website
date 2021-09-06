class OrdersController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include OrdersHelper

  def new
    @order = Order.order_for_form(!corp_member?)
  end

  def show
    @order = Order.get(params[:id])

    @admin = true

    @og_title = "Order for #{isk_currency(@order.total)} isk"
    desc = []
    @order.line_items.each do |li|
      desc << "#{li.corp_stock.item} x #{number_with_delimiter(li.quantity)}: #{isk_currency(li.total)}"
    end
    @og_description = desc.join("\n")
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

    @orders = Order.filter(@status).preload(:line_items).order(created_at: :desc)
  end

  def destroy
    @order = Order.find(params[:id])

    if @order.pending?
      @order.cancel!
      redirect_to order_path(@order.token, token: @order.admin_token)
    else
      render action: 'show', notice: "Not authorized"
    end
  end

  def complete
    @order = Order.find(params[:id])

    if @order.pending?
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
