class ValueError < RuntimeError
end

class Cave
  def initialize()
    @edges = [[1, 2], [2, 10], [10, 11], [11, 8], [8, 1], [1, 5], [2, 3], [9, 10], [20, 11], [7, 8], [5, 4],
                      [4, 3], [3, 12], [12, 9], [9, 19], [19, 20], [20, 17], [17, 7], [7, 6], [6, 5], [4, 14], [12, 13],
                      [18, 19], [16, 17], [15, 6], [14, 13], [13, 18], [18, 16], [16, 15], [15, 14]]
    # add cave attributes
    @rooms = Hash.new
    (1..20).each do |val|
      @rooms[val] = Room.new(val)
    end
    @edges.each do |edge|
      @rooms[edge[0]].connect(@rooms[edge[1]])
    end
  end
  # add cave methods
  def add_hazard(h, n)
    noHazards = @rooms.reject {|key, value| value.has?(h)}
    noHazards.values.sample(n).each do |rm|
      rm.add(h)
    end
  end

  def random_room()
    return @rooms.values.sample()
  end

  def room_with(hazard)
    @rooms.values.each do |rm|
      if rm.has?(hazard) then return rm end
    end
    return nil
  end

  def move(hazard, frm, to)
    frm.remove(hazard)
    to.add(hazard)
  end

  def room(n)
    if !@rooms.keys.include?(n) then return nil end
    return @rooms[n]
  end

  def entrance() 
    @rooms.values.each do |rm|
      if rm.safe? then return rm end
    end
  end
end

class Player
  # add specified Player methods
  attr_reader :room
  def initialize()
    @senses = Hash.new
    @encounters = Hash.new
    @actions = Hash.new
    @room = 0
  end

  def sense(hazard, &callback)
    @senses[hazard] = callback
  end

  def encounter(hazard, &callback)
    @encounters[hazard] = callback
  end

  def action(act, &callback)
    @actions[act] = callback
  end

  def enter(room)
    @room = room
    @encounters.keys.each do |hz|
      if room.has?(hz) then return @encounters[hz].call() end
    end
  end

  def explore_room
    room.neighbors.each do |nb|
      nb.hazards.each do |hz|
        @senses[hz].call()
      end
    end
  end

  def act(action, destination) 
    if !@actions.keys.include?(action) then raise KeyError end
    @actions[action].call(destination)
  end

end

class Room
  attr_reader :number, :hazards, :neighbors
  # add specified Room methods
  def initialize(number)
    @number = number
    @hazards = Array.new
    @neighbors = Array.new
  end

  def add(hazard) 
    @hazards.append(hazard)
  end

  def has?(hazard)
    @hazards.include?(hazard)
  end

  def remove(hazard)
    if !has?(hazard) then raise ValueError end
    @hazards.delete(hazard)
  end

  def empty?()
    @hazards.length == 0
  end

  def safe?()
    if @hazards.length != 0 then return false end
    @neighbors.each do |nb|
      if nb.hazards.size != 0 then return false end
    end
    return true
  end

  def connect(other_room)
    if @neighbors.include?(other_room) then return end
    @neighbors.append(other_room)
    other_room.connect(self)
  end

  def exits()
    out = []
    @neighbors.each do |nb|
      out.append(nb.number)
    end
    return out
  end
  
  def neighbor(number)
    @neighbors.each do |nb|
      if nb.number == number then return nb end
    end
    return nil
  end

  def random_neighbor()
    if @neighbors.size == 0 then raise IndexError end
    return @neighbors[rand(0...@neighbors.size)]
  end
end

class Console
  def initialize(player, narrator)
    @player   = player
    @narrator = narrator
  end

  def show_room_description
    @narrator.say "-----------------------------------------"
    @narrator.say "You are in room #{@player.room.number}."

    @player.explore_room

    @narrator.say "Exits go to: #{@player.room.exits.join(', ')}"
  end

  def ask_player_to_act
    actions = {"m" => :move, "s" => :shoot, "i" => :inspect }

    accepting_player_input do |command, room_number|
      @player.act(actions[command], @player.room.neighbor(room_number))
    end
  end

  private

  def accepting_player_input
    @narrator.say "-----------------------------------------"
    command = @narrator.ask("What do you want to do? (m)ove or (s)hoot?")

    unless ["m","s"].include?(command)
      @narrator.say "INVALID ACTION! TRY AGAIN!"
      return
    end

    dest = @narrator.ask("Where?").to_i

    unless @player.room.exits.include?(dest)
      @narrator.say "THERE IS NO PATH TO THAT ROOM! TRY AGAIN!"
      return
    end

    yield(command, dest)
  end
end

class Narrator
  def say(message)
    $stdout.puts message
  end

  def ask(question)
    print "#{question} "
    $stdin.gets.chomp
  end

  def tell_story
    yield until finished?

    say "-----------------------------------------"
    describe_ending
  end

  def finish_story(message)
    @ending_message = message
  end

  def finished?
    !!@ending_message
  end

  def describe_ending
    say @ending_message
  end
end
