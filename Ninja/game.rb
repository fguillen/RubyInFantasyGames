require "fantasy"
require "debug"

SCREEN_WIDTH = 138*3*2
SCREEN_HEIGHT = 90*3

on_game do
  Global.background = Color.from_hex("312520")

  background = Background.new(image_name: "background")
  background.scale = 3
  background.layer = -1

  rain = Background.new(image_name: "rain")
  rain.scale = 2
  rain.layer = -10
  Clock.new {
    rain.position.y += 20
    rain.position.y = 0 if rain.position.y > rain.height
  }.repeat(seconds: 0.1)

  floor = Background.new(image_name: "floor")
  floor.scale = 2
  floor.layer = 10
  floor.repeat = :horizontal
  floor.position = Coordinates.new(0, Global.screen_height - floor.height)

  animation_walk = Animation.new(sequence: "ninja", columns: 4, rows: 7, speed: 10, frames: [3, 7, 11, 15])
  animation_idle = Animation.new(sequence: "ninja", columns: 4, rows: 7, speed: 1, frames: [3])
  animation_punch = Animation.new(sequence: "ninja", columns: 4, rows: 7, speed: 5, frames: [19], loops: 1)
  actor = Actor.new(animation_idle)
  actor.position = Coordinates.zero
  actor.scale = 3
  actor.layer = 0
  actor.speed = 200
  actor.move_with_cursors

  actor.on_state(:idle) do
    actor.graphic = animation_idle

    actor.on_after_move do
      actor.state(:walking) if !actor.direction.zero?
    end

    on_space_bar do
      actor.state(:punching)
    end
  end

  actor.on_state(:walking) do
    actor.graphic = animation_walk

    actor.on_after_move do
      actor.state(:idle) if actor.direction.zero?

      if actor.direction.x < 0
        actor.flip = "horizontal"
      elsif actor.direction.x > 0
        actor.flip = "none"
      end
    end

    on_space_bar do
      actor.state(:punching)
    end
  end

  actor.on_state(:punching) do
    actor.pocket[:punch] = true
    animation_punch.reset
    actor.graphic = animation_punch
    old_speed = actor.speed
    actor.speed = 0

    animation_punch.on_finished do
      actor.state(:idle)
      actor.pocket[:punch] = false
      actor.speed = old_speed
    end

    actor.on_after_move {}
    on_space_bar {}
  end

  actor.state(:idle)

  on_loop do
    Camera.main.position.x = actor.position.x - (Global.screen_width / 2)
    puts ">>>> actor.pocket[:punch]: #{actor.pocket[:punch]}"
  end
end

start!
