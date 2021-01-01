class LineItem < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  belongs_to :corp_stock
  belongs_to :order

  validates :quantity, numericality: {greater_than: 0, message: ->(object, data){ "'Quantity' for #{object.corp_stock.item} must be greater than 0." }}
  validate :external_order_above_fulfillment_quantity

  before_create :store_metadata_snapshot

  def total
    price * quantity
  end

  def price_without_contract_fee
    # Perhaps mistakenly, contract/AL orders don't include contract fee
    # in this total, but external orders do. So we'll subtract contract fee from
    # only the external ones :P
    if order.contract?
      price - blueprint_price_reduction
    else
      (price - blueprint_price_reduction) * 0.92
    end
  end

  def pending_stock?
    quantity > corp_stock.current_stock
  end

  def corp_member_manufacturing_withdrawal_fee
    bp_reduction = if blueprint_provided?
      purchase_price_metadata["ShipBlueprintSellPrice"].to_f
    else
      0
    end
    purchase_price_metadata["BestBuyPriceat0.0Fulfillment"].to_f - bp_reduction
  end

  def corp_margin(type)
    if type == :external
      bp_reduction = if blueprint_provided?
        # This 0.08 is the corp margin on external ship sales
        purchase_price_metadata["ShipBlueprintSellPrice"].to_f * 0.08
      else
        0
      end

      # breakeven = y
      # external = y * 1.08 / 0.92

      # external * 0.92 - breakeven
      # (y * 1.08 / 0.92) * 0.92 - y
      # y * 1.08 - y
      # 1.08y - y
      # 0.08y

      # For the corp margin, first we take off the contract fee, then
      # we subtract the BreakEvenSalePrice amount, then we remove any amount
      # the blueprint would've added, if the customer is supplying it.
      purchase_price_metadata["ExternalSalePrice"].to_f * 0.92 - purchase_price_metadata["BreakEvenSalePrice"].to_f - bp_reduction
    else
      bp_reduction = if blueprint_provided?
        # This 0.04 is the corp margin on internal/corp ship sales.
        purchase_price_metadata["ShipBlueprintSellPrice"].to_f * 0.04
      else
        0
      end
      # For AL purchases, we can use the CorpMemberSaleCorpMargin
      # which is just taking the corp member sale price (already has contract
      # fee removed) minus the break even sale price
      purchase_price_metadata["CorpMemberSaleCorpMargin"].to_f - bp_reduction
    end
  end

  def blueprint_price_reduction
    return 0 unless corp_stock.ship?
    return 0 unless blueprint_provided?

    bp_raw_cost = if purchase_price_metadata.blank?
      corp_stock.purchase_price_metadata["ShipBlueprintSellPrice"].to_f
    else
      purchase_price_metadata["ShipBlueprintSellPrice"].to_f
    end

    sale_modifier = (order.corp_member? ? 1.04 : 1.08)
    contract_modifier = (order.corp_member? ? 1 : 0.92)

    return (bp_raw_cost * sale_modifier / contract_modifier)
  end

  private

  # validate
  def external_order_above_fulfillment_quantity
    # Fulfillment restriction never applies for ships, or corp members (AL or ALI)
    # Or if the 'desired stock' is 0, let the order go to negative and we'll
    # work on collecting it (IE: morphite)
    return if corp_stock.ship?
    return if order.corp_member?
    return if corp_stock.desired_stock <= 0

    # The quantity of this resource that is in current
    # pending orders
    outstanding_quantities = LineItem.joins(:order).
      where(orders: {status: "pending"}).
      where(corp_stock_id: corp_stock_id).
      sum(:quantity)

    buyable_amount = if corp_stock.blueprint?
      # Blueprints can be sold all the way down to 0
      [0, corp_stock.current_stock - outstanding_quantities].max.to_i
    else
      # Anything else can only be sold down to `DesiredStock`
      [0, (corp_stock.current_stock - outstanding_quantities) - corp_stock.desired_stock].max.to_i
    end

    # Do not allow the purchase of resources that would bring it's quantity (when added
    # to other outstanding orders) to fall below our fulfillment % (desired_stock)
    if buyable_amount == 0 && quantity > 0
      errors.add(:quantity, "Other orders have claimed our remaining stock of #{corp_stock.item}, this item has been removed from your order. You may submit again if this is acceptable or contact us on discord.")
      self.quantity = nil
    elsif quantity > buyable_amount
      errors.add(:quantity, "You cannot order more than #{number_with_delimiter(buyable_amount)} #{corp_stock.item} due to our current levels of stock. The quantity has been adjusted automatically to this maximum amount, you may submit again if acceptable.")
      self.quantity = buyable_amount
    end
  end

  # before_create
  # Captures the purchase price metadata at the point that this entry was created, so that later
  # changes won't affect what's displayed.
  def store_metadata_snapshot
    self.purchase_price_metadata = corp_stock.purchase_price_metadata
  end
end
