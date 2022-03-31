extends Node

####THIS SCRIPT WILL HOLD ALL OF YOUR BLOCKS DATA
#### EVERY BLOCK / OBJECT ADDED/DELETED HERE WILL HAVE TO BE PUT IN THSI SCRIPT

####### HOW TO USE IT #####
#to add a block, put a new constant into the block enum
#this will create a new block index

#then, add it to the blocks dictionary, with it's info
#the blocks dictionary will also be used to create the buttons of the plugin
#they will be added to the dock to the left
#here, you assign an index, also the block name (that will be the button name)
#and also the group it belongs. the group is useful in case you want to 
#randomize the blocks you are placing. it will randomize between the blocks
#of the same group

#lastly, you modify the block types array. It will determine the textures of
#each face, if it is solid or now or even if should generate the faces

#then simply reload your project, and you should be able to see a new block
#into the plugin

#the same process is made with the objects, but here you also add the
#scene path of the object.

#block ENUM. It will hold the block indexes
enum {
AIR, 
DIRT, 
GRASS_HALF, 
GRASS_FULL,
GLASS,
COBBLESTONE,
ANDESITE,
DIORITE,
STONE,
LOG_MOSSY,
LOG,
WOODEN_PLANK,
SAND,
SANDSTONE,
RED_SAND,
RED_SAND_CRACKED,
GOLD_ORE,
COAL_ORE,
COPPER_ORE,
VINE_STONE,
OAK_LEAF
}

#object ENUM. It will hold the objects indexes
enum{
CHEST,
FURNACE,
CACTUS
}

#group list, They will be used for randomizing.
#if the randomized blocks button is pressed, 
#it randomizes between blocks of the same group
enum {NONE,
DIRT_GROUP, 
GRASS_GROUP, 
STONE_GROUP,
LOG_GROUP,
SAND_GROUP, 
RED_SAND_GROUP, 
ORE_GROUP}

#BUTTONS definition. It will hold the blocks information
#this dictionary will generate the buttons of the plugin.
#changing this add/remove buttons, so you can custom the plugin itself
var blocks = {"DIRT" : {index = DIRT, block_name = "Dirt", group = DIRT_GROUP}, 
"GRASS_HALF" : {index = GRASS_HALF, block_name = "Grass_half", group = GRASS_GROUP}, 
"GRASS_FULL" : {index = GRASS_FULL, block_name = "Grass_full", group = GRASS_GROUP},
"GLASS" : {index = GLASS, block_name = "Glass", group = NONE},
"COBBLESTONE" : {index = COBBLESTONE, block_name = "Cobble_Stone", group = STONE_GROUP}, 
"ANDESITE" : {index = ANDESITE, block_name = "Andesite", group = STONE_GROUP},
"DIORITE" : {index = DIORITE, block_name = "Diorite", group = STONE_GROUP},
"STONE" : {index = STONE, block_name = "Stone", group = STONE_GROUP},
"LOG_MOSSY" : {index = LOG_MOSSY, block_name = "Log_Mossy", group = LOG_GROUP},
"LOG" : {index = LOG, block_name = "Log", group = LOG_GROUP},
"WOODEN_PLANK" : {index = WOODEN_PLANK, block_name = "Wooden_plank", group = NONE},
"SAND" : {index = SAND, block_name = "Sand", group = SAND_GROUP},
"SANDSTONE" : {index = SANDSTONE, block_name = "Sandtone", group = SAND_GROUP},
"RED_SAND" : {index = RED_SAND, block_name = "Red_Sand", group = RED_SAND_GROUP},
"RED_SAND_CRACKED" : {index = RED_SAND_CRACKED, block_name = "Red_Sand_cracked", group = RED_SAND_GROUP},
"GOLD_ORE" : {index = GOLD_ORE, block_name = "Gold Ore", group = ORE_GROUP},
"COAL_ORE" : {index = COAL_ORE, block_name = "Coal Ore", group = ORE_GROUP},
"COPPER_ORE" : {index = COPPER_ORE, block_name = "Copper Ore", group = ORE_GROUP},
"VINE_STONE" : {index = VINE_STONE, block_name = "Vine Stone", group = STONE_GROUP},
"OAK_LEAF" : {index = OAK_LEAF, block_name = "Oak Leaf", group = NONE},
}

