class CreatePostings < ActiveRecord::Migration[8.0]
  def change
    create_table :postings do |t|
      t.references :journal_entry, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :direction, null: false
      t.bigint :amount_cents, null: false
      t.string :currency, null: false
      t.datetime :created_at, null: false
    end

    add_index :postings, [:account_id, :created_at]
  end
end
