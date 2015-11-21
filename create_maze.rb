require 'fileutils'

# Taken from:
# http://weblog.jamisbuck.org/2010/12/27/maze-generation-recursive-backtracking
# --------------------------------------------------------------------

$stdout.sync = true

width  = (ARGV[0] || 17).to_i
length = (ARGV[1] || width).to_i
seed   = (ARGV[2] || rand(0xFFFF_FFFF)).to_i
srand(seed)

N, S, E, W = 1, 2, 4, 8
MOVE_X         = { E => 1, W => -1, N =>  0, S => 0 }
MOVE_Z         = { E => 0, W =>  0, N => -1, S => 1 }
OPPOSITE   = { E => W, W =>  E, N =>  S, S => N }

def carve_passages_from(current_x, current_z, grid)
  directions = [N, S, E, W].sort_by{rand}

  directions.each do |direction|
    next_x = current_x + MOVE_X[direction]
    next_z = current_z + MOVE_Z[direction]

    if  next_z.between?(0, grid.length-1) &&
        next_x.between?(0, grid[next_z].length-1) &&
        grid[next_z][next_x] == 0
      grid[current_z][current_x] |= direction
      grid[next_z][next_x] |= OPPOSITE[direction]
      carve_passages_from(next_x, next_z, grid)
    end
  end
end

def expand_into_blocks(grid, material)
  grid_length = grid.size
  grid_width = grid[0].size

  blocks = Array.new(grid_length * 2 + 1) {
    Array.new(grid_width * 2 + 1, material)
  }

  grid_length.times do |z|
    grid_width.times do |x|
      block_z = 1 + z*2
      block_x = 1 + x*2
      blocks[block_z][block_x] = nil

      if grid[z][x] & S != 0
        blocks[block_z+1][block_x] = nil
      end

      if grid[z][x] & E != 0
        blocks[block_z][block_x+1] = nil
      end
    end
  end
  
  blocks
end

def fill(
    start_x, start_y, start_z,
    end_x, end_y, end_z,
    block, block_data=0, handling="replace")
  parts = ["fill"]
  parts += [start_x, start_y, start_z, end_x, end_y, end_z]
  parts += [block, block_data, handling]
  parts.join(" ")
end

if Dir.exist?("maze")
  puts "Clearing previous map"
  FileUtils.rm_r "maze"
end

IO.popen("java -Xms1024M -Xmx2048M -jar minecraft_server.1.8.8.jar nogui", mode="r+") do |io|
  sleep(2)
  until io.eof?
    line = io.gets
    puts line

    if line =~ /.*Done.*For help.*/
      puts "Creating maze"

      grid = Array.new(length) { Array.new(width, 0) }
      carve_passages_from(0, 0, grid)
      blocks = expand_into_blocks(grid, "minecraft:stonebrick")

      io.puts fill(width-4, 4, -1, width-4, 7, -6, "minecraft:glass")
      io.puts fill(width+4, 4, -1, width+4, 7, -6, "minecraft:glass")
      io.puts fill(width-4, 4, -6, width+4, 7, -6, "minecraft:glass")

      blocks.size.times do |z|
        blocks[z].size.times do |x|
          io.puts fill(z, 4, x, z, 7, x, blocks[z][x]) unless blocks[z][x].nil?
        end
      end

      io.puts fill(width, 4, 0, width, 7, 0, "minecraft:air")
      io.puts fill(width, 4, length*2, width, 7, length*2, "minecraft:air")
      
      io.puts "setworldspawn #{width} 4 -2"
      io.puts "gamerule doDaylightCycle false"
      #io.puts "stop"
    end
  end
end

puts
puts "#{$0} #{width} #{length} #{seed}"
puts "Done"
