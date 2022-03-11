require "fantasy"

SCREEN_WIDTH = 960
SCREEN_HEIGHT = 540

on_game do
  background = Background.new(image_name: "beach")
  background.scale = 6

  points = HudText.new(position: Coordinates.new(20, 10))
  points.text = 0
  points.size = "big"

  turtle = Actor.new("turtle")
  turtle.scale = 10
  turtle.position = Coordinates.new(440, 160)
  turtle.solid = true
  turtle_moving = false

  turtle_hunt_movement =
    Clock.new do
      turtle.speed = 150
      turtle_moving = true
      turtle.direction = Coordinates.right
      sleep(2)
      turtle.direction = Coordinates.left
    end

  turtle.on_after_move do
    if turtle.position.x < 440
      turtle.position.x = 440
      turtle.speed = 0
      turtle_moving = false
      turtle_hunt_movement.stop
    end
  end

  crab = Actor.new("crab")
  crab.scale = 6
  crab.position = Coordinates.new(650 + rand(-50..50), -40)
  crab.solid = true
  crab.speed = 80 + rand(-30..30)
  crab.direction = Coordinates.down

  crab.on_after_move do
    if crab.position.y > SCREEN_HEIGHT
      crab.position = Coordinates.new(600 + rand(-20..20), -40)
      crab.speed = 80 + rand(-30..30)
    end
  end

  turtle.on_collision do |other|
    if other.name == "crab"
      crab.position = Coordinates.new(600 + rand(-20..20), -40)
      crab.speed = 80 + rand(-30..30)
      turtle.direction = Coordinates.left
      points.text += 1
    end
  end



  on_space_bar do
    unless turtle_moving
      turtle_hunt_movement.run_now
    end
  end
end

start!
