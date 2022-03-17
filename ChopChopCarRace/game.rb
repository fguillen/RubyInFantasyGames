require "fantasy"

SCREEN_WIDTH = 768
SCREEN_HEIGHT = 768

on_game do
  # The game has multiple levels see ./maps/*
  Global.references.level ||= 1
  Global.references.total_levels ||= 3

  road_left = 232 # Coordinate x for the road
  road_track_width = 112
  race_ended = false
  cars_finished = 0

  # Game playable config
  player_acceleration = 1
  cars_speed = 50 + (20 * Global.references.level)
  player_max_speed = 200 + (25 * Global.references.level)

  background = Background.new(image_name: "map") # Background image, by default it is automatically replicated
  Global.camera.position = Coordinates.zero # We start the camera

  # Different text displays
  speed_display = HudText.new(position: Coordinates.new(20, 20))
  speed_display.size = "medium"

  time_display = HudText.new(position: Coordinates.new(SCREEN_WIDTH - 100, 20))
  time_display.size = "medium"

  position_display = HudText.new(position: Coordinates.new(20, 60))
  position_display.visible = false
  position_display.size = "medium"

  level_display = HudText.new(position: Coordinates.new((SCREEN_WIDTH / 2 - 100), SCREEN_HEIGHT / 2))
  level_display.size = "big"
  level_display.text = "Level #{Global.references.level}"

  # The level_display is displayed in the center of the screen
  # after a couple of seconds it moves up until disappear from the screen
  Clock.new do
    100.times do
      level_display.position.y -= 10
      sleep(0.01)
    end
    level_display.destroy
  end.run_on(seconds: 2)

  # The templates for the Tilemap
  car_red = Actor.new("car_red")
  car_red.name = "car"
  car_red.speed = cars_speed
  car_red.direction = Coordinates.up
  car_red.solid = true

  car_blue = Actor.new("car_blue")
  car_blue.name = "car"
  car_blue.speed = cars_speed
  car_blue.direction = Coordinates.up
  car_blue.solid = true

  # Loading the Tilemap and spawning the Actors
  # From the `tiles` param we get the Actor templates
  # From the map in ./maps/* we get the positions
  map = Tilemap.new(map_name: "level_#{Global.references.level}", tiles: [car_red, car_blue], tile_width: road_track_width, tile_height: 150)
  map.position = Coordinates.new(road_left, -map.height)
  map.spawn

   # We don't need the originals
  car_red.destroy
  car_blue.destroy

  # The player
  player = Actor.new("car_green")
  player.position = Coordinates.new(road_left + road_track_width, SCREEN_HEIGHT)
  player.name = "player"
  player.direction = Coordinates.up
  player.speed = 0
  player.solid = true

  # Prevent the player moves out of the road
  player.on_after_move do
    if player.position.x < road_left
      player.position.x = road_left
    end

    if player.position.x > road_left + road_track_width * 2
      player.position.x = road_left + road_track_width * 2
    end
  end

  # Player collides with another car
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

  # Player moves
  on_cursor_left do
    player.position.x -= road_track_width
  end

  on_cursor_right do
    player.position.x += road_track_width
  end

  # The player car sound with acceleration effect
  sound_car =
    Clock.new do
      loop do
        Sound.play("car_sound")
        break if race_ended
        seconds_to_sleep = Utils.remap(value: player.speed, from_ini: 0, from_end: 200, to_ini: 0.8, to_end: 0.3)
        sleep(seconds_to_sleep)
      end
    end.run_now

  # The Finish Line
  finish = Actor.new("finish")
  finish.layer = -1
  finish.solid = true

  # Finish Line position is calculated based to assure player can arrive
  # in first position if not any collision occurs
  # This required the help from the internet: https://math.stackexchange.com/q/4405586/858819
  finish_y_position = (((map.position.y - 450) * player_max_speed) - (player.position.y * cars_speed)) / (player_max_speed - cars_speed).to_f
  finish_y_position -= finish.height + 20 # Collider is at the bottom of the image
  finish.position = Coordinates.new(road_left, finish_y_position)

  # The Finish Line's on collision behaviour
  finish.on_collision do |other|
    other.solid = false

    if other.name == "player"
      race_ended = true

      # We store some persistent data
      Global.references.race_time = Global.seconds_in_scene.to_i
      Global.references.player_position = cars_finished + 1

      # Wining sound
      Sound.play("finish")

       # Go to End Scene in 2 seconds
      Clock.new do
        Global.go_to_end
      end.run_on(seconds: 2)
    end

    if other.name == "car"
      cars_finished += 1
    end
  end

  # The main game loop
  on_loop do
    if player.speed < player_max_speed
      player.speed += player_acceleration
    end

    # Move camera towards the player position
    # With a small delta based on player speed to give some speed sensation
    if !race_ended
      camera_delta = Utils.remap(value: player.speed, from_ini: 0, from_end: player_max_speed, to_ini: 0, to_end: 200)
      desired_position = Coordinates.new(0, player.position.y - (SCREEN_HEIGHT - player.height - camera_delta))
      Global.camera.position = Tween.move_towards(from: Global.camera.position, to: desired_position, speed: player_max_speed)

      time_display.text = Time.at(Global.seconds_in_scene).utc.strftime("%M:%S")
    end

    speed_display.text = "#{player.speed} km/h" # Update the speed display

    # Update the cars finished display
    if cars_finished > 0
      position_display.visible = true
      position_display.text = "#{cars_finished} cars finished"
    end
  end
end

# The END Scene
on_end do
  display = HudText.new(position: Coordinates.new(10, 100), text: "Congrats!\nYou have finished the race in\n<c=3ca370>#{Global.references.race_time} seconds</c>\n\nYou have finished in\n<c=3ca370>#{Global.references.player_position} position</c>");
  display.size = "big"

  # If more levels we continue into the next one
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
