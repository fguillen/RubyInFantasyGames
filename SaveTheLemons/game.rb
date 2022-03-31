require "fantasy" # Yeah!

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

# Game Scene
on_game do
  background = Background.new(image_name: "background")
  background.position = Coordinates.new(-110, -30)
  background.replicable = false
  background.scale = 3.4

  lifeboat = Lifeboat.new
  lemon_spawner = LemonSpawner.new
  hud = HUD.new

  Music.play("music", volume: 0.1)

  Global.references.hud = hud
end

class Lifeboat < Actor
  def initialize
    super("lifeboat")
    @scale = 2
    @position = Coordinates.new(180, 500)
    @solid = true
    @speed = 200
    move_with_cursors(left: true, right: true)
  end

  def on_after_move_do
    if(@position.x > 564)
      @position.x = 564
    end

    if(@position.x < 143)
      @position.x = 143
    end

    if Cursor.space_bar?
      @speed = 400
    else
      @speed = 200
    end
  end
end

class LemonSpawner
  def initialize
    @data = File.read("#{__dir__}/maps/lemons.txt")
    puts "data: #{@data}"

    Clock.new do
      @data.each_char do |char|
        puts char
        if(char == "L")
          spawn(kind: "lemon")
        elsif(char == "K")
          spawn(kind: "lemon_king")
        end

        sleep(0.5)
      end
      puts "lemons finished"
    end.run_now
  end

  def spawn(kind:)
    Lemon.new(kind: kind)
  end
end

class Lemon < Actor
  def initialize(kind: "lemon")
    puts "XXX: new lemon: #{kind}"
    super(kind)
    @kind = kind
    @scale = 2
    @position = Coordinates.new(0, 50)

    @solid = true
    @jump_force = 500
    @gravity = 10

    @collision_with = ["lifeboat"]
    @sunk = false

    # @speed = 120
    # @direction = Coordinates.right

    impulse(direction: Coordinates.new(1, -1), force: 190)
  end

  def on_after_move_do
    if(!@sunk && @position.y > 540)
      puts "lemon sunk"
      Sound.play("sunk")
      @sunk = true
      Global.references.hud.sunk_update
    end

    if(@position.y > 600)
      puts "lemon destroyed"
      destroy
    end

    if(@position.x > SCREEN_WIDTH)
      saved
    end
  end

  def on_collision_do(other)
    if other.name == "lifeboat" && !@jumping
      jump
      Global.references.hud.points_update(value: 1)
      Sound.play("jump", volume: 0.5)
    end
  end

  def saved
    if(@kind == "lemon_king")
      Sound.play("bonus")
      Global.references.hud.points_update(value: 10)
      Global.references.hud.sunk_update(value: -10)
    else
      Sound.play("collectable")
      Global.references.hud.points_update(value: 5)
    end


    destroy
  end
end

class HUD
  def initialize
    @sunk_title = HudText.new(position: Coordinates.new(10, 5), text: "Sunk")
    @sunk_counter = HudText.new(position: Coordinates.new(10, 35), text: 0)
    @sunk_counter.color = Color.palette.deep_sky_blue

    @points_title = HudText.new(position: Coordinates.new(SCREEN_WIDTH - 10, 5), text: "Points")
    @points_title.alignment = "top-right"
    @points_counter = HudText.new(position: Coordinates.new(SCREEN_WIDTH - 10, 35), text: 0)
    @points_counter.alignment = "top-right"
    @points_counter.color = Color.palette.medium_sea_green
  end

  def sunk_update(value: 1)
    @sunk_counter.text += value
    @sunk_counter.text = 0 if @sunk_counter.text < 0
  end

  def points_update(value:)
    @points_counter.text += value
  end
end

start!
