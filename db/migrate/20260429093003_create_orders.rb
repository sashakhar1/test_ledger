class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true

      t.bigint :amount_cents, null: false
      t.string :currency, null: false, default: "USD"

      # State machine: created -> paid -> cancelled, or created -> cancelled.
      # Application-level transitions enforced in Order#transition_to!.
      t.string :status, null: false, default: "created"

      # Links into the ledger. Both nullable: a never-paid order has no entry,
      # a created->cancelled order has no cancellation entry either.
      t.references :paid_journal_entry,
                   foreign_key: { to_table: :journal_entries }
      t.references :cancellation_journal_entry,
                   foreign_key: { to_table: :journal_entries }

      t.timestamps
    end

    add_index :orders, :status
  end
end
