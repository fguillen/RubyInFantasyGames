require "fantasy" # Yeah!

SCREEN_WIDTH = 960
SCREEN_HEIGHT = 540

on_game do
  background = Background.new(image_name: "beach")
  background.scale = 6

  points = HudText.new(position: Coordinates.new(20, 10))
  points.text = 0
  points.size = "big"

  # Turtle
  turtle = Actor.new("turtle")
  turtle.scale = 10
  turtle.position = Coordinates.new(440, 160)
  turtle.solid = true
  turtle.speed = 80 + rand(-30..30)
  turtle.direction = [Coordinates.up, Coordinates.down].sample
  turtle_hunting = false

  turtle_hunt_movement =
    Clock.new do
      turtle.speed = 150
      turtle_hunting = true
      turtle.direction = Coordinates.right
      sleep(2)
      turtle.direction = Coordinates.left
    end

  turtle.on_after_move do
    if turtle.position.x < 440
      turtle.position.x = 440
      turtle.speed = 80 + rand(-30..30)
      turtle_hunting = false
      turtle_hunt_movement.stop
      turtle.direction = [Coordinates.up, Coordinates.down].sample
    end

    if turtle.position.y < 100
      turtle.direction = Coordinates.down
    end

    if turtle.position.y > SCREEN_HEIGHT - 200
      turtle.direction = Coordinates.up
    end
  end

  turtle.on_collision do |other|
    if other.name == "crab" # other is the crab
      other.position = Coordinates.new(600 + rand(-20..20), -40)
      other.speed = 80 + rand(-30..30)
      turtle.direction = Coordinates.left
      points.text += 1
      Sound.play("collectable")
    end
  end

  # The Crab
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

  # The Mom Crab
  mom_crab = Actor.new("mom_crab")
  mom_crab.solid = true
  mom_crab.scale = 10
  mom_crab_attacking = false

  mom_crab_attack =
    Clock.new do
      if(!mom_crab_attacking)
        mom_crab_attacking = true
        mom_crab.speed = 180 + rand(-100..100)
        mom_crab.position.y = turtle.position.y
        mom_crab.position.x = SCREEN_WIDTH + 10
        mom_crab.direction = Coordinates.left
        sleep(2)
        mom_crab.direction = Coordinates.right
      end
    end
  mom_crab_attack.repeat(seconds: (2..5))

  mom_crab.on_after_move do
    if mom_crab.position.x > SCREEN_WIDTH + 10
      mom_crab.speed = 0
      mom_crab_attacking = false
    end
  end

  mom_crab.on_collision do |other|
    if other.name == "turtle"
      turtle.destroy
      Sound.play("lose")
      end_text =
        Clock.new do
          text = HudText.new(position: Coordinates.new(10, 100), text: "Mom crab ate you!. <c=3ca370>Bad luck</c>.");
          text.size = "big"
        end
      end_text.run_on(seconds: 2)
    end
  end

  # When space bar is pressed
  on_space_bar do
    unless turtle_hunting
      turtle_hunt_movement.run_now
    end
  end
end

start!
