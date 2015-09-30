
require "crsfml"

SIZE_BLOC = 34
NB_BLOCS_WIDHT = 12
NB_BLOCS_HEIGHT = 12
WIDTH = SIZE_BLOC * NB_BLOCS_WIDHT
HEIGHT = SIZE_BLOC * NB_BLOCS_HEIGHT

enum DIRECTION
TOP
BOTTOM
RIGHT
LEFT
end

enum ITEM
EMPTY
WALL
BOX
OBJECTIVE
MARIO
BOX_OK
end


class Map

  def initialize (file)
    @file_input = file
  end

  def simple_map
    map = [[1,1,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,4,0,0,0,0,1],
    [1,1,1,1,1,0,0,1,1,0,1],
    [1,1,1,0,0,0,0,1,1,0,1],
    [1,1,1,0,0,0,0,1,1,0,1],
    [1,1,1,0,0,0,0,0,0,0,1],
    [1,1,1,0,1,0,0,1,1,0,1],
    [1,1,1,2,1,2,2,1,1,0,1],
    [1,1,1,0,0,0,0,0,0,0,1],
    [1,1,1,0,1,0,3,1,0,0,1],
    [1,1,1,0,0,0,0,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,1,1]]
    return map
  end

  def load_map
    if File.file?(@file_input.to_s)
      map = Array.new(0) { [] of Int32 }

      File.open(@file_input.to_s(), "r" ).each_line do |line|
        t = [] of Int32
        line.each_char { |c|
          if c != '\n'
            t.push(c.to_i)
          else
            map << t.clone
            t.clear
          end
        }
      end
      return map
    else
      raise Errno.new("Unable to open '#{@file_input}'")
    end
  end

  def display_map (map)
    wall_texture = SF::Texture.from_file("assets/images/wall.jpg")
    wall = SF::Sprite.new(wall_texture)
    box_texture = SF::Texture.from_file("assets/images/box.jpg")
    box = SF::Sprite.new(box_texture)
    box_ok_texture = SF::Texture.from_file("assets/images/box_ok.jpg")
    box_ok = SF::Sprite.new(box_ok_texture)
    objective_texture = SF::Texture.from_file("assets/images/objective.png")
    objective = SF::Sprite.new(objective_texture)
    floor_texture = SF::Texture.from_file("assets/images/floor.jpg")
    floor = SF::Sprite.new(floor_texture)
    i = j = 0
    obj = false
    p = Array.new(2, 0)
    map.each { |m|
      until j >= NB_BLOCS_HEIGHT - 1
        p[0] = i * SIZE_BLOC
        p[1] = j * SIZE_BLOC
        case map[i][j]
        when ITEM::WALL.value
          wall.position = p
          @window.draw wall
        when ITEM::BOX.value
          box.position = p
          @window.draw box
        when ITEM::BOX_OK.value
          box_ok.position = p
          @window.draw box_ok
        when ITEM::OBJECTIVE.value
          obj = true
          objective.position = p
          @window.draw objective
        when ITEM::EMPTY.value
          floor.position = p
          @window.draw floor
        end
        j+=1
      end
      j = 0
      i+=1
    }
    return obj
  end

end

