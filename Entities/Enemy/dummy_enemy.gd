extends CharacterBody2D

var hp: int = 50

func take_damage(amount: int):
	hp -= amount
	print("Dummy menerima ", amount, " damage! Sisa HP: ", hp)

	if hp <= 0:
		print("Dummy dikalahkan!")
		queue_free() # Menghapus diri sendiri dari scene
