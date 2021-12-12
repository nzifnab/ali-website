namespace :update_blueprints do
  task go: :environment do
    CorpStock.where(blueprint_id: nil).find_each do |stock|
      stock.send(:set_blueprint_id)
      stock.save!
    end
  end
end
