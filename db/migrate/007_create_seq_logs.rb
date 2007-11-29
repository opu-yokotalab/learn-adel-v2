class CreateSeqLogs < ActiveRecord::Migration
  def self.up
    create_table :seq_logs do |t|
      t.column :user_id, :integer
      t.column :ent_seq_id, :integer
      t.column :created_on, :timestamp
    end
  end

  def self.down
    drop_table :seq_logs
  end
end
