class CreatePostings < ActiveRecord::Migration[8.0]
  def change
    create_table :postings do |t|
      t.references :journal_entry, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true

      # 'debit' or 'credit'. Sign is encoded in direction, not in amount.
      t.string :direction, null: false

      # Always positive. The (account.kind, direction) pair determines whether
      # this posting increases or decreases the account balance.
      t.bigint :amount_cents, null: false

      t.string :currency, null: false

      # Postings are immutable, so updated_at is intentionally absent.
      t.datetime :created_at, null: false
    end

    # Composite index for "balance of account X over period Y" queries.
    add_index :postings, [:account_id, :created_at]
  end
end
