require "fantasy"
require "debug"

ENV["debug"] = "active"

SCREEN_WIDTH = 138*3*2
SCREEN_HEIGHT = 90*3

on_game do
  Global.background = Color.from_hex("312520")

  background = Background.new(graphic: "background")
  background.scale = 3
  background.layer = -1

  background_rain = Background.new(graphic: "rain")
  background_rain.scale = 2
  background_rain.layer = -10
  Clock.new {
    background_rain.position.y += 20
    background_rain.position.y = 0 if background_rain.position.y > background_rain.height
  }.repeat(seconds: 0.1)

  background_floor = Background.new(graphic: "floor")
  background_floor.scale = 2
  background_floor.layer = 10
  background_floor.repeat = :horizontal
  background_floor.position = Coordinates.new(0, Global.screen_height - background_floor.height)

  floor = Actor.new(name: "floor")
  floor.layer = 20
  floor.position.y = Global.screen_height - 25
  floor_collider = Collider.new(name: "floor", width: 200, height: 10)
  floor_collider.solid = true
  floor_collider.collision_with = "none"
  floor.add_part(floor_collider)

  animation_walk = Animation.new(sequence: "ninja", columns: 4, rows: 7, speed: 10, frames: [3, 7, 11, 15])
  animation_idle = Animation.new(sequence: "ninja", columns: 4, rows: 7, speed: 1, frames: [3])
  animation_punch = Animation.new(sequence: "ninja", columns: 4, rows: 7, speed: 5, frames: [19], loops: 1)
  ninja = Actor.new(graphic: animation_idle)
  ninja.position = Coordinates.zero
  ninja.scale = 3
  ninja.layer = 0
  ninja.speed = 200
  ninja.gravity = 20
  ninja.jump_force = 500
  ninja.auto_flipable = true
  ninja.move_with_cursors(jump: true, up: false, down: false)
  ninja_collider = Collider.new(name: "ninja", actor: ninja, solid: true)


  animation_enemy_walk = Animation.new(sequence: "enemy", columns: 4, rows: 7, speed: 10, frames: [3, 7, 11, 15])
  enemy = Actor.new(graphic: animation_enemy_walk)
  enemy.scale = 3
  # enemy.flip = "horizontal"
  enemy.position = Coordinates.new(Camera.main.position.x, 194)
  enemy_collider = Collider.new(name: "enemy", actor: enemy, solid: true)


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
    ninja.pocket[:punch] = true
    animation_punch.reset
    ninja.graphic = animation_punch
    old_speed = ninja.speed
    ninja.speed = 0

    animation_punch.on_finished do
      ninja.state(:idle)
      ninja.pocket[:punch] = false
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
