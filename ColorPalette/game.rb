require "fantasy" # Yeah!

SCREEN_WIDTH = 1760
SCREEN_HEIGHT = 900

# Game Scene
on_game do
  Global.background = Color.palette.white

  color_names = Color.palette.to_h.keys

  num_rows = 15
  num_columns = 10
  card_width = SCREEN_WIDTH / num_columns
  card_height = SCREEN_HEIGHT / num_rows

  labels = []
  labels_visible = true

  num_rows.times.each do |row|
    num_columns.times.each do |column|
      color_name = color_names[(row * num_columns) + column]
      position_card = Coordinates.new(column * card_width, row * card_height)

      position_shape = position_card + Coordinates.new(10, 5)
      shape = Shape.rectangle(position: position_shape, width: card_width - 20, height: card_height/2)
      shape.color = Color.palette[color_name]
      shape.stroke = 0

      puts "color: #{shape.color}"

      # Change global background color when color is clicked
      shape.on_click do
        Global.background = shape.color
      end

      position_text = position_card + Coordinates.new(card_width/2, card_height - 15)
      label = HudText.new(text: color_name, position: position_text)
      label.color = Color.palette.slate_gray
      label.background_color = nil
      label.alignment = "center"
      label.size = "small"
      label.visible = labels_visible
      labels << label
    end
  end

  # Click space to toggle color names visibility
  on_space_bar do
    labels_visible = !labels_visible
    puts "labels_visible: #{labels_visible}"
    labels.each do |text|
      text.visible = labels_visible
    end
  end
end

start!