#group definition. Defines the blocks that belong to a group
var groups = {DIRT_GROUP : [DIRT],
GRASS_GROUP : [GRASS_HALF,GRASS_FULL],
STONE_GROUP : [COBBLESTONE,ANDESITE,DIORITE,STONE,VINE_STONE],
LOG_GROUP : [LOG_MOSSY,LOG],
SAND_GROUP : [SAND,SANDSTONE], 
RED_SAND_GROUP : [RED_SAND,RED_SAND_CRACKED], 
ORE_GROUP: [GOLD_ORE,COAL_ORE,COPPER_ORE]
}

#object BUTTONS definition.
#they will be added independently of blocks. May have half-tile sizes,
#can be rotated, and so on.
var objects = {"CHEST" : {index = CHEST, block_name = "Chest", rotateable = true},
"FURNACE" : {index = FURNACE, block_name = "FURNACE",rotateable = true},
"CACTUS" : {index = CACTUS, block_name = "Cactus",rotateable = false}
}

#helper enum to generate the faces of a block
enum {TOP,BOTTOM,LEFT,RIGHT,FRONT,BACK,SOLID,GENERATE_FACES, SCENE, OFFSET}

#---------------------------------------------------------------------------
#block face definitions.
#defines the faces that make a block
#the faces are defined by a vector2, that maps the texture in the atlas texture
#for example, the dirt object (the second one):
#the top face is defined by Vector(0,3), which means
#it will get the texture in the first column, fourth row
#ir maps where the faces are in the atlas texture. 
#it also defines if the block is solid, and if any faces will be generated.
#solid defines if a block is solid or not, so we can see through it 
#glass and leaves for example are not solid, but transparent. 

