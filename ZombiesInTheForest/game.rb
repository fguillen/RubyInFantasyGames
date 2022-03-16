require "fantasy"

SCREEN_WIDTH = 768
SCREEN_HEIGHT = 768

# Game presentation scene
on_presentation do
  Global.background = Color.new(r: 34, g: 35, b: 35)

  hud_text =
    HudText.new(
      position: Coordinates.new(10, 100),
      text: "This is a game\nabout <c=3ca370>zombies</c>\n\nTry to survive until\nyou find home\n\nIf you find the ring\nyou will shoot fire ;)"
    );
  hud_text.size = "big"

  hud_start = HudText.new(position: Coordinates.new(10, 700), text: "<Click Space to Start>");
  hud_start.size = "medium"

  clock =
    Clock.new do
      hud_start.visible = !hud_start.visible
    end
  clock.repeat(seconds: 1)

  on_space_bar do
    Global.go_to_game
  end
end

# Game game scene
on_game do
  Global.background = Color.new(r: 34, g: 35, b: 35)

  # HUD elements
  hud_points = HudText.new(position: Coordinates.new(0, 10), text: "0")
  hud_points.size = "big"

  hud_time = HudText.new(position: Coordinates.new(SCREEN_WIDTH - 120, 10))
  hud_time.size = "big"

  hud_key = HudImage.new(position: Coordinates.new(SCREEN_WIDTH - 220, 8), image_name: "key")
  hud_key.scale = 4
  hud_key.visible = false

  hud_ring = HudImage.new(position: Coordinates.new(SCREEN_WIDTH - 180, 10), image_name: "ring")
  hud_ring.scale = 4
  hud_ring.visible = false

  # Singleton references
  Global.references.points = 0
  Global.references.game_started_at = Time.now
  Global.references.hud_time = hud_time
  Global.references.hud_points = hud_points
  Global.references.hud_key = hud_key
  Global.references.hud_ring = hud_ring

  # House spawn
  house = House.new

  # Player spawn
  player = Player.new

  # Grass spawn
  20.times do
    tree = Actor.new("grass")
    tree.solid = false
    tree.scale = 6
    tree.position = Coordinates.new(rand(0..SCREEN_WIDTH - 48), rand(house.position.y + 60..player.position.y - 60))
  end

  # Trees spawn
  40.times do
    Tree.new
  end

  # Ring spawn
  ring = Ring.new

  # Key spawn
  key = Key.new

  # Zombies spawn
  clock =
    Clock.new do
      zombie = Zombie.new
    end
  clock.repeat(seconds: 2)

  on_space_bar do
    Bullet.new if player.have_the_ring
  end

  on_loop do
    Global.references.hud_time.text = Time.at(Global.seconds_in_scene).utc.strftime("%M:%S")
    Global.camera.position.y = Global.references.player.position.y - (SCREEN_HEIGHT / 2)
  end
end

# Game end scene
on_end do
  Global.background = Color.new(r: 34, g: 35, b: 35)

  if(Global.references.player.alive)
    hud_text_1 = HudText.new(position: Coordinates.new(10, 100), text: "You are safe!... <c=3ca370>for now</c>.");
    hud_text_1.size = "big"
    Sound.play("win")
  else
    hud_text_2 = HudText.new(position: Coordinates.new(10, 100), text: "You died!. <c=3ca370>Bad luck</c>.");
    hud_text_2.size = "big"
    Sound.play("lose")
  end

  hud_start = HudText.new(position: Coordinates.new(10, 500), text: "<Click Space to Restart>");
  hud_start.size = "medium"

  clock =
    Clock.new do
      hud_start.visible = !hud_start.visible
    end
  clock.repeat(seconds: 1)

  on_space_bar do
    Global.go_to_presentation
  end
end


# Classes
class Player < Actor
  attr_accessor :alive
  attr_reader :have_the_ring, :have_the_key

  def initialize
    super("player")

    @name = "player"
    @position = Coordinates.new(SCREEN_WIDTH / 2, SCREEN_HEIGHT - 30)
    @direction = Coordinates.zero
    @scale = 6
    @speed = 200
    @solid = true
    @alive = true
    @have_the_ring = false
    @have_the_key = false
    @layer = 1

    move_with_cursors()

    on_after_move do
      if(position.x + width > SCREEN_WIDTH)
        position.x = SCREEN_WIDTH - width
      end

      if(position.x < 0)
        position.x = 0
      end

      if(position.y > SCREEN_HEIGHT + 100)
        position.y = SCREEN_HEIGHT + 100
      end

      if(position.y < -2300)
        position.y = -2300
      end
    end

    on_collision do |other|
      if(other.name == "zombie")
        @alive = false
        Global.go_to_end
      end
    end

    Global.references.player = self
  end

  def get_the_ring
    @have_the_ring = true
    Global.references.hud_ring.visible = true
    Sound.play("collectable")
  end

  def get_the_key
    @have_the_key = true
    Global.references.hud_key.visible = true
    Sound.play("collectable")
  end
