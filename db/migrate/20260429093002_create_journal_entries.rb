class CreateJournalEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :journal_entries do |t|
      # DB-level idempotency: duplicate inserts (retry, double-click, worker
      # restart) are rejected by the unique index, not by application logic.
      t.string :idempotency_key, null: false

      t.string :memo

      # Self-reference: storno (reversing entry) points to the original entry.
      # Unique because one entry can only be reversed once.
      t.references :reverses_journal_entry,
                   foreign_key: { to_table: :journal_entries },
                   index: { unique: true }

      # Polymorphic source: the business object that triggered this entry
      # (Order in this codebase; could be Subscription, Payout, Adjustment).
      t.string :source_type
      t.bigint :source_id

      # Effective accounting date, separate from created_at. Storno's posted_at
      # is the day of cancellation, not the day of the original transaction.
      t.datetime :posted_at, null: false

      t.timestamps
    end

    add_index :journal_entries, :idempotency_key, unique: true
    add_index :journal_entries, [:source_type, :source_id]
  end
end
