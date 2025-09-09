# Scripts/StatResource.gd
extends Resource
class_name StatResource

## Status Inti
@export var level: int = 1
@export var current_exp: int = 0
@export var exp_to_next_level: int = 100

## Stats Dasar
@export var hp: int = 100
@export var atk: int = 10
@export var def: int = 10
@export var agi: int = 10
