require "fantasy"

SCREEN_WIDTH = 768
SCREEN_HEIGHT = 768

on_game do
  road_left = 232
  road_track_width = 112

  background = Background.new(image_name: "map")
  Global.camera.speed = 500

  car_red = Actor.new("car_red")
  car_red.name = "car"
  car_red.speed = 50
  car_red.direction = Coordinates.up
  car_red.solid = true

  car_blue = Actor.new("car_blue")
  car_blue.name = "car"
  car_blue.speed = 50
  car_blue.direction = Coordinates.up
  car_blue.solid = true

  map = TileMap.new(map_name: "level_1", tiles: [car_red, car_blue], tile_size: road_track_width)
  map.position = Coordinates.new(road_left, -map.height)
  map.spawn

  car_red.destroy # We don't need the originals
  car_blue.destroy # We don't need the originals

  player = Actor.new("car_green")
  player.position = Coordinates.new(road_left, SCREEN_HEIGHT)
  player.direction = Coordinates.up
  player.speed = 0
  player.solid = true
  player_acceleration = 1
  player_max_speed = 200
  player_moving = false

  player.on_after_move do
    if player.position.x < road_left
      player.position.x = road_left
    end

    if player.position.x > road_left + road_track_width * 2
      player.position.x = road_left + road_track_width * 2
    end
  end

  player.on_collision do |other|
    puts "player.collision: #{other.name}"
    if other.name == "car"
      explosion = Actor.new("explosion")
      explosion.position = other.position
      explosion.layer = -1
      player.speed = 0
      other.destroy
    end
  end

  on_cursor_left do
    player.position.x -= road_track_width
  end

  on_cursor_right do
    player.position.x += road_track_width
  end

  on_loop do
    if player.speed < player_max_speed
      player.speed += player_acceleration
    end
    desired_position = Coordinates.new(0, player.position.y - (SCREEN_HEIGHT - player.height - player.speed))
    Global.camera.position = Tween.move_towards(from: Global.camera.position, to: desired_position, speed: 200)
  end
end

start!
