require "fantasy" # Yeah!

SCREEN_WIDTH = 600
SCREEN_HEIGHT = 540

rubies_to_collect = 1
rubies_collected = 0
level = 1

on_presentation do
  # Show the instruction messages
  HudText.new(position: Coordinates.new(20, 150), text: "Level #{level}")
  HudText.new(position: Coordinates.new(20, 200), text: "Collect #{rubies_to_collect} space rubies to win!")

  # This message appears after 2 seconds
  Clock.run_on(seconds: 2) do
    HudText.new(position: Coordinates.new(20, 250), text: "Press space to start!")
  end

  # Start game when space bar pressed
  on_space_bar do
    Global.go_to_game
  end
end

# Game Scene.
# Put here all the game logic.
on_game do
  # Set the background image
  background = Background.new(image_name: "background")

  # This is the points counter
  points = HudText.new(position: Coordinates.new(20, 10))
  points.text = rubies_collected
  points.size = "big"

  # This is the level counter
  level_counter = HudText.new(position: Coordinates.new((SCREEN_WIDTH - 20), 10))
  level_counter.text = "Level #{level}"
  level_counter.size = "big"
  level_counter.alignment = "top-right"

  # This is the character
  character = Actor.new("character")
  character.position = Coordinates.new(50, 290)

  # Move the background
  Clock.repeat(seconds: 0.01) do
    background.position.x -= 1
  end

  # When space bar is pressed character jumps
  character_jumping = false
  on_space_bar do
    unless character_jumping
      character_jumping = true
      Clock.run_now do
        character.position.y -= 100
        character.image = "character_jump"
        Sound.play("jump")

        sleep(1.5)

        character.position.y += 100
        character.image = "character"
        character_jumping = false
      end
    end
  end

  # Random objects appear. Some times a ruby, some times a rock
  # Collect the rubies, avoid the rocks.
  Clock.repeat(seconds: 2..4) do
    object_name = ["ruby", "rock"].sample

    object = Actor.new(object_name)
    object.position = Coordinates.new(SCREEN_WIDTH + 10, 375)

    object.direction = Coordinates.left
    object.speed = 250

    object.collision_with = ["character"]
    object.on_collision do |other|
      if object_name == "ruby"
        Sound.play("ruby")
        rubies_collected += 1
        points.text = rubies_collected
        object.destroy

        if rubies_collected == rubies_to_collect
          Global.go_to_end
        end

      elsif object_name == "rock"
        Global.go_to_end
      end
    end
  end
end

# This is when the game ends
on_end do
  # is it a win or a lose?
  if rubies_collected == rubies_to_collect
    message = "You won!"
    restart_message = "Press space to go to the next level!"
    Sound.play("win")
    rubies_to_collect *= 2
    level += 1
    rubies_collected = 0
  else
    message = "You lost the rubies!"
    restart_message = "Press space to try again!"
    Sound.play("lose")
  end

  # Show the messages
  HudText.new(position: Coordinates.new(20, 200), text: message)
  Clock.run_on(seconds: 2) do
    HudText.new(position: Coordinates.new(20, 250), text: restart_message)
  end

  # On space bar clicked go back to the presentation
  on_space_bar do
    Global.go_to_presentation
  end
end

start!
