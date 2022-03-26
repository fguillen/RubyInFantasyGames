require "fantasy" # Yeah!

SCREEN_WIDTH = 1760
SCREEN_HEIGHT = 900

# Game Scene
on_game do
  lifeboat = Actor.new("lifeboat")
  lifeboat.scale = 2
  lifeboat.position = Coordinates.new(100, 300)
  lifeboat.solid = true
  lifeboat.speed = 200
  lifeboat.move_with_cursors(left: true, right: true)

  lemon = Actor.new("lemon")
  lemon.scale = 2
  lemon.position = Coordinates.new(100, 100)
  lemon.gravity = 100
  lemon.solid = true
  lemon.jump = 200
  lemon.speed = 100
  lemon.direction = Coordinates.right

  lemon.on_collision do |other|
    if other.name = "lifeboat"
      puts "XXX: jump"
      lemon.execute_jump
    end
  end

  lemon.on_start_jumping do
    puts "on_start_jumping"
  end

end

start!
