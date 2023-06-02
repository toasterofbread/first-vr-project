extends Node

enum FINGER {THUMB, INDEX, MIDDLE, RING, PINK}
enum CONTROLLER_AXIS {
	None = -1,
	
	JOYSTICK_X = 0,
	JOYSTICK_Y = 1,
	INDEX_TRIGGER = 2,
	GRIP_TRIGGER = 3,
}
enum CONTROLLER_BUTTON {
	None = -1,

	AX = 7,
	BY = 1,
	TOUCH_AX = 5,
	TOUCH_BY = 6,
	
	GRIP_TRIGGER = 2, # grip trigger pressed over threshold
	MENU = 3, # Menu Button on left controller

	STICK = 14, # left/right thumb stick pressed
	TOUCH_THUMB_UP = 10,
	
	TOUCH_INDEX_TRIGGER = 11,
	TOUCH_INDEX_POINTING = 12,
	
	INDEX_TRIGGER = 15, # index trigger pressed over threshold
}
enum SIDE {LEFT, RIGHT}
enum DAMAGE_TYPE {BULLET, HIT, CUT}
