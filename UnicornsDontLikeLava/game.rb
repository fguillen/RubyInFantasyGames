require "fantasy" # Yeah!

SCREEN_WIDTH = 480
SCREEN_HEIGHT = 1000

on_game do
  background = Background.new(image_name: "sky")
  platform_map = PlatformsMap.new
  lava = Lava.new
  unicorn = Unicorn.new
  rainbow = Rainbow.new(position: Coordinates.new(0, platform_map.position.y - 100))

  on_loop do
    Global.camera.position.y = lava.position.y - SCREEN_HEIGHT + 150

    if Global.camera.position.y < rainbow.position.y
      Global.camera.position.y = rainbow.position.y
    end
  end

  Global.references.rainbow = rainbow
end

class PlatformsMap < Tilemap
  def initialize
    platform_1 = Platform.new("platform_1")
    platform_2 = Platform.new("platform_2")
    platform_moving = PlatformMoving.new("platform_moving")

    super(map_name: "platforms", tiles: [platform_1, platform_2, platform_moving], tile_width: 96, tile_height: 72)

    platform_1.destroy
    platform_2.destroy
    platform_moving.destroy

    set_right_position
    spawn
  end

  def set_right_position
    @position = Coordinates.new(0, SCREEN_HEIGHT - height - 100)
  end
end

class Platform < Actor
  def initialize(image_name)
    super(image_name)

    @name = "platform"
    @scale = 6
    @solid = true
    @layer = 1
  end
end

class PlatformMoving < Platform
  def initialize(image_name)
    super(image_name)

    @speed = 100
    @direction = Coordinates.left
    @name = "platform"
  end

  def on_collision_do(other)
    if other.name == "platform"
      @direction.x = -@direction.x
    end
  end

  def on_after_move_do
    if @position.x < 0
      @position.x = 0
      @direction = Coordinates.right
    end

    if @position.x > SCREEN_WIDTH - width
      @position.x = SCREEN_WIDTH - width
      @direction = Coordinates.left
    end
  end
end

class Lava < Actor
  def initialize
    super("lava")

    @direction = Coordinates.up
    @position = Coordinates.new(-10, SCREEN_HEIGHT - 100)
    @solid = true
    @layer = 3
    @speed = 50

    @collision_with = ["unicorn"]
  end
end

class Unicorn < Actor
  def initialize
    super("unicorn")
    @position = Coordinates.new(SCREEN_WIDTH/2, SCREEN_HEIGHT - 550)
    @scale = 6
    @layer = 2
    @solid = true
    @speed = 200
    @jump = 150
    @gravity = 200
    move_with_cursors(left: true, right: true, up: false, down: false, jump: true)
  end

  def on_start_jumping_do
    @image = Image.new("unicorn_jump")
  end

  def on_start_falling_do
    @image = Image.new("unicorn")
  end

  def on_after_move_do
    if @position.y < Global.references.rainbow.position.y + 100
      puts "Game over"
    end
  end
end

class Rainbow < Actor
  def initialize(position: )
    super("rainbow")
    @position = position
  end
end

start!
