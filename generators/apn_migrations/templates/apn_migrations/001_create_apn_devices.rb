class CreateApnDevices < ActiveRecord::Migration # :nodoc:
  def self.up
    create_table :apn_devices do |t|
      t.text :token, :size => 100, :null => false
      t.datetime :last_registered_at
      t.timestamps
    end
    add_index :apn_devices, :token, :unique => true
  end

  def self.down
    remove_index :apn_devices, :column => :token
    drop_table :apn_devices
  end
end
