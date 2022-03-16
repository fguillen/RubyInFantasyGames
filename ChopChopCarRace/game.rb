require "fantasy"

SCREEN_WIDTH = 768
SCREEN_HEIGHT = 768

on_game do
  road_left = 232
  road_track_width = 112

  background = Background.new(image_name: "map")
  Global.camera.speed = 500

  car_red = Actor.new("car_red")
  car_red.speed = 50
  car_red.direction = Coordinates.up
  car_red.solid = true

  car_blue = Actor.new("car_blue")
  car_blue.speed = 50
  car_blue.direction = Coordinates.up
  car_blue.solid = true

  map = TileMap.new(map_name: "level_1", tiles: [car_red, car_blue], tile_size: road_track_width)
  map.position = Coordinates.new(road_left, -map.height)
  map.spawn

  car_red.destroy
  car_blue.destroy

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
    Global.camera.position.y = player.position.y - (SCREEN_HEIGHT - player.height - player.speed)
  end
end

start!
