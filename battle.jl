using Random: shuffle!

TEAM_ONE_LINE = 1
EMPTY_FIELD_ONE = 2
EMPTY_FIELD_TWO = 3
TEAM_TWO_LINE = 4


"""Clear the battlefield so it can be printed again"""
function clear_battlefield()
    # move the cursor to beginning of the line n (4) lines up so we can print again
    print("\u1b[4F")
    # clear the rest of the top line just in case
    print("\u1b[0K")
end


function print_board(board, t)
    clear_battlefield()
    for line in board
        for square in line
            print(square)
        end
        println()
    end
    sleep(t)
end


"""Lay out a new board with two teams of soldiers and two lines of empty squares between them"""
function prepare_board(team_one, team_two, empty_square_name::String)

    name_length = length(empty_square_name)
    return [
        [Square(x, lengthen_name(x, name_length), true) for x in team_one],
        [Square(empty_square_name, empty_square_name, false) for _ in team_one],
        [Square(empty_square_name, empty_square_name, false) for _ in team_two],
        [Square(x, lengthen_name(x, name_length), true) for x in team_two]
    ]
end


"""A warrior or an empty square on the battlefield"""
struct Square
    name::String
    state::String
    is_warrior::Bool
end

# Warrior/Square functions #
kill_warrior(warrior, dead_square_name) = Square(dead_square_name, dead_square_name, warrior.is_warrior)


remove_warrior(empty_square_name) = Square(empty_square_name, empty_square_name, false)


wound_warrior(warrior, new_state) = Square(warrior.name, new_state, warrior.is_warrior)


"""Checks if a given warrior (square) is alive - is it a warrior and does it not have a wound in its centre position?"""
function is_warrior_alive(square)
    if !square.is_warrior
        return square.is_warrior
    end
    warrior_heart = square.state[Int(ceil(length(square.state)/2))]
    return warrior_heart !== '_' && warrior_heart !== ' '
end


"""Checks if any warriors in a line are alive"""
function warriors_are_alive(line)
    for warrior in line
        if is_warrior_alive(warrior)
            return true
        end
    end
    return false
end


Base.print(io::IO, x::Square) = print(io, x.state)
# ------------------------ #


"""Play out a round of army manoeuvring - one warrior from each army steps forward, and either kills or duals an opposite warrior"""
function initiate_combat!(board, empty_square_name, dead_square_name; t)

    team_one = board[TEAM_ONE_LINE]
    team_two = board[TEAM_TWO_LINE]
    # pick a brave warrior for each team - they will be honoured!
    i_first_noble = i_second_noble = ""
    while true
        i_first_noble = rand(1:length(team_one))
        i_second_noble = rand(1:length(team_two))
        if is_warrior_alive(team_one[i_first_noble]) && is_warrior_alive(team_two[i_second_noble])
            break
        end
    end

    first_noble = team_one[i_first_noble]
    second_noble = team_two[i_second_noble]

    # remove the brave warriors from their line
    board[TEAM_ONE_LINE][i_first_noble] = remove_warrior(empty_square_name)
    board[TEAM_TWO_LINE][i_second_noble] = remove_warrior(empty_square_name)

    # put them in the empty fields
    board[EMPTY_FIELD_ONE][i_first_noble] = first_noble
    board[EMPTY_FIELD_TWO][i_second_noble] = second_noble

    # create tension for the conflict
    print_board(board, t/1.8)

    # if opposite each other, they must dual - a special scenario
    if i_first_noble == i_second_noble
        initiate_single_combat!(board, i_first_noble, i_second_noble, dead_square_name, t=t)
        return
    end

    # otherwise, KILL their enemies!
    board[TEAM_TWO_LINE][i_first_noble] = kill_warrior(board[TEAM_TWO_LINE][i_first_noble], dead_square_name)
    board[TEAM_ONE_LINE][i_second_noble] = kill_warrior(board[TEAM_ONE_LINE][i_second_noble], dead_square_name)
end


