class CreateApnFeedbacks < ActiveRecord::Migration # :nodoc:
  
  def self.up
    create_table :apn_feedbacks do |t|
      t.string :code
      t.string :message
      t.text :body
      t.string :state
      t.timestamps
    end
  end

  def self.down
    drop_table :apn_feedbacks
  end
  
end