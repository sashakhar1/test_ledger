class CreateJournalEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :journal_entries do |t|
      t.string :idempotency_key, null: false
      t.string :memo
      t.references :reverses_journal_entry,
                   foreign_key: { to_table: :journal_entries },
                   index: { unique: true }
      t.string :source_type
      t.bigint :source_id
      t.datetime :posted_at, null: false

      t.timestamps
    end

    add_index :journal_entries, :idempotency_key, unique: true
    add_index :journal_entries, [:source_type, :source_id]
  end
end
