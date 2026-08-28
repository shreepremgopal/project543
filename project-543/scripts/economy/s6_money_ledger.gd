class_name S6MoneyLedger
extends RefCounted

var opening_balance: int = 0
var balance: int = 0
var transactions: Array[S6MoneyTransaction] = []


func _init(initial_balance: int = 0) -> void:
	if initial_balance < 0:
		push_error(
			"S6MoneyLedger cannot start with negative balance"
		)

		opening_balance = 0
		balance = 0
	else:
		opening_balance = initial_balance
		balance = initial_balance


func can_afford(amount: int) -> bool:
	if amount < 0:
		return false

	return balance >= amount


func record_transaction(
	source: String,
	amount: int,
	turn: int,
	reason: String,
	transaction_type: String
) -> bool:
	if source.strip_edges().is_empty():
		return false

	if amount == 0:
		return false

	if turn < 1:
		return false

	if reason.strip_edges().is_empty():
		return false

	if not S6MoneyTransaction.TYPES.values().has(
		transaction_type
	):
		return false

	var new_balance: int = balance + amount

	if new_balance < 0:
		return false

	var transaction: S6MoneyTransaction = (
		S6MoneyTransaction.new(
			source,
			amount,
			turn,
			reason,
			transaction_type
		)
	)

	if not transaction.is_valid():
		return false

	balance = new_balance
	transactions.append(transaction)

	return true


func spend(
	source: String,
	amount: int,
	turn: int,
	reason: String,
	transaction_type: String = S6MoneyTransaction.TYPES.CAMPAIGN_SPEND
) -> bool:
	if amount <= 0:
		return false

	if not can_afford(amount):
		return false

	return record_transaction(
		source,
		-amount,
		turn,
		reason,
		transaction_type
	)


func receive(
	source: String,
	amount: int,
	turn: int,
	reason: String,
	transaction_type: String
) -> bool:
	if amount <= 0:
		return false

	return record_transaction(
		source,
		amount,
		turn,
		reason,
		transaction_type
	)


func total_income() -> int:
	var total: int = 0

	for transaction: S6MoneyTransaction in transactions:
		if transaction.amount > 0:
			total += transaction.amount

	return total


func total_spending() -> int:
	var total: int = 0

	for transaction: S6MoneyTransaction in transactions:
		if transaction.amount < 0:
			total += abs(transaction.amount)

	return total


func validate() -> Array[String]:
	var errors: Array[String] = []

	var calculated_balance: int = opening_balance

	for index: int in transactions.size():
		var transaction: S6MoneyTransaction = transactions[index]

		if transaction == null:
			errors.append(
				"transaction %d is null"
				% index
			)
			continue

		errors.append_array(
			transaction.validate()
		)

		calculated_balance += transaction.amount

	if calculated_balance != balance:
		errors.append(
			"ledger conservation failed: calculated=%d balance=%d"
			% [
				calculated_balance,
				balance
			]
		)

	if opening_balance < 0:
		errors.append(
			"opening balance cannot be negative"
		)

	if balance < 0:
		errors.append(
			"ledger balance cannot be negative"
		)

	return errors


func is_valid() -> bool:
	return validate().is_empty()


func to_dictionary() -> Dictionary:
	var serialized: Array = []

	for transaction: S6MoneyTransaction in transactions:
		serialized.append(
			transaction.to_dictionary()
		)

	return {
		"opening_balance": opening_balance,
		"balance": balance,
		"transactions": serialized
	}


static func from_dictionary(
	data: Dictionary
) -> S6MoneyLedger:
	var opening_balance: int = int(
		data.get("opening_balance", 0)
	)

	var result: S6MoneyLedger = (
		S6MoneyLedger.new(opening_balance)
	)

	var transaction_data: Array = data.get(
		"transactions",
		[]
	)

	for item: Variant in transaction_data:
		if item is Dictionary:
			result.transactions.append(
				S6MoneyTransaction.from_dictionary(
					item as Dictionary
				)
			)

	result.balance = int(
		data.get(
			"balance",
			opening_balance
		)
	)

	return result
