extends Resource

class_name BirdSpecies

@export_group("GeneralBirdInfo")
@export
var name: String
@export_range(0.1, 11.0)
var size: float
@export
var diet: String
@export
var sound: String
@export
var nest_type: String
@export_range(20, 30)
var max_age: int
@export
var is_predator: bool

@export 
var animations: SpriteFrames

@export_group("Navigation")
@export_range(100, 10000) 
var max_stamina: float 
@export_range(100, 10000) 
var stamina: float
@export_range(0.2, 0.9)
var threshold: float

@export_group("Ground")
@export_range(5.0, 300.0)
var ground_cost: float
@export
var can_swim: bool = false
@export
var can_fly: bool = true
@export_range(4.0, 48.0)
var ground_max_distance: float

@export_group("Flight")
@export_range(0.1, 500.0)
var take_off_cost: float
@export_range(5.0, 300.0) 
var flight_cost: float
#Anything above the maximimum will trigger the migration action
@export_range(24.0, 64.0)
var flight_max_distance: float

@export_group("Traits")
@export
var preen: bool
@export
var takes_dust_baths: bool
@export
var does_sunbathing: bool
@export
var coparent: bool
@export
var male_single_parent: bool
@export
var female_single_parent: bool
