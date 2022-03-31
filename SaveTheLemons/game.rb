require "fantasy" # Yeah!

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

# Game Scene
on_game do
  background = Background.new(image_name: "background")
  background.position = Coordinates.new(-110, -30)
  background.replicable = false
  background.scale = 3.4

  lifeboat = Actor.new("lifeboat")
  lifeboat.scale = 2
  lifeboat.position = Coordinates.new(180, 525)
  lifeboat.solid = true
  lifeboat.speed = 200
  lifeboat.move_with_cursors(left: true, right: true)

  lemon_spawner = LemonSpawner.new

  on_loop do
    if Cursor.space_bar?
      lifeboat.speed = 400
    else
      lifeboat.speed = 200
    end
  end

  Clock.new do
    loop do
      lemon_spawner.spawn
      sleep(rand(1..3))
    end
  end.run_now
end

class LemonSpawner
  def spawn
    Lemon.new
  end
end

class Lemon < Actor
  def initialize
    puts "XXX: new lemon"
    super("lemon")
    @scale = 2
    @position = Coordinates.new(0, 50)

    @solid = true
    @jump_force = 500
    @gravity = 10

    @collision_with = ["lifeboat"]

    # @speed = 120
    # @direction = Coordinates.right

    impulse(direction: Coordinates.new(1, -1), force: 190)
  end

  def on_collision_do(other)
    if other.name == "lifeboat" && !@jumping
      jump
    end
  end
end

start!
