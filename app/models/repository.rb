class Repository < ApplicationRecord
  USPSTF = 'USPSTF'
  
  def self.uspstf!
    where("name = ?", USPSTF).first!
  end
end
