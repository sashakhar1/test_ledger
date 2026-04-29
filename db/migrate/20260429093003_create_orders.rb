class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :amount_cents, null: false
      t.string :currency, null: false, default: "USD"
      t.string :status, null: false, default: "created"
      t.references :paid_journal_entry,
                   foreign_key: { to_table: :journal_entries }
      t.references :cancellation_journal_entry,
                   foreign_key: { to_table: :journal_entries }

      t.timestamps
    end

    add_index :orders, :status
  end
end
