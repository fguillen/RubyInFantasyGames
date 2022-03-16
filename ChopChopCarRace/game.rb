require "fantasy"

SCREEN_WIDTH = 768
SCREEN_HEIGHT = 768

on_game do
  Global.references.level ||= 3
  Global.references.total_levels ||= 3

  road_left = 232
  road_track_width = 112
  race_ended = false
  cars_finished = 0

  background = Background.new(image_name: "map")
  Global.camera.position = Coordinates.zero
  Global.camera.speed = 500

  speed_indicator = HudText.new(position: Coordinates.new(20, 20))
  speed_indicator.size = "medium"

  time_indicator = HudText.new(position: Coordinates.new(SCREEN_WIDTH - 100, 20))
  time_indicator.size = "medium"

  position_indicator = HudText.new(position: Coordinates.new(20, 60))
  position_indicator.visible = false
  position_indicator.size = "medium"

  level_indicator = HudText.new(position: Coordinates.new((SCREEN_WIDTH / 2 - 100), SCREEN_HEIGHT / 2))
  level_indicator.size = "big"
  level_indicator.text = "Level #{Global.references.level}"
  Clock.new do
    100.times do
      level_indicator.position.y -= 10
      sleep(0.01)
    end
    level_indicator.destroy
  end.run_on(seconds: 2)

  car_red = Actor.new("car_red")
  car_red.name = "car"
  car_red.speed = 50 + (20 * Global.references.level)
  car_red.direction = Coordinates.up
  car_red.solid = true

  car_blue = Actor.new("car_blue")
  car_blue.name = "car"
  car_blue.speed = 50 + (20 * Global.references.level)
  car_blue.direction = Coordinates.up
  car_blue.solid = true

  finish = Actor.new("finish")
  finish.solid = true

  finish.on_collision do |other|
    other.solid = false

    if other.name == "player"
      race_ended = true
      Global.references.race_time = Global.seconds_in_scene.to_i
      Sound.play("finish")

      Clock.new do
        Global.go_to_end
      end.run_on(seconds: 2)
    end

    if other.name == "car"
      cars_finished += 1
    end
  end

  map = TileMap.new(map_name: "level_#{Global.references.level}", tiles: [car_red, car_blue, finish], tile_width: road_track_width, tile_height: 150)
  map.position = Coordinates.new(road_left, -map.height)
  map.spawn

  car_red.destroy # We don't need the originals
  car_blue.destroy # We don't need the originals
  finish.destroy # We don't need the originals

  player = Actor.new("car_green")
  player.position = Coordinates.new(road_left, SCREEN_HEIGHT)
  player.name = "player"
  player.direction = Coordinates.up
  player.speed = 0
  player.solid = true
  player_acceleration = 1
  player_max_speed = 200 + (25 * Global.references.level)
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
    if other.name == "car"
      explosion = Actor.new("explosion")
      explosion.position = other.position
      explosion.layer = 10
      Sound.play("crash")
      Clock.new do
        3.times do
          sleep(0.1)
          explosion.scale += 1
          explosion.position.x -= 20
        end
        sleep(0.1)
        explosion.destroy
      end.run_now
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

  sound_car =
    Clock.new do
      loop do
        Sound.play("car_sound")
        break if race_ended
        seconds_to_sleep = Utils.remap(value: player.speed, from_ini: 0, from_end: 200, to_ini: 0.8, to_end: 0.3)
        sleep(seconds_to_sleep)
      end
    end.run_now

  on_loop do
    if player.speed < player_max_speed
      player.speed += player_acceleration
    end

    # Move camera
    if !race_ended
      camera_delta = Utils.remap(value: player.speed, from_ini: 0, from_end: player_max_speed, to_ini: 0, to_end: 200)
      desired_position = Coordinates.new(0, player.position.y - (SCREEN_HEIGHT - player.height - camera_delta))
      Global.camera.position = Tween.move_towards(from: Global.camera.position, to: desired_position, speed: player_max_speed)

      time_indicator.text = Time.at(Global.seconds_in_scene).utc.strftime("%M:%S")
    end

    speed_indicator.text = "#{player.speed} km/h"

    if cars_finished > 0
      position_indicator.visible = true
      position_indicator.text = "#{cars_finished} cars finished"
    end
  end
end

on_end do
  puts "On end!"
  display = HudText.new(position: Coordinates.new(10, 100), text: "Congrats!\nYou have finished the race in\n<c=3ca370>#{Global.references.race_time} seconds</c>");
  display.size = "big"

  if (Global.references.level < Global.references.total_levels)
    Global.references.level += 1

    hud_start = HudText.new(position: Coordinates.new(10, 500), text: "<Click Space to play level #{Global.references.level}>");
    hud_start.size = "medium"

    Clock.new do
      hud_start.visible = !hud_start.visible
    end.repeat(seconds: 1)

    on_space_bar do
      Global.go_to_presentation
    end
  else
    hud_start = HudText.new(position: Coordinates.new(10, 500), text: "You have completed all levels");
    hud_start.size = "medium"
  end
end

start!