end

class Bullet < Actor
  def initialize
    super("fire_ball")

    @scale = 4
    @position = Coordinates.new(Global.references.player.position.x + (Global.references.player.width / 2) - (width / 2), Global.references.player.position.y - height)
    @direction = Coordinates.up
    @speed = 400
    @solid = true
    @layer = 1

    Sound.play("shoot")

    on_collision do |other|
      if(other.name == "zombie")
        other.killed
      end

      if(other.name == "tree")
        other.burned
      end

      if(other.name != "player" and other.name != "key" && other.name != "ring")
        destroy
      end
    end

    on_after_move do
      if(position.y < Global.references.player.position.y - SCREEN_HEIGHT)
        destroy
      end
    end

    set_dead
  end

  def set_dead
    Clock.new do
      @position += Coordinates.new((8 * @scale) / 4, (8 * @scale) / 4)
      @scale = @scale / 2;
      @speed = 0
      sleep(0.1)
      destroy
    end.run_on(seconds: 0.3)
  end
end

class Zombie < Actor
  def initialize
    super("enemy")

    @name = "zombie"
    @scale = 6
    @speed = 100
    @solid = true
    @layer = 1

    # Re position until no collisions
    begin
      set_position
    end until collisions.empty?

    on_after_move do
      chase_player
    end
  end

  def set_position
    @position = Coordinates.new(rand(0..SCREEN_WIDTH - 48), Global.references.player.position.y - (SCREEN_HEIGHT / 2))
  end

  def chase_player
    self.direction = Global.references.player.position - position
    self.direction = direction.normalize
  end

  def killed
    Global.references.points += 1
    Global.references.hud_points.text = Global.references.points

    clock =
      Clock.new do
        Global.references.hud_points.size = "huge"
        sleep(0.2)
        Global.references.hud_points.size = "big"
      end
    clock.run_now

    Sound.play("zombie_dead")

    destroy
  end
end

class House < Actor
  def initialize
    super("house")
    @position = Coordinates.new(SCREEN_WIDTH / 2, -2000)
    @solid = true
    @scale = 6

    on_collision do |other|
      if(other.name == "player")
        if(Global.references.player.have_the_key)
          Global.go_to_end
        else
          show_is_closed_message
        end
      end
    end

    Global.references.house = self
  end

  def show_is_closed_message
    hud_text = HudText.new(position: position + Coordinates.new(-40, -40), text: "It is closed")
    hud_text.in_world = true
    Clock.new { hud_text.destroy }.run_on(seconds: 2)
    Sound.play("house_closed")
  end
end

class Ring < Actor
  def initialize
    super("ring")
    @solid = true
    @scale = 6

    # Re position until no collisions
    begin
      set_position
    end until collisions.empty?

    on_collision do |other|
      puts "Ring on_collision #{other.name}"
      if(other.name == "player")
        other.get_the_ring
        destroy
      end
    end
  end

  def set_position
    position_x = rand(0..SCREEN_WIDTH - 48)
    position_y = ((Global.references.house.position.y - Global.references.player.position.y) / 2) + Global.references.player.position.y + rand(-100..100)
    @position = Coordinates.new(position_x, position_y)
  end
end

class Key < Actor
  def initialize
    super("key")
    @solid = true
    @scale = 6

    # Re position until no collisions
    begin
      set_position
    end until collisions.empty?

    on_collision do |other|
      if(other.name == "player")
        other.get_the_key
        destroy
      end
    end
  end

  def set_position
    position_x = rand(0..SCREEN_WIDTH - 48)
    position_y = rand(Global.references.house.position.y..Global.references.player.position.y - 100)
    @position = Coordinates.new(position_x, position_y)
  end
end

class Tree < Actor
  def initialize
    super("tree")
    @solid = true
    @scale = 6
    set_position
  end

  def set_position
    position_x = rand(0..SCREEN_WIDTH - 48)
    position_y = rand(Global.references.house.position.y + 60..Global.references.player.position.y - 60)
    @position = Coordinates.new(position_x, position_y)
  end

  def burned
    @solid = false
    Sound.play("tree_burned")
    self.image = "tree_burned"
  end
end

# Start the game
start!
