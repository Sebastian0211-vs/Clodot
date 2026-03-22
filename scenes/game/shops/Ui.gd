extends CanvasLayer

enum MODE {
	INVENTORY,
	SHOP
}

func open_mode(mode,items):
	%Shop.load_items(items)
	%Manager.open_mode(mode)
