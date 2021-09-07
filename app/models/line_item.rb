class LineItem < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  belongs_to :corp_stock
  belongs_to :order

  validates :quantity, numericality: {greater_than: 0, message: ->(object, data){ "'Quantity' for #{object.corp_stock.item} must be greater than 0." }}
  validate :external_order_above_fulfillment_quantity

  before_create :store_metadata_snapshot

  delegate :settings, to: :order

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
      (price - blueprint_price_reduction) * settings[:contract_multiplier]
    end
  end

  def pending_stock?
    quantity > corp_stock.current_stock
  end

  def alliance_margin?
    corp_stock.ship?
  end

  # For Corp  purchases where funds were donated to corp wallet,
  # this is the amount of money the builder should withdraw from corp, given
  # they manufactured this item and contracted it direct to consumer.

  def donation_sale_personal_manufacture_withdrawal_amount
    bp_reduction = if blueprint_provided?
      purchase_price_metadata["ShipBlueprintSellPrice"].to_f
    else
      0
    end
    quantity * (purchase_price_metadata["BestBuyPriceat0.0Fulfillment"].to_f - bp_reduction)
  end

  def donation_sale_corp_manufacture_withdrawal_amount
    quantity * purchase_price_metadata["CorpMemberProfitAmount"].to_f
  end

  def contract_sale_personal_manufacture_donate_amount
    quantity * profit_margin_for(:total)
  end

  def contract_sale_corp_manufacture_withdrawal_amount
    quantity * purchase_price_metadata["CorpMemberProfitAmount"].to_f
  end


  def profit_margin_for(corp_or_alliance)
    buyer_type = (order.contract? || order.donation?) ? :corp : :external

    # Where `buyer_type` is `:corp` or `:external`
    margin_percent = settings["#{corp_or_alliance}_profit_percent".to_sym]

    if !corp_stock.ship? && corp_or_alliance == :alliance
      margin_percent = 0
    elsif (!corp_stock.ship? && corp_or_alliance == :corp) || corp_or_alliance == :total
      margin_percent = 1
    end

    # Since I changed ship sales to not mark up the bp cost with our margins, there is no need to reduce
    # the profit margin based on the bp
    bp_reduction = 0

    alliance_contract_multiplier = if corp_or_alliance == :alliance && corp_stock.ship?
      # Contracts sent to someone with only isk will immediately charge _you_ 4%,
      # so we have to reduce the contract sent by 4%
      1 - (1 - settings[:contract_multiplier]) / 2
    else
      1
    end
    [0, (purchase_price_metadata["#{buyer_type.to_s.capitalize}SaleTotalMargin"].to_f - bp_reduction) * margin_percent * alliance_contract_multiplier].max
  end

  def blueprint_price_reduction
    return 0 unless corp_stock.ship?
    return 0 unless blueprint_provided?

    bp_raw_cost = if purchase_price_metadata.blank?
      corp_stock.purchase_price_metadata["ShipBlueprintSellPrice"].to_f
    else
      purchase_price_metadata["ShipBlueprintSellPrice"].to_f
    end

    contract_modifier = (order.corp_member? ? 1 : settings[:contract_multiplier])

    return (bp_raw_cost / contract_modifier)
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
