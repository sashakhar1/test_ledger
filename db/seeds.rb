puts "Creating demo users..."
sasha    = User.find_or_create_by!(email: "sasha@aurospace.test")
maxim    = User.find_or_create_by!(email: "maxim@aurospace.test")
viktoria = User.find_or_create_by!(email: "viktoria@aurospace.test")

puts "Creating user wallets and system accounts..."
[sasha, maxim, viktoria].each do |user|
  Account.find_or_create_by!(user: user, kind: "user_wallet")
end
Account.find_or_create_by!(user: nil, kind: "system_revenue")
Account.find_or_create_by!(user: nil, kind: "system_clearing")

puts "Scenario 1: Sasha pays for a 15.00 order (happy path)..."
sasha_order = Order.create!(user: sasha, amount_cents: 1_500)
PayOrderService.call(order: sasha_order)

puts "Scenario 2: Maxim pays for a 50.00 order, then it is cancelled (storno cycle)..."
maxim_order = Order.create!(user: maxim, amount_cents: 5_000)
PayOrderService.call(order: maxim_order)
CancelOrderService.call(order: maxim_order)

puts "Scenario 3: Viktoria cancels her 20.00 order before paying (no postings)..."
viktoria_order = Order.create!(user: viktoria, amount_cents: 2_000)
CancelOrderService.call(order: viktoria_order)

puts ""
puts "Final state:"
puts "  Users:          #{User.count}"
puts "  Accounts:       #{Account.count}"
puts "  Orders:         #{Order.count}"
puts "  JournalEntries: #{JournalEntry.count}"
puts "  Postings:       #{Posting.count}"
puts ""
[sasha, maxim, viktoria].each do |user|
  wallet = user.accounts.find_by(kind: "user_wallet")
  puts "  #{user.email.ljust(28)} wallet balance: #{wallet.balance_cents} cents"
end
puts ""
puts "  Sasha's order ##{sasha_order.id}:    #{sasha_order.reload.status}"
puts "  Maxim's order ##{maxim_order.id}:    #{maxim_order.reload.status} (paid then cancelled, storno JE created)"
puts "  Viktoria's order ##{viktoria_order.id}: #{viktoria_order.reload.status} (no JE created)"
