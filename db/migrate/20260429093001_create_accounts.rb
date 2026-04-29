class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.references :user, foreign_key: true
      t.string :kind, null: false
      t.string :currency, null: false, default: "USD"
      t.bigint :balance_cents, null: false, default: 0

      t.timestamps
    end

    add_index :accounts, [:user_id, :kind]
  end
end
