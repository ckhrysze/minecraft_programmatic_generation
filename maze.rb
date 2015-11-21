# Taken from:
# http://weblog.jamisbuck.org/2010/12/27/maze-generation-recursive-backtracking
# --------------------------------------------------------------------

width  = (ARGV[0] || 3).to_i
length = (ARGV[1] || width).to_i
seed   = (ARGV[2] || rand(0xFFFF_FFFF)).to_i
srand(seed)

N, S, E, W = 1, 2, 4, 8
MOVE_X         = { E => 1, W => -1, N =>  0, S => 0 }
MOVE_Z         = { E => 0, W =>  0, N => -1, S => 1 }
OPPOSITE   = { E => W, W =>  E, N =>  S, S => N }

def create_maze(width, length)
  grid = Array.new(length) { Array.new(width, 0) }
  carve_passage(grid, 0, 0)
  grid
end

def carve_passage(grid, current_x, current_z)
  directions = [N, S, E, W].sort_by{rand}

  directions.each do |direction|
    next_x = current_x + MOVE_X[direction]
    next_z = current_z + MOVE_Z[direction]

    if  next_z.between?(0, grid.length-1) &&
        next_x.between?(0, grid[next_z].length-1) &&
        grid[next_z][next_x] == 0
      grid[current_z][current_x] |= direction
      grid[next_z][next_x] |= OPPOSITE[direction]
      carve_passage(grid, next_x, next_z)
    end
  end
end

def expand_into_blocks(grid, material)
  passage_width = 3
  wall_width = 1
  multiplier = passage_width + wall_width
  
  grid_length = grid.size
  grid_width = grid[0].size

  blocks = Array.new(wall_width + grid_length * multiplier) {
    Array.new(wall_width + grid_width * multiplier, material)
  }

  grid_length.times do |z|
    grid_width.times do |x|
      block_z = wall_width + z * multiplier
      block_x = wall_width + x * multiplier

      passage_width.times do |i|
        passage_width.times do |j|
          blocks[block_z+i][block_x+j] = nil
        end
      end
      
      if grid[z][x] & S != 0
        passage_width.times do |i|
          blocks[block_z + passage_width][block_x + i] = nil
        end
      end

      if grid[z][x] & E != 0
        passage_width.times do |i|
          blocks[block_z + i][block_x + passage_width] = nil
        end
      end
    end
  end
  
  blocks
end

grid = create_maze(width, length)
blocks = expand_into_blocks(grid, "minecraft:stonebrick")

blocks.size.times do |z|
  blocks[z].size.times do |x|
    if blocks[z][x].nil?
      print ' '
    else
      print 'X'
    end
  end
  puts
end

puts
puts "#{$0} #{width} #{length} #{seed}"
puts "Done"
