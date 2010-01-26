class Album < ActiveRecord::Base     
  has_many :songs
  belongs_to :artist  
  
  attr_accessor :status
  
  def after_initialize
    @status = UNCHECKED
  end

end