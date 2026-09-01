extends Node

const CROPS := {
	"wheat": preload("res://resources/data/crops/wheat.tres"),
	"carrot": preload("res://resources/data/crops/carrot.tres"),
	"moonberry": preload("res://resources/data/crops/moonberry.tres"),
}

func get_crop(crop_id: String) -> CropData:
	return CROPS.get(crop_id)