const block_types = {
	AIR:{
		SOLID : false, GENERATE_FACES: false
		},
	DIRT:{
		TOP : Vector2(0,3), BOTTOM: Vector2(0,3), LEFT : Vector2(0,3),
		RIGHT : Vector2(0,3), FRONT: Vector2(0,3), BACK : Vector2(0,3),
		SOLID : true, GENERATE_FACES: true
	},
	GRASS_HALF:{
		TOP : Vector2(2,3), BOTTOM: Vector2(0,3), LEFT : Vector2(1,3),
		RIGHT : Vector2(1,3), FRONT: Vector2(1,3), BACK : Vector2(1,3),
		SOLID : true, GENERATE_FACES: true
	},
		GRASS_FULL:{
		TOP : Vector2(2,3), BOTTOM: Vector2(2,3), LEFT : Vector2(2,3),
		RIGHT : Vector2(2,3), FRONT: Vector2(2,3), BACK : Vector2(2,3),
		SOLID : true, GENERATE_FACES: true
	},
		GLASS:{
		TOP : Vector2(3,3), BOTTOM: Vector2(3,3), LEFT : Vector2(3,3),
		RIGHT : Vector2(3,3), FRONT: Vector2(3,3), BACK : Vector2(3,3),
		SOLID : false, GENERATE_FACES: true
	},
		COBBLESTONE:{
		TOP : Vector2(0,2), BOTTOM: Vector2(0,2), LEFT : Vector2(0,2),
		RIGHT : Vector2(0,2), FRONT: Vector2(0,2), BACK : Vector2(0,2),
		SOLID : true, GENERATE_FACES: true
	},
		ANDESITE:{
		TOP : Vector2(1,2), BOTTOM: Vector2(1,2), LEFT : Vector2(1,2),
		RIGHT : Vector2(1,2), FRONT: Vector2(1,2), BACK : Vector2(1,2),
		SOLID : true, GENERATE_FACES: true
	},
		DIORITE:{
		TOP : Vector2(2,2), BOTTOM: Vector2(2,2), LEFT : Vector2(2,2),
		RIGHT : Vector2(2,2), FRONT: Vector2(2,2), BACK : Vector2(2,2),
		SOLID : true, GENERATE_FACES: true
	},
		STONE:{
		TOP : Vector2(3,2), BOTTOM: Vector2(3,2), LEFT : Vector2(3,2),
		RIGHT : Vector2(3,2), FRONT: Vector2(3,2), BACK : Vector2(3,2),
		SOLID : true, GENERATE_FACES: true
	},
		LOG_MOSSY:{
		TOP : Vector2(1,4), BOTTOM: Vector2(1,4), LEFT : Vector2(0,4),
		RIGHT : Vector2(0,4), FRONT: Vector2(0,4), BACK : Vector2(0,4),
		SOLID : true, GENERATE_FACES: true
	},
		LOG:{
		TOP : Vector2(3,4), BOTTOM: Vector2(3,4), LEFT : Vector2(2,4),
		RIGHT : Vector2(2,4), FRONT: Vector2(2,4), BACK : Vector2(2,4),
		SOLID : true, GENERATE_FACES: true
	},
		WOODEN_PLANK:{
		TOP : Vector2(4,4), BOTTOM: Vector2(4,4), LEFT : Vector2(4,4),
		RIGHT : Vector2(4,4), FRONT: Vector2(4,4), BACK : Vector2(4,4),
		SOLID : true, GENERATE_FACES: true
	},
		SAND:{
		TOP : Vector2(0,5), BOTTOM: Vector2(0,5), LEFT : Vector2(0,5),
		RIGHT : Vector2(0,5), FRONT: Vector2(0,5), BACK : Vector2(0,5),
		SOLID : true, GENERATE_FACES: true
	},
		SANDSTONE:{
		TOP : Vector2(1,5), BOTTOM: Vector2(1,5), LEFT : Vector2(1,5),
		RIGHT : Vector2(1,5), FRONT: Vector2(1,5), BACK : Vector2(1,5),
		SOLID : true, GENERATE_FACES: true
	},
		RED_SAND:{
		TOP : Vector2(2,5), BOTTOM: Vector2(2,5), LEFT : Vector2(2,5),
		RIGHT : Vector2(2,5), FRONT: Vector2(2,5), BACK : Vector2(2,5),
		SOLID : true, GENERATE_FACES: true
	},
		RED_SAND_CRACKED:{
		TOP : Vector2(3,5), BOTTOM: Vector2(3,5), LEFT : Vector2(3,5),
		RIGHT : Vector2(3,5), FRONT: Vector2(3,5), BACK : Vector2(3,5),
		SOLID : true, GENERATE_FACES: true
	},
		GOLD_ORE:{
		TOP : Vector2(1,6), BOTTOM: Vector2(1,6), LEFT : Vector2(1,6),
		RIGHT : Vector2(1,6), FRONT: Vector2(1,6), BACK : Vector2(1,6),
		SOLID : true, GENERATE_FACES: true
	},
		COAL_ORE:{
		TOP : Vector2(2,6), BOTTOM: Vector2(2,6), LEFT : Vector2(2,6),
		RIGHT : Vector2(2,6), FRONT: Vector2(2,6), BACK : Vector2(2,6),
		SOLID : true, GENERATE_FACES: true
	},
		COPPER_ORE:{
		TOP : Vector2(3,6), BOTTOM: Vector2(3,6), LEFT : Vector2(3,6),
		RIGHT : Vector2(3,6), FRONT: Vector2(3,6), BACK : Vector2(3,6),
		SOLID : true, GENERATE_FACES: true
	},
		VINE_STONE:{
		TOP : Vector2(4,6), BOTTOM: Vector2(4,6), LEFT : Vector2(4,6),
		RIGHT : Vector2(4,6), FRONT: Vector2(4,6), BACK : Vector2(4,6),
		SOLID : true, GENERATE_FACES: true
	},
		OAK_LEAF:{
		TOP : Vector2(0,7), BOTTOM: Vector2(0,7), LEFT : Vector2(0,7),
		RIGHT : Vector2(0,7), FRONT: Vector2(0,7), BACK : Vector2(0,7),
		SOLID : false, GENERATE_FACES: true
	},
}

#defines the objects and how they are generated.
#the difference between objects and blocks, is that blocks are part of the surface mesh
#meanwhile, objects are individual scenes, that can have their own functionality
#of course you could also add functionality to blocks, but it's easier that way
#you could add leaves as objects for example, and make them move with the wind
#by applying a shader to it, etc;
const object_types = {
	CHEST:{
		SOLID : true, GENERATE_FACES: false, SCENE: preload("res://Scenes/Chest/chest.tscn"), OFFSET: Vector3(0.5,0,0.5)
		},
	FURNACE:{
		SOLID : true, GENERATE_FACES: false, SCENE: preload("res://Scenes/Furnace/furnace.tscn"),OFFSET: Vector3(0.5,0,0.5)
		},
	CACTUS:{
		SOLID : false, GENERATE_FACES: false, SCENE: preload("res://Scenes/Cactus/cactus.tscn"),OFFSET: Vector3(0.75,0,0.75)
		}
}