"""Play out a glorious dual between two great warriors - honour to the victor!"""
function initiate_single_combat!(board, i_first_noble, i_second_noble, dead_square_name; t)

    first_noble_state = board[EMPTY_FIELD_ONE][i_first_noble].state
    second_noble_state = board[EMPTY_FIELD_TWO][i_second_noble].state

    while is_warrior_alive(board[EMPTY_FIELD_ONE][i_first_noble]) && is_warrior_alive(board[EMPTY_FIELD_TWO][i_second_noble])
        # add a wound randomly in the state of one warrior - a wound to the heart will kill them!
        # decide which warrior to wound
        which_noble = rand(1:2)
        if which_noble == 1

            wound = rand(1:length(first_noble_state))
            first_noble_state[wound] == '_' && continue
            first_noble_state = first_noble_state[1:wound-1] * '_' * first_noble_state[wound+1:length(first_noble_state)]
            board[EMPTY_FIELD_ONE][i_first_noble] = wound_warrior(board[EMPTY_FIELD_ONE][i_first_noble], first_noble_state)
        elseif which_noble == 2
            wound = rand(1:length(second_noble_state))
            second_noble_state[wound] == '_' && continue
            second_noble_state = second_noble_state[1:wound-1] * '_' * second_noble_state[wound+1:length(second_noble_state)]
            board[EMPTY_FIELD_TWO][i_second_noble] = wound_warrior(board[EMPTY_FIELD_TWO][i_second_noble], second_noble_state)
        end

        print_board(board, t/4)
    end
    if !is_warrior_alive(board[EMPTY_FIELD_ONE][i_first_noble])
        board[EMPTY_FIELD_ONE][i_first_noble] = kill_warrior(board[EMPTY_FIELD_ONE][i_first_noble], dead_square_name)
    elseif !is_warrior_alive(board[EMPTY_FIELD_TWO][i_second_noble])
        board[EMPTY_FIELD_TWO][i_second_noble] = kill_warrior(board[EMPTY_FIELD_TWO][i_second_noble], dead_square_name)
    end
end


find_square_length(names) = maximum(length.(names))


"""Add spaces to every name in a list of names until they are square_length long"""
function lengthen_name(name::String, square_length::Int)
    if length(name) < square_length
        # add padding to each side
        dif = square_length - length(name)
        return repeat(" ", Int(floor(dif/2))) * name * repeat(" ", Int(ceil(dif/2)))
    end
    return name
end

"""
	battle(names; t=1)

Line up your players in two battle lines, and see whose tactical genius delivers their side a victory!
Randomly picks teams and advances the bravest warriors to kill & maim their opponents, until only one side is left standing.

"""
function battle(names; t=1)
	# prepare teams and a board #
    print("\n\n\n")
    shuffle!(names)
    # remove a random player if we have an odd number of soldiers
    (length(names) % 2 == 1) && (pop!(names))
    square_length = find_square_length(names)
    # lengthen_names!(names, square_length)
    split = length(names) ÷ 2

    team_one = names[1:split]
    team_two = names[split+1:length(names)]

    empty_square_name = repeat(" ", square_length)
    dead_square_name = repeat(" ", square_length)
    board = prepare_board(team_one, team_two, empty_square_name)
	# ------------------------- #

	# play the game
    while true
        print_board(board, t/1.4)

		# if both sides are still lined up, initiate battle line activity
		if warriors_are_alive(board[TEAM_ONE_LINE]) && warriors_are_alive(board[TEAM_TWO_LINE])
            initiate_combat!(board, empty_square_name, dead_square_name, t=t)

        # if the rear lines have been killed, begin the final duals!
		else
            # get a warrior from each team
            i_first_noble = i_second_noble = 0
            for i in 1:length(board[EMPTY_FIELD_ONE])
                if is_warrior_alive(board[EMPTY_FIELD_ONE][i])
                    i_first_noble = i
                    break
                end
            end
            for i in 1:length(board[EMPTY_FIELD_TWO])
                if is_warrior_alive(board[EMPTY_FIELD_TWO][i])
                    i_second_noble = i
                    break
                end
            end

            initiate_single_combat!(board, i_first_noble, i_second_noble, dead_square_name, t=t)

            # If one army alone stands alive, honour them and their great general, who will lead their people in standing up tomorrow
            alive_warriors = []
            if !warriors_are_alive(board[EMPTY_FIELD_ONE])
                for warrior in board[EMPTY_FIELD_TWO]
                    if is_warrior_alive(warrior)
                        append!(alive_warriors, [warrior.name])
                    end
                end
            elseif !warriors_are_alive(board[EMPTY_FIELD_TWO])
                for warrior in board[EMPTY_FIELD_ONE]
                    if is_warrior_alive(warrior)
                        append!(alive_warriors, [warrior.name])
                    end
                end
            end
            if length(alive_warriors) > 0
                i = rand(1:length(alive_warriors))
                winner = uppercase(alive_warriors[i])
                deleteat!(alive_warriors, i)


                output = "GLORY to the victorious general, $winner"
                # print out any additional soldiers who survived the battle
                output_end = ", they have left all other warriors behind in the mud of the battlefield"
                (length(alive_warriors) > 0) && (output_end = ", and their measly soldiers: $(join(alive_warriors, ", ", " and "))")
                output = output * output_end

                println(output)
                return
            end
        end
    end
	return
end

# test behaviour
names = ["maxim", "neil", "keoki", "matej", "beatrice", "ariovistus", "romi", "napoleon", "brian", "pelagius", "keoki", "san"]
battle(names, t=1)