##################
class Game < Map

  def initialize (map)
    @map = map
    @pos_mario = [0.0, 0.0]
    @obj :: Bool
    @window = SF::RenderWindow.new(SF.video_mode(WIDTH , HEIGHT- SIZE_BLOC), "Mario Sokoban !")
  end

  private def find_mario
    i = j = 0
    @map.each { |m|
      while j != NB_BLOCS_HEIGHT - 1
        if m[j] == ITEM::MARIO.value
          @pos_mario[0] = i.to_f
          @pos_mario[1] = j.to_f
        end
        j+=1
      end
      i+=1
      j = 0
    }
  end

  private def move_player (direction)
    x = @pos_mario[0].to_i
    y = @pos_mario[1].to_i
    case direction
    when DIRECTION::TOP
      if y - 1 < 0
        return
      end
      if @map[x][y - 1] == ITEM::WALL.value
        return
      end
      if (@map[x][y - 1] == ITEM::BOX.value || @map[x][y - 1] == ITEM::BOX_OK.value) &&
        (y - 2 < 0 || @map[x][y - 2] == ITEM::WALL.value ||
        @map[x][y - 2] == ITEM::BOX.value || @map[x][y - 2] == ITEM::BOX_OK.value)
        return
      end
      move_box({x , y - 1}, {x , y - 2})
      @map[x.to_i][y.to_i] = ITEM::EMPTY.value
      @map[x.to_i][y.to_i - 1] = ITEM::MARIO.value
      @pos_mario[1] -= 1.0

    when DIRECTION::BOTTOM
      if y + 1 >= NB_BLOCS_WIDHT
        return
      end
      if @map[x][y + 1] == ITEM::WALL.value
        return
      end
      if (@map[x][y + 1] == ITEM::BOX.value || @map[x][y + 1] == ITEM::BOX_OK.value) &&
        (y + 2 < 0 || @map[x][y + 2] == ITEM::WALL.value ||
        @map[x][y + 2] == ITEM::BOX.value || @map[x][y + 2] == ITEM::BOX_OK.value)
        return
      end
      move_box({x , y + 1}, {x , y + 2})
      @map[x.to_i][y.to_i] = ITEM::EMPTY.value
      @map[x.to_i][y.to_i + 1] = ITEM::MARIO.value
      @pos_mario[1] += 1.0

    when DIRECTION::LEFT
      if x - 1 < 0
        return
      end
      if @map[x - 1][y] == ITEM::WALL.value
        return
      end
      if (@map[x - 1][y] == ITEM::BOX.value || @map[x - 1][y] == ITEM::BOX_OK.value) &&
        (y - 2 < 0 || @map[x - 2][y] == ITEM::WALL.value ||
        @map[x - 2][y] == ITEM::BOX.value || @map[x - 2][y] == ITEM::BOX_OK.value)
        return
      end
      move_box({x - 1, y}, {x - 2, y})
      @map[x.to_i][y.to_i] = ITEM::EMPTY.value
      @map[x.to_i - 1][y.to_i] = ITEM::MARIO.value
      @pos_mario[0] -= 1.0

    when DIRECTION::RIGHT
      if x + 1 >= NB_BLOCS_WIDHT
        return
      end
      if @map[x + 1][y] == ITEM::WALL.value
        return
      end
      if (@map[x + 1][y] == ITEM::BOX.value || @map[x + 1][y] == ITEM::BOX_OK.value) &&
        (y + 2 < 0 || @map[x + 2][y] == ITEM::WALL.value ||
        @map[x + 2][y] == ITEM::BOX.value || @map[x + 2][y] == ITEM::BOX_OK.value)
        return
      end
      move_box({x + 1, y}, {x + 2, y})
      @map[x.to_i][y.to_i] = ITEM::EMPTY.value
      @map[x.to_i + 1][y.to_i] = ITEM::MARIO.value
      @pos_mario[0] += 1.0
    end
  end

  private def move_box (b1, b2)
    box_1 = @map[b1.first][b1.last]
    box_2 = @map[b2.first][b2.last]

    if box_1 == ITEM::BOX.value || box_1 == ITEM::BOX_OK.value
      if box_2 == ITEM::OBJECTIVE.value
        @map[b2.first][b2.last] = ITEM::BOX_OK.value
      else
        @map[b2.first][b2.last] = ITEM::BOX.value
      end
      if box_1 == ITEM::BOX_OK.value
        @map[b1.first][b1.last] = ITEM::OBJECTIVE.value
      else
        @map[b1.first][b1.last] =  ITEM::EMPTY.value
      end
    end
  end

  private def play_game
    @window.clear SF.color(96, 96, 96)
    mario_top_text = SF::Texture.from_file("assets/images/mario_top.gif")
    mario_top = SF::Sprite.new(mario_top_text)
    mario_bottom_text = SF::Texture.from_file("assets/images/mario_bottom.gif")
    mario_bottom = SF::Sprite.new(mario_bottom_text)
    mario_left_text = SF::Texture.from_file("assets/images/mario_left.gif")
    mario_left = SF::Sprite.new(mario_left_text)
    mario_right_text = SF::Texture.from_file("assets/images/mario_right.gif")
    mario_right = SF::Sprite.new(mario_right_text)
    mario = {
      DIRECTION::TOP => mario_top,
      DIRECTION::BOTTOM => mario_bottom,
      DIRECTION::LEFT => mario_left,
      DIRECTION::RIGHT => mario_right
    }
    find_mario
    current_mario = mario[DIRECTION::RIGHT]
    current_mario.position = SF.vector2(@pos_mario.at(0) * SIZE_BLOC.to_f, @pos_mario.at(1) * SIZE_BLOC.to_f)
    while @window.open?
      while event = @window.poll_event()
        if event.type == SF::Event::Closed || (event.type == SF::Event::KeyPressed && event.key.code == SF::Keyboard::Escape)
          @window.close()
        elsif event.type == SF::Event::KeyPressed
          case event.key.code
          when SF::Keyboard::Z
            current_mario = mario[DIRECTION::TOP]
            move_player DIRECTION::TOP
          when SF::Keyboard::Q
            current_mario = mario[DIRECTION::LEFT]
            move_player DIRECTION::LEFT
          when SF::Keyboard::S
            current_mario = mario[DIRECTION::BOTTOM]
            move_player  DIRECTION::BOTTOM
          when SF::Keyboard::D
            current_mario = mario[DIRECTION::RIGHT]
            move_player DIRECTION::RIGHT
          end
          current_mario.position = SF.vector2( @pos_mario.at(0) * SIZE_BLOC.to_f, @pos_mario.at(1) * SIZE_BLOC.to_f)
          @window.clear SF.color(96,96,96)
        end
      end
      @obj = display_map @map
      if @obj == false
        end_game
        return
      end
      @window.draw current_mario
      @window.display
    end
  end

  private def end_game
    @window.clear SF.color(0,0,0)
    font = SF::Font.from_file("assets/font/font.ttf")
    text = SF::Text.new("You win !", font)
    text.character_size= 35
    text.position = SF.vector2(WIDTH.to_f / 3.0, HEIGHT.to_f / 2.5)
    text.color = SF::Color::White
    while @window.open?
      while event = @window.poll_event()
        if event.type == SF::Event::Closed || (event.type == SF::Event::KeyPressed && event.key.code == SF::Keyboard::Escape)
          @window.close()
        end
      end
      @window.draw text
      @window.display
    end
  end

  def run
    font = SF::Font.from_file("assets/font/font.ttf")
    text = SF::Text.new("Press Space to play !", font)
    text.character_size= 25
    text.position = SF.vector2(WIDTH.to_f / 4.0, HEIGHT.to_f / 2.5)
    text.color = SF::Color::White
    while @window.open?
      while event = @window.poll_event()
        if event.type == SF::Event::Closed || (event.type == SF::Event::KeyPressed && event.key.code == SF::Keyboard::Escape)
          @window.close()
        elsif event.type == SF::Event::KeyPressed
          case event.key.code
          when SF::Keyboard::Space
            play_game
          end
        end
      end
      @window.draw text
      @window.display
    end
  end

end

#################################

if  ARGV.empty?
  m = Map.new ("")
  g = Game.new (m.simple_map)
  g.run
else
  begin 
    m = Map.new (ARGV[0])
    g = Game.new (m.load_map)
    g.run
  rescue e
    puts e.message
  end
end
