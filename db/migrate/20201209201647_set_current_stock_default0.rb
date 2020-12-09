class SetCurrentStockDefault0 < ActiveRecord::Migration[6.0]
  def change
    change_column_default :corp_stocks, :current_stock, 0
    CorpStock.where(current_stock: nil).update_all(:current_stock => 0)
    change_column_null :corp_stocks, :current_stock, false
  end
end
