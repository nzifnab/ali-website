class AddBlueprintProvidedToLineItem < ActiveRecord::Migration[6.0]
  def change
    add_column :line_items, :blueprint_provided, :boolean, null: false, default: false

    add_column :corp_stocks, :blueprint_id, :integer

    add_column :corp_stocks, :visible, :boolean, null: false, default: true

    CorpStock.last_run_entry.update_column(:visible, false)

    CorpStock.all.each do |stock|
      if stock.ship?
        stock.set_blueprint_id
        stock.save!
      end
    end
  end
end
