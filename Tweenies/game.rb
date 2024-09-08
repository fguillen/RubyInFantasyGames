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
  actor.position = Coordinates.new(left_position, 210)

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

  on_space_bar do
    if(tween.nil? or tween.finished)
      from = actor.position.x
      to = (actor.position.x < (SCREEN_WIDTH / 2)) ? right_position : left_position
      actor.flip = (to > from) ? "horizontal" : "none"

      tween =
        Tweeni.start(from:, to:, seconds: 1.5, ease: actual_ease) do |value|
          actor.position.x = value
          label_position.text = "Position: #{actor.position.x.round(2)}"
        end

      actor.sprite = animation_run

      tween.on_finished do
        actor.sprite = animation_idle
      end
    end
  end

  on_cursor_left do
    actual_ease_index = (actual_ease_index - 1) % Tweeni::EASES.size
    actual_ease = Tweeni::EASES[actual_ease_index]
    label_ease.text = actual_ease
  end

  on_cursor_right do
    actual_ease_index = (actual_ease_index + 1) % Tweeni::EASES.size
    actual_ease = Tweeni::EASES[actual_ease_index]
    label_ease.text = actual_ease
  end
end

start!
