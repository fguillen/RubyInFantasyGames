require "fantasy"
require "debug"

ENV["debug"] = "active"

SCREEN_WIDTH = 138*3*2*2
SCREEN_HEIGHT = 90*3*2

on_game do
  Global.background = Color.from_hex("312520")
  @points = 0
  hud = Hud.new
  points_hud =
    Text.new(
      text: "Points: #{@points.to_s.rjust(3, '0')}",
      position: Coordinates.new(10, 10),
      size: "big"
    )
  hud.add_child(points_hud)

  # sprite = Sprite.new("ninja")

  background = Background.new(graphic: "background")
  background.scale = 6
  background.layer = -1

  background_rain = Background.new(graphic: "rain")
  background_rain.scale = 4
  background_rain.layer = -10
  Clock.new {
    background_rain.position.y += 100
    background_rain.position.y = 0 if background_rain.position.y > background_rain.height
  }.repeat(seconds: 0.1)

  background_floor = Background.new(graphic: "floor")
  background_floor.scale = 4
  background_floor.layer = 10
  background_floor.repeat = :horizontal
  background_floor.position = Coordinates.new(0, Global.screen_height - background_floor.height)

  floor = Actor.new(name: "floor")
  floor.layer = 20
  floor.position.y = Global.screen_height - 50
  floor_collider = Collider.new(name: "floor", width: 200, height: 10)
  floor_collider.solid = true
  floor_collider.collision_with = "none"
  floor.add_child(floor_collider)

  animation_walk = Animation.new(sequence: "ninja", columns: 4, rows: 7, speed: 10, frames: [3, 7, 11, 15])
  animation_idle = Animation.new(sequence: "ninja", columns: 4, rows: 7, speed: 1, frames: [3])
  animation_punch = Animation.new(sequence: "ninja", columns: 4, rows: 7, speed: 5, frames: [19], loops: 1)
  ninja = Actor.new(graphic: animation_idle)
  ninja.position = Coordinates.zero
  ninja.scale = 6
  ninja.layer = 0
  ninja.speed = 200
  ninja.gravity = 40
  ninja.jump_force = 800
  ninja.auto_flipable = true
  ninja.move_with_cursors(jump: true, up: false, down: false)
  ninja_collider = Collider.new(name: "collider_ninja", parent: ninja, solid: true)
  punch_collider = Collider.new(name: "collider_punch", parent: ninja, solid: true)
  punch_collider.width = 5
  punch_collider.height = 5
  punch_collider.solid = false
  punch_collider.active = false
  punch_collider.position = Coordinates.new(ninja.width, 10)

  punch_collider.on_collision do |other_collider|
    if (other_collider.parent.name == "enemy" || other_collider.parent.name == "enemy_shoot") && !other_collider.parent.pocket[:punched]
      enemy = other_collider.parent
      puts ">>>> PUNCH [#{enemy.object_id}] #{enemy.pocket[:punched]}"

      enemy.pocket[:punched] = true
      enemy.speed = 0
      enemy.add_force(Coordinates.new(800 * ninja.forward.x.sign, -1500))
      enemy.gravity = 100
      @points += enemy.pocket[:points]
      points_hud.text = "Points: #{@points.to_s.rjust(3, '0')}"
    end
  end


  Clock.new {
    enemy_properties =
      if rand(1..10) < 9
        {
          name: "enemy",
          speed_factor: 1.5,
          points: 10
        }
      else
        {
          name: "enemy_shoot",
          speed_factor: 1,
          points: 20
        }
      end

    animation_enemy_walk = Animation.new(sequence: enemy_properties[:name], columns: 4, rows: 7, speed: 10, frames: [3, 7, 11, 15])
    enemy = Actor.new(graphic: animation_enemy_walk)
    enemy.scale = 6
    enemy.position = Coordinates.new(ninja.position.x + [-Global.screen_width, Global.screen_width].sample, 390)
    enemy.flip = "horizontal" if enemy.position.x > ninja.position.x
    enemy.direction = Coordinates.new((ninja.position.x - enemy.position.x).sign, 0)
    enemy.speed = 200 * enemy_properties[:speed_factor]
    enemy_collider = Collider.new(name: "enemy", parent: enemy, solid: true, collision_with: "none")
    enemy.pocket[:punched] = false
    enemy.pocket[:points] = enemy_properties[:points]

    if enemy_properties[:name] == "enemy_shoot"
      Clock.new {
        star = Actor.new(graphic: "star")
        star.scale = 4
        star.position = enemy.position + Coordinates.new(0, 20)
        star.direction = Coordinates.new((ninja.position.x - enemy.position.x).sign, 0)
        star.speed = 200 * 3.5
        Clock.new {
          star.rotation += 10
        }.repeat(seconds: 0.1)
      }.repeat(seconds: 5)
    end
  }.repeat(seconds: 5)

  ninja.on_state(:idle) do
    ninja.graphic = animation_idle

    ninja.on_after_move do
      ninja.state(:walking) if !ninja.direction.zero?
    end

    on_key(27) do
      ninja.state(:punching)
    end
  end

  ninja.on_state(:walking) do
    ninja.graphic = animation_walk

    ninja.on_after_move do
      ninja.state(:idle) if ninja.direction.zero?
    end

    on_key(27) do
      ninja.state(:punching)
    end
  end

  ninja.on_state(:punching) do
    punch_collider.active = true
    ninja.pocket[:punch] = true
    animation_punch.reset
    ninja.graphic = animation_punch
    old_speed = ninja.speed
    ninja.speed = 0

    animation_punch.on_finished do
      ninja.state(:idle)
      ninja.pocket[:punch] = false
      punch_collider.active = false
      ninja.speed = old_speed
    end

    ninja.on_after_move {}
    on_key(27) {} # deactivate punching
  end

  ninja.state(:idle)

  on_loop do
    Camera.main.position.x = ninja.position.x - (Global.screen_width / 2)
    floor.position.x = ninja.position.x - (floor_collider.width / 2)
  end
end

start!
