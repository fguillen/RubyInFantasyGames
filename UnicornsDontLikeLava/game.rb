require "fantasy" # Yeah!

SCREEN_WIDTH = 480
SCREEN_HEIGHT = 800

# Presentation Scene
on_presentation do
  Global.background = Color.new(r: 210, g: 241, b: 244)

  unicorn = Actor.new("unicorn")
  unicorn.position = Coordinates.new(SCREEN_WIDTH/2 - 50, 100)
  unicorn.scale = 6

  text_1 = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 250))
  text_1.text = "Save Unicorn from the lava"
  text_1.alignment = "center"

  text_3 = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 500), text: "<Click Space to start>");
  text_3.alignment = "center"
  Clock.new { text_3.visible = !text_3.visible }.repeat(seconds: 1)

  on_space_bar do
    Global.go_to_game
  end
end

# Game Scene
on_game do
  Music.play("music")
  background = Background.new(image_name: "sky")
  platform_map = PlatformsMap.new
  lava = Lava.new
  unicorn = Unicorn.new
  rainbow = Rainbow.new(position: Coordinates.new(0, platform_map.position.y - 100))
  hud = Hud.new

  on_loop do
    unless Global.references.game_ended
      Global.camera.position.y = lava.position.y - SCREEN_HEIGHT + 150

      if Global.camera.position.y < rainbow.position.y
        Global.camera.position.y = rainbow.position.y
      end
    end
  end

  # Some global references
  Global.references.stars_collected = 0
  Global.references.unicorn = unicorn
  Global.references.rainbow = rainbow
  Global.references.hud = hud
  Global.references.game_ended = false
end

# End Scene
on_end do
  Global.background = End.background_color

  unicorn = Actor.new(End.unicorn_image_name)
  unicorn.position = Coordinates.new(SCREEN_WIDTH/2 - 50, 100)
  unicorn.scale = 6

  text_1 = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 220))
  text_1.text = End.text
  text_1.alignment = "center"

  if Global.references.end_version == "good"
    star = HudImage.new(image_name: "star", position: Coordinates.new(SCREEN_WIDTH/2 - 50, 280))
    star.scale = 2

    text_2 = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 380))
    text_2.text = "#{Global.references.stars_collected} stars saved"
    text_2.size = "big"
    text_2.alignment = "center"
  end

  if Global.references.end_version == "bad"
    text_2 = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 350))
    text_2.text = "GAME OVER"
    text_2.size = "huge"
    text_2.alignment = "center"
  end

  text_3 = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 500), text: "<Click Space to try again>");
  text_3.alignment = "center"
  Clock.new { text_3.visible = !text_3.visible }.repeat(seconds: 1)

  on_space_bar do
    Global.go_to_game
  end
end

# The Tilemap
class PlatformsMap < Tilemap
  def initialize
    platform_1 = Platform.new("platform_1")
    platform_2 = Platform.new("platform_2")
    platform_moving = PlatformMoving.new("platform_moving")
    star = Star.new("star")

    super(map_name: "platforms", tiles: [platform_1, platform_2, platform_moving, star], tile_width: 96, tile_height: 72)

    # Destroy the templates, we don't need them any more
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

# The static platform
class Platform < Actor
  def initialize(image_name)
    super(image_name)

    @name = "platform"
    @scale = 6
    @solid = true
    @layer = 2
  end
end

# The moving platform
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

# The growing lava
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
    # when lava collides with unicorn we go to the bad_end
    if other.name == "unicorn"
      End.bad_end
    end
  end
end

# The player
class Unicorn < Actor
  def initialize
    super("unicorn")
    @position = Coordinates.new(SCREEN_WIDTH/2 - 40, SCREEN_HEIGHT - 550)
    @scale = 6
    @layer = 3
    @solid = true
    @speed = 200
    @jump = 150
    @gravity = 200
    @collision_during_jumping = true

    # Cursors controls settings
    move_with_cursors(left: true, right: true, up: false, down: false, jump: true)
  end

  # Triggered when jump starts
  def on_start_jumping_do
    Sound.play("jump")
    @image = Image.new("unicorn_jump")
  end

  # Triggered when jump is in top hight
  def on_start_falling_do
    @image = Image.new("unicorn")
  end

  def on_after_move_do
    unless Global.references.game_ended
      if @position.y < Global.references.rainbow.position.y + 100
        End.good_end
      end

      if @position.x < 0
        @position.x = 0
      end

      if @position.x > SCREEN_WIDTH - width
        @position.x = SCREEN_WIDTH - width
      end
    end
  end
end

# The rainbow at the top
class Rainbow < Actor
  def initialize(position: )
    super("rainbow")
    @position = position
    @layer = 1
  end
end

# The shinny star
class Star < Actor
  def initialize(image_name)
    super(image_name)
    @solid = true
    @scale = 2
    @layer = 2
  end

  def on_collision_do(other)
    if other.name == "unicorn"
      Sound.play("collectable")
      Global.references.hud.increase_stars
      Global.references.stars_collected += 1
      destroy
    end
  end
end

# The simple HUD with the num of collected stars
class Hud
  def initialize
    @star_display = HudImage.new(position: Coordinates.new(0, 5), image_name: "star")
    @star_display.scale = 1

    @text_display = HudText.new(position: Coordinates.new(50, 0), text: 0)
  end

  def increase_stars
    @text_display.text += 1
  end
end

# To control the different endings
class End
  def self.bad_end
    Global.references.end_version = "bad"
    Global.references.game_ended = true
    Music.stop
    Sound.play("lose")
    unicorn = Global.references.unicorn
    unicorn.image = "unicorn_burnt"
    unicorn.solid = false

    Clock.new do
      sleep(1)
      Global.go_to_end
    end.run_now
  end

  def self.good_end
    Global.references.end_version = "good"
    Global.references.game_ended = true
    Music.stop
    Sound.play("win")
    unicorn = Global.references.unicorn
    unicorn.solid = false
    unicorn.gravity = 0

    Clock.new do
      final_position = unicorn.position - Coordinates.new(0, 300)
      while(unicorn.position.y > final_position.y)
        sleep(0.01)
        unicorn.position = Tween.move_towards(from: unicorn.position, to: final_position, speed: 100)
      end

      sleep(1)
      Global.go_to_end
    end.run_now
  end

  def self.background_color
    if Global.references.end_version == "good"
      Color.new(r: 210, g: 241, b: 244)
    else
      Color.new(r: 180, g: 129, b: 99)
    end
  end

  def self.unicorn_image_name
    if Global.references.end_version == "good"
      "unicorn"
    else
      "unicorn_burnt"
    end
  end

  def self.text
    if Global.references.end_version == "good"
      "Unicorn is safe"
    else
      "Unicorn is burnt"
    end
  end
end

# Start the game
start!
