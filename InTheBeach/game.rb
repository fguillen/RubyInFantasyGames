require "fantasy"

SCREEN_WIDTH = 960
SCREEN_HEIGHT = 540

on_game do
  background = Background.new(image_name: "beach")
  background.scale = 6
end


start!
