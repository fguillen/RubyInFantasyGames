require "fantasy" # Yeah!

SCREEN_WIDTH = 768
SCREEN_HEIGHT = 768

# The Presentation Scene
on_presentation do
  display_top_left = HudText.new(position: Coordinates.new(0, 0))
  display_top_left.text = "Top-Left"

  display_top_right = HudText.new(position: Coordinates.new(SCREEN_WIDTH, 100))
  display_top_right.text = "Top-Right"
  display_top_right.alignment = "top-right"

  display_center = HudText.new(position: Coordinates.new(SCREEN_WIDTH / 2, 200))
  display_center.text = "Center"
  display_center.alignment = "center"
  display_center.size = "big"
end

start!
