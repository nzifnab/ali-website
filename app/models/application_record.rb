class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def to_bool(val)
    ActiveModel::Type::Boolean.new.cast(val)
  end
end
