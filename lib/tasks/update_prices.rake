namespace :update_prices do
  desc "Update stock & prices in the DB based on the ALI Market spreadsheet"
  task go: :environment do
    CorpStock.update_from_spreadsheet!
    # StockModifierQueue.run!
  end

end
