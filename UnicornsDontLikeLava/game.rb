require "fantasy" # Yeah!

SCREEN_WIDTH = 480
SCREEN_HEIGHT = 1000

on_game do
  background = Background.new(image_name: "sky")
  platform_map = PlatformsMap.new
  lava = Lava.new
  unicorn = Unicorn.new
  rainbow = Rainbow.new(position: Coordinates.new(0, platform_map.position.y - 100))
  hud = Hud.new

  on_loop do
    unless Global.references.game_ended
      puts "loop"
      Global.camera.position.y = lava.position.y - SCREEN_HEIGHT + 150

      if Global.camera.position.y < rainbow.position.y
        Global.camera.position.y = rainbow.position.y
      end
    end
  end

  Global.references.rainbow = rainbow
  Global.references.hud = hud
  Global.references.game_ended = false
end

on_end do
  Global.background = Color.new(r: 210, g: 241, b: 244)
  puts "XXX: Global.camera.position: #{Global.camera.position}"
  unicorn = Actor.new("unicorn")
  unicorn.position = Coordinates.new(SCREEN_WIDTH/2 - 50, SCREEN_HEIGHT/2 - 90)
  unicorn.scale = 6
end

class PlatformsMap < Tilemap
  def initialize
    platform_1 = Platform.new("platform_1")
    platform_2 = Platform.new("platform_2")
    platform_moving = PlatformMoving.new("platform_moving")
    star = Star.new("star")

    super(map_name: "platforms", tiles: [platform_1, platform_2, platform_moving, star], tile_width: 96, tile_height: 72)

    platform_1.destroy
    platform_2.destroy
    platform_moving.destroy
    star.destroy

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
    @layer = 2
  end
end

class PlatformMoving < Platform
  def initialize(image_name)
    super(image_name)

    @speed = 100
    @direction = Coordinates.left
    @name = "platform"
    @layer = 2
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
    @layer = 10
    @speed = 50

    @collision_with = ["unicorn"]
  end

  def on_collision_do(other)
    if other.name == "unicorn"
      other.burnt
    end
  end
end

class Unicorn < Actor
  def initialize
    super("unicorn")
    @position = Coordinates.new(SCREEN_WIDTH/2, SCREEN_HEIGHT - 550)
    @scale = 6
    @layer = 3
    @solid = true
    @speed = 200
    @jump = 150
    @gravity = 200
    @collision_during_jumping = true
    move_with_cursors(left: true, right: true, up: false, down: false, jump: true)
  end

  def on_start_jumping_do
    Sound.play("jump")
    @image = Image.new("unicorn_jump")
  end

  def on_start_falling_do
    @image = Image.new("unicorn")
  end

  def on_after_move_do
    if @position.y < Global.references.rainbow.position.y + 100
      puts "Game over"
    end

    if @position.x < 0
      @position.x = 0
    end

    if @position.x > SCREEN_WIDTH - width
      @position.x = SCREEN_WIDTH - width
    end
  end

  def burnt
    Global.references.game_ended = true
    Sound.play("lose")
    @image = Image.new("unicorn_burnt")
    @solid = false

    Clock.new do
      final_position = @position + Coordinates.new(200, 0)

      while(@position.y < final_position.y)
        Tween.move_towards(from: @position, to: final_position, speed: 100)
      end

      sleep(1)

      Global.go_to_end
    end.run_now
  end
end

class Rainbow < Actor
  def initialize(position: )
    super("rainbow")
    @position = position
    @layer = 1
  end
end

class Star < Actor
  def initialize(image_name)
    super(image_name)
    @solid = true
    @scale = 2
    @layer = 2
  end

  def on_collision_do(other)
    if other.name == "unicorn"
      collect
    end
  end

  def collect
    puts "Coin collected"
    Sound.play("collectable")
    Global.references.hud.increase_stars
    destroy
  end
end

class Hud
  def initialize
    @star_display = HudImage.new(position: Coordinates.new(0, 5), image_name: "star")
    @star_display.scale = 1

    @text_display = HudText.new(position: Coordinates.new(50, 0), text: 0)
    @text_display.size = "medium"
  end

  def increase_stars
    @text_display.text += 1
  end
end

start!
