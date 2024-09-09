require "fantasy" # Yeah!

SCREEN_WIDTH = 600
SCREEN_HEIGHT = 540

on_game do
  # Final positions
  left_position = 80
  right_position = (SCREEN_WIDTH - 120)

  background = Background.new(image_name: "background")

  # The mashroom
  animation_idle = Animation.new(sequence: "idle", speed: 25, columns: 14)
  animation_run = Animation.new(sequence: "run", speed: 25, columns: 16)
  actor = Actor.new(animation_idle)
  actor.scale = 3
  actor.position = Coordinates.new(left_position, 140)

  # Internal variables
  tween = nil
  actual_ease_index = 0
  actual_ease = Tweeni::EASES[actual_ease_index]

  # The text labels :: INI
  label_instructions = HudText.new(position: Coordinates.new(10, 10))
  label_instructions.text = "left, right to change ease. Space to start."
  label_instructions.alignment = "top-left"
  label_instructions.size = "small"

  label_ease = HudText.new(position: Coordinates.new(10, 30))
  label_ease.text = actual_ease
  label_ease.alignment = "top-left"
  label_ease.size = "big"

  label_position = HudText.new(position: Coordinates.new(10, (SCREEN_HEIGHT - 10)))
  label_position.text = "Position: #{actor.position.x.round(2)}"
  label_position.alignment = "bottom-left"
  label_position.size = "big"
  # The text labels :: END

  # When space bar is pressed we start the tweeni
  on_space_bar do
    if(tween.nil? or tween.finished)
      from = actor.position.x
      to = (actor.position.x < (SCREEN_WIDTH / 2)) ? right_position : left_position
      actor.flip = (to > from) ? "horizontal" : "none"

      # This is the tweeni that is changing the position of the character
      tween =
        Tweeni.start(from:, to:, seconds: 1.5, ease: actual_ease) do |value, step, value_normalized|
          actor.position.x = value
          label_position.text = "Position: #{actor.position.x.round(2)}"

          draw_graph_point(step, value_normalized)
        end

      # Change the animation to run
      actor.sprite = animation_run

      # When the tween is finished we change the animation to idle
      tween.on_finished do
        actor.sprite = animation_idle
      end
    end
  end

  # Capturing cursor left click to change to the previous ease
  on_cursor_left do
    actual_ease_index = (actual_ease_index - 1) % Tweeni::EASES.size
    actual_ease = Tweeni::EASES[actual_ease_index]
    label_ease.text = actual_ease
  end

  # Capturing cursor right click to change to the next ease
  on_cursor_right do
    actual_ease_index = (actual_ease_index + 1) % Tweeni::EASES.size
    actual_ease = Tweeni::EASES[actual_ease_index]
    label_ease.text = actual_ease
  end

  draw_graph_background
end

# Draws the graph background. This is called only once.
def draw_graph_background
  width = 430
  height = 200
  color = Color.from_hex("E4C997")
  color.alpha = 120

  Shape.rectangle(
    position: Coordinates.new(80, 210),
    width:,
    height:,
    fill: true,
    color:
  )
end

# Crates a point in the graph. This is called every time the tween is updated.
def draw_graph_point(step, value)
  width = 430
  height = 200
  radious = 5
  color = Color.from_hex("A14744")
  point_position = Coordinates.new(80, 210) + (Coordinates.new(step, value) * Coordinates.new(width, height))

  # Create a new point in the graph
  point =
    Shape.rectangle(
      position: point_position - (radious / 2.to_f),
      width: radious,
      height: radious,
      fill: true,
      color:
    )

  # Make dots transparent
  tween_color =
    Tweeni.start(from: 255, to: 0, seconds: 2, ease: Tween::Expo::In) do |value|
      point.color.alpha = value
    end

  # When the tween is finished destroy the point
  tween_color.on_finished { point.destroy }
end

start!
