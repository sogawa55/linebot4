class CreateLastDialogues < ActiveRecord::Migration
  def change
    create_table :last_dialogues do |t|
      t.string :mid
      t.string :mode
      t.integer :da
      t.string :context

      t.timestamps null: false
    end
  end
end
