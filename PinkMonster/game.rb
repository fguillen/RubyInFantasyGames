require "fantasy"

SCREEN_WIDTH = 300
SCREEN_HEIGHT = 620

ENV["debug"] = "active"

on_game do
  Global.background = Color.palette.peach_puff
  body = Actor.new("body")
  body.position = Coordinates.new(90, 10)
  puts body.to_s

  smile = Actor.new("smile")
  smile.position = Coordinates.new(110, 140)
  # smile will rotate 180 degrees every half of a second
  Clock.new { smile.rotation += 180 }.repeat(seconds: 0.5)

  eye_1 = Actor.new("eye_open")
  eye_1.position = Coordinates.new(120, 80)
  # this eye will blink every 2 seconds
  Clock.new { blink(eye_1) }.repeat(seconds: 2)

  eye_2 = Actor.new("eye_open")
  eye_2.position = Coordinates.new(120, 200)
  # this eye will blink only once right now
  Clock.new { blink(eye_2) }.run_now

  eye_3 = Actor.new("eye_open")
  eye_3.position = Coordinates.new(120, 280)
  # this eye will be closed in 10 senconds
  Clock.new { eye_3.image = "eye_closed" }.run_on(seconds: 10)

  eye_4 = Actor.new("eye_open")
  eye_4.position = Coordinates.new(120, 350)
  # this eye will blink every 1 to 4 seconds
  Clock.new { blink(eye_4) }.repeat(seconds: 1..4)

  eye_5 = Actor.new("eye_open")
  eye_5.position = Coordinates.new(120, 440)
  # this eye will blink every 1 to 4 seconds
  # Same as before. Using the class method version.
  Clock.repeat(seconds: 1..4) { blink(eye_5) }

  eye_6 = Actor.new("eye_open")
  eye_6.position = Coordinates.new(120, 505)
  # this eye will blink every 1 to 4 seconds
  Clock.new { blink(eye_6) }.repeat(seconds: 1..4)
end

def blink(eye)
  eye.image = "eye_closed"
  sleep(0.3)
  eye.image = "eye_open"
end

start!
