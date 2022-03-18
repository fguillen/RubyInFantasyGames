require "fantasy" # Yeah!

SCREEN_WIDTH = 500
SCREEN_HEIGHT = 1000

# The Presentation Scene
# on_presentation do
#   display_top_left = HudText.new(position: Coordinates.new(0, 0))
#   display_top_left.text = "Top-Left"

#   display_top_right = HudText.new(position: Coordinates.new(SCREEN_WIDTH, 100))
#   display_top_right.text = "Top-Right"
#   display_top_right.alignment = "top-right"

#   display_center = HudText.new(position: Coordinates.new(SCREEN_WIDTH / 2, 200))
#   display_center.text = "Center"
#   display_center.alignment = "center"
#   display_center.size = "big"
# end

on_game do
  background = Background.new(image_name: "sky")
  platform_map = PlatformsMap.new
  lava = Lava.new
  unicors = Unicorn.new
end

class PlatformsMap < Tilemap
  def initialize
    platform_1 = Platform.new("platform_1")
    platform_2 = Platform.new("platform_2")

    super(map_name: "platforms", tiles: [platform_1, platform_2], tile_size: 72)

    platform_1.destroy
    platform_2.destroy

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
    @direction = Coordinates.zero
    @scale = 6
    @solid = true
    @layer = 1
  end
end

class Lava < Actor
  def initialize
    super("lava")

    @direction = Coordinates.up
    @position = Coordinates.new(-10, SCREEN_HEIGHT - 100)
    @solid = true
    @layer = 3
    @speed = 10

    on_collision do |other|
      if other.name == "platform"
        other.solid = false
      end
    end
  end
end

class Unicorn < Actor
  def initialize
    super("unicorn")
    @position = Coordinates.new(SCREEN_WIDTH/2, SCREEN_HEIGHT - 250)
    @scale = 6
    @layer = 2
  end
end


start!
