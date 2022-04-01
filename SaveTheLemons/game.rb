require "fantasy" # Yeah!

# Screen size
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600

# Presentation Scene
on_presentation do
  text_1 = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 80), text: "Save the Lemons")
  text_1.alignment = "center"
  text_1.size = "huge"
  text_1.color = Color.palette.lemon_chiffon

  # Big instructions text
  text_2 = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 170))
  text_2.text = <<~EOS
    The lemons are trying to cross the river. Help them to not fall into the cold water.

    You manage the little lifeboat, be sure that as many as possible lemons finish the journey.

    Use <c=#{Color.palette.lemon_chiffon.hex}>cursor keys</c> left and right to manage the lifeboat. You get points when a lemon bounce
    on your lifeboat. And extra points if the lemon riches the other side safely.

    If 20 lemons sink into the cold water <c=#{Color.palette.lemon_chiffon.hex}>you lose the game</c>.

    Have special attention to the fairy lemons. If they reach the other side, they will reward you.

    But watch out!. Some lemons are very angry; if they touch the lifeboat they will bite it!.

    <c=#{Color.palette.lemon_chiffon.hex}>Press space bar</c> to move the lifeboat faster.
  EOS
  text_2.size = "small"
  text_2.alignment = "center"

  lifeboat = Actor.new("lifeboat")
  lifeboat.scale = 2
  lifeboat.position = Coordinates.new(SCREEN_WIDTH/2 - (lifeboat.width/2), 480)

  text_4 = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 560), text: "<Press Space to start>");
  text_4.alignment = "center"
  Clock.new { text_4.visible = !text_4.visible }.repeat(seconds: 1)

  # Start game when space bar pressed
  on_space_bar do
    Global.go_to_game
  end
end


# Game Scene
on_game do
  Music.play("music", volume: 0.05) # Start music very low

  # Set the background image
  background = Background.new(image_name: "background")
  background.position = Coordinates.new(-110, -30)
  background.replicable = false
  background.scale = 3.4

  # Starting the active entities
  lifeboat = Lifeboat.new
  lemon_spawner = LemonSpawner.new
  hud = HUD.new

  # A bunch of global references
  Global.references.hud = hud
  Global.references.lifeboat = lifeboat
  Global.references.level = 1
  Global.references.points = 0
  Global.references.sinks = 0
  Global.references.ended = false
  Global.references.max_sinks = 20

  # Start spawning lemons
  lemon_spawner.start_level(Global.references.level)
end

on_end do
  text_1 = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 80), text: "Game Over")
  text_1.alignment = "center"
  text_1.size = "huge"

  text_2 = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 170))
  text_2.text = "You made\n<c=#{Color.palette.lemon_chiffon.hex}>#{Global.references.points} points</c>"
  text_2.alignment = "center"

  lifeboat = Actor.new("lifeboat")
  lifeboat.scale = 2
  lifeboat.position = Coordinates.new(SCREEN_WIDTH/2 - (lifeboat.width/2), 250)

  text_3 = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 350));
  text_3.text = "Records:\n#{Disk.data.records.join("\n")}"
  text_3.alignment = "center"

  text_4 = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 550), text: "<Press Space to play again>");
  text_4.alignment = "center"
  text_4.size = "small"
  Clock.new { text_4.visible = !text_4.visible }.repeat(seconds: 1)

  on_space_bar do
    Global.go_to_game
  end
end

class Lifeboat < Actor
  def initialize
    super("lifeboat")
    @scale = 2
    @position = Coordinates.new(180, 500)
    @solid = true
    @speed = 200
    @poked = false
    move_with_cursors(left: true, right: true)
  end

  def on_after_move_do
    if(!Global.references.ended)
      @poked ? move_poked : move_normal
    end
  end

  def move_normal
    if(@position.x > 564)
      @position.x = 564
    end

    if(@position.x < 143)
      @position.x = 143
    end

    if Cursor.space_bar?
      @speed = 500
    else
      @speed = 200
    end
  end

  def move_poked
    @speed = 600

    if(@position.x > 564)
      @position.x = 564
      @direction = @direction * -1
    end

    if(@position.x < 143)
      @position.x = 143
      @direction = @direction * -1
    end
  end

  def poke
    @poked = true
    @image = Image.new("lifeboat_poked")
    @direction = Coordinates.right
    Clock.new { fix_poke }.run_on(seconds: 4)
    Clock.new { Sound.play("poke") }.repeat(seconds: 1, times: 4)
    move_with_cursors(left: false, right: false)
  end

  def fix_poke
    @poked = false
    @image = Image.new("lifeboat")
    @direction = Coordinates.zero
    @speed = 200
    move_with_cursors(left: true, right: true)
  end
end

class LemonSpawner
  def initialize
    @data = File.read("#{__dir__}/maps/lemons.txt").reverse
  end

  def start_level(level = 1)
    puts "Start level: #{level}"
    Global.references.hud.level_update(value: level)

    Clock.new do
      @data.each_char do |char|
        if(char == "L")
          spawn(kind: "normal")
        elsif(char == "F")
          spawn(kind: "fairy")
        elsif(char == "A")
          spawn(kind: "angry")
        end

        sleep(1 / level.to_f)
      end

      Global.references.level += 1
      Sound.play("level_up", volume: 2)
      start_level(Global.references.level)
    end.run_now
  end

  def spawn(kind:)
    unless Global.references.ended
      Lemon.new(kind: kind)
    end
  end
end

class Lemon < Actor
  def initialize(kind: "normal")
    super("lemon_#{kind}")
    @kind = kind
    @scale = 2
    @position = Coordinates.new(0, 50)
    @solid = true
    @jump_force = 500
    @gravity = 10

    @collision_with = ["lifeboat"]
    @sunk = false

    # Initial impulse
    impulse(direction: Coordinates.new(1, -1), force: 190)
  end

  def on_after_move_do
    if(!@sunk && !Global.references.ended && @position.y > 540)
      Sound.play("sunk", volume: 0.8)
      @sunk = true

      if(@kind != "angry")
        Global.references.hud.sunk_update
      end
    end

    if(@position.y > 455) # below the lifeboat
      @solid = false
    end

    if(@position.y > 600)
      destroy
    end

    if(@position.x > SCREEN_WIDTH)
      unless Global.references.ended
        saved
      end
    end
  end

  def on_collision_do(other)
    return if Global.references.ended

    if other.name == "lifeboat" && !@jumping
      if(@kind == "normal" || @kind == "fairy")
        jump
        Global.references.hud.points_update(value: 1)
        Sound.play("jump", volume: 0.5)
      elsif(@kind == "angry")
        Sound.play("angry")
        Global.references.lifeboat.poke
        @solid = false
      else
        raise "Lemon kind not supported: '#{@kind}'"
      end
    end
  end

  def saved
    if(@kind == "fairy")
      Sound.play("bonus")
      Global.references.hud.points_update(value: 10)
      Global.references.hud.sunk_update(value: -5)
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

    @level_title = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 5), text: "Level")
    @level_title.alignment = "top-center"
    @level_counter = HudText.new(position: Coordinates.new(SCREEN_WIDTH/2, 35), text: 0)
    @level_counter.color = Color.palette.medium_sea_green
    @level_counter.alignment = "top-center"

    @points_title = HudText.new(position: Coordinates.new(SCREEN_WIDTH - 10, 5), text: "Points")
    @points_title.alignment = "top-right"
    @points_counter = HudText.new(position: Coordinates.new(SCREEN_WIDTH - 10, 35), text: 0)
    @points_counter.alignment = "top-right"
    @points_counter.color = Color.palette.gold
  end

  def sunk_update(value: 1)
    Global.references.sinks += value
    Global.references.sinks = 0 if Global.references.sinks < 0

    @sunk_counter.text = Global.references.sinks

    if Global.references.sinks >= Global.references.max_sinks
      Music.stop
      Global.references.ended = true
      set_records

      Clock.new { Sound.play("lose") }.run_on(seconds: 1)
      Clock.new { Global.go_to_end }.run_on(seconds: 2)
    end
  end

  def points_update(value:)
    Global.references.points += value
    @points_counter.text = Global.references.points
  end

  def level_update(value:)
    @level_counter.text = value
  end

  def set_records
    records = Disk.data.records
    records ||= []
    records.push(Global.references.points)
    records = records.sort.reverse.first(3)

    Disk.data.records = records
    Disk.save
  end
end

start!
