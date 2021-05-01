#cython: language_level=3
cimport Board
cimport Maps
cimport misc
import Board

cdef int PERFT_CHECK = 0
cdef int PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING
cdef int ENEMY_PAWN, ENEMY_KNIGHT, ENEMY_BISHOP, ENEMY_ROOK, ENEMY_QUEEN, ENEMY_KING
cdef unsigned short MOVES[220]
cdef unsigned long long PINNED_PIECES[8]

cdef class Move:
#holds all critical information for a given move
    #a move is a 16 bit short interger
    #first 6 bits describe the starting position and the next 6 describe the ending position while the last 4 are flags
    #the flags are as follows: promotion flag, capture flag, special 1, special 2

    @staticmethod
    cdef inline unsigned short encode_move(unsigned short starting_pos, unsigned short final_pos, bint is_capture = 0, bint is_castle = 0, bint castle_type = 0, bint is_pawn_special = 0, bint is_promotion = 0, unsigned short promotion_type = 0):
        return (starting_pos << 10) + (final_pos << 4) + (is_promotion << 3) + (is_capture << 2) + promotion_type + (is_castle << 1) + castle_type + is_pawn_special

    #TODO: when move_gen is finished convert to a static method to avoid overhead
    @staticmethod
    cdef void print_move(unsigned short move):
        print(str(bin(move))[2:] + "\n" \
        "starting positon = " + str(move >> 10) + "\n" \
        + "ending position = " + str((move % (1 << 10)) >> 4) + "\n" \
        + "flags = " + str(bin(move % (1<< 4)))[2:])

    @staticmethod
    def test():
        move = Move(1, 1, 1, 0, 0, 0, 1, 3)
        print(move)

cdef inline int generate_for_piece(unsigned short[:] move_array, unsigned long long map, unsigned long long occupancy, int starting_pos, int index):
    #generates moves for all pieces except pawns and kings
    cdef int moves_added = 0
    cdef int i
    for i in range(64):
        if map >> i & 1:
            move_array[index + moves_added] = Move.encode_move(starting_pos, i, occupancy >> i & 1)
            moves_added += 1
    return moves_added

cdef void initialize_pinned_pieces(unsigned long long[:] pinned_pieces, Board.Board board, int king_square):
    cdef unsigned long long pin_cands_rook_lines = Maps.get_rook_maps(king_square, 0uLL)
    cdef unsigned long long pin_cands_bishop_lines = Maps.get_bishop_maps(king_square, 0uLL)
    cdef unsigned long long cand
    cdef unsigned long long cand_piece
    cdef int i
    cdef int j = 0
    pin_cands_bishop_lines &= board.bit_boards[ENEMY_BISHOP] | board.bit_boards[ENEMY_QUEEN]
    pin_cands_rook_lines &= board.bit_boards[ENEMY_ROOK] | board.bit_boards[ENEMY_QUEEN]
    for i in range(64):
        cand = 0
        if pin_cands_bishop_lines >> i & 1:
            cand = Maps.get_bishop_maps(i, 0uLL) & Maps.get_bishop_maps(king_square, 0uLL) | (1uLL << i)
            cand_piece = cand & board.get_white_occupancy()
            if cand_piece & (cand_piece - 1) == 0:
                pinned_pieces[j] = cand
                j += 1
        if pin_cands_rook_lines >> i & 1:
            cand = Maps.get_rook_maps(i, 0uLL) & Maps.get_rook_maps(king_square, 0uLL) | (1uLL << i)
            cand_piece = cand & board.get_white_occupancy()
            if cand_piece & (cand_piece - 1) == 0:
                pinned_pieces[j] = cand
                j += 1



def test():
    Maps.setup_vars()
    #board = Board.Board.board_from_fen("1k6/1r6/3B4/8/8/8/8/1Q6 b KQkq - 0 1")
    board_perm = Board.Board.board_from_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1")
    print(board_perm)
    #cdef unsigned short[:] moves = move_gen(board_perm)
    i = 0
    #while moves[i] != 0:
    #    board = Board.Board.board_from_board(board_perm)
    #    board.make_move(moves[i])
    #    Move.print_move(moves[i])
    #    print(board)
    #    i += 1
    perft_check(2, board_perm)
    print(PERFT_CHECK)

#TODO: fix perft testing function figure out the bug that doesnt allow side_to_move to change
cdef void perft_check(int depth, Board.Board board):
    global PERFT_CHECK
    cdef int i = 0
    cdef int sum = 0
    cdef Board.Board board_perm = board
    cdef unsigned short moves[220]
    move_gen(board)
    for i in range(220):
        moves[i] = MOVES[i]
    i = 0
    while (moves[i] != 0) & (depth > 0):
        Move.print_move(moves[i])
        board_temp = Board.Board.board_from_board(board_perm)
        board_temp.make_move(moves[i])
        print(board_temp)
        i += 1
        PERFT_CHECK += 1
        perft_check(depth - 1, board_temp)



cdef void move_gen(Board.Board board):
    setup_pieces(board.side_to_move)
    global MOVES
    #the correct map for every square on the board (if it is of the side that is to move)
    cdef unsigned long long maps[64]
    cdef unsigned long long i
    cdef unsigned long long j
    cdef unsigned long long danger_squares = 0uLL
    #only used when there is a single check
    cdef unsigned long long check_ray = 0
    for i in range(64):
        maps[i] = 0
    cdef int index = 0
    cdef int pin_index = 0
    #for every index i we describe both the piece's location and its map
    cdef unsigned long long occupancy_king
    cdef unsigned long long occupancy = ~board.bit_boards[0]
    cdef unsigned long long checking_bitboard
    cdef int check_flag
    cdef int king_square
    cdef bint double_push

    king_square = misc.log2_pow2(board.bit_boards[KING])
    initialize_pinned_pieces(PINNED_PIECES, board, king_square)
    checking_bitboard = board.checking_bitboard(king_square)
    check_flag = (checking_bitboard != 0) + (checking_bitboard & (checking_bitboard - 1) != 0)

    #calculates all the moves that allow the king to dodge
    occupancy_king = ~(board.bit_boards[0] | board.bit_boards[KING])
    for i in range(64uLL):
        if (board.bit_boards[ENEMY_PAWN] >> i) & 1:
            danger_squares |= Maps.get_pawn_maps(i, ~board.side_to_move)
        if (board.bit_boards[ENEMY_KNIGHT] >> i) & 1:
            danger_squares |= Maps.get_knight_maps(i)
        if (board.bit_boards[ENEMY_BISHOP] >> i) & 1:
            danger_squares |= Maps.get_bishop_maps(i, occupancy_king)
        if (board.bit_boards[ENEMY_ROOK] >> i) & 1:
            danger_squares |= Maps.get_rook_maps(i, occupancy_king)
        if (board.bit_boards[ENEMY_QUEEN] >> i) & 1:
            danger_squares |= Maps.get_queen_maps(i, occupancy_king)
    index += generate_for_piece(MOVES, Maps.get_king_maps(king_square) & ~danger_squares & ~occupancy, occupancy, king_square, index)

    #generates all maps for each piece
    if check_flag != 2:
        for i in range(64uLL):
            if (board.bit_boards[PAWN] >> i) & 1:
                double_push = (((i >> 3 == 1) & ~board.side_to_move) | ((i >> 3 == 6) & board.side_to_move)) & (board.bit_boards[0] >> (i + 8uLL - (16uLL * board.side_to_move)) & 1uLL)
                maps[i] = ((board.bit_boards[0] >> (i + 8uLL - (16uLL * board.side_to_move)) & 1uLL) << (i + 8uLL - (16uLL * board.side_to_move))) | \
                (((board.bit_boards[0] >> (i + 16uLL - (32uLL * board.side_to_move)) & 1uLL) << (i + 16uLL - (32uLL * board.side_to_move))) * double_push)

            if (board.bit_boards[KNIGHT] >> i) & 1:
                maps[i] = Maps.get_knight_maps(i) & ~board.get_occupancy_side()

            if (board.bit_boards[BISHOP] >> i) & 1:
                maps[i] = Maps.get_bishop_maps(i, occupancy) & ~board.get_occupancy_side()

            if (board.bit_boards[ROOK] >> i) & 1:
                maps[i] = Maps.get_rook_maps(i, occupancy) & ~board.get_occupancy_side()

            if (board.bit_boards[QUEEN] >> i) & 1:
                maps[i] = Maps.get_queen_maps(i, occupancy) & ~board.get_occupancy_side()
        for i in range(64):
            for j in range(8):
                if PINNED_PIECES[j] >> i & 1:
                    maps[i] &= PINNED_PIECES[j]


    #calculates all "blocking" moves
    if check_flag == 1:
        for i in range(64uLL):
            if (checking_bitboard >> i) & 1:
                check_ray |= 1uLL << i
                if (board.bit_boards[ENEMY_ROOK] >> i & 1) | (board.bit_boards[ENEMY_QUEEN] >> i & 1):
                    check_ray |= Maps.get_rook_maps(king_square, occupancy) & Maps.get_rook_maps(i, occupancy)
                if (board.bit_boards[ENEMY_BISHOP] >> i & 1) | (board.bit_boards[ENEMY_QUEEN] >> i & 1):
                    check_ray |= Maps.get_bishop_maps(king_square, occupancy) & Maps.get_bishop_maps(i, occupancy)
        for i in range(64):
            maps[i] &= check_ray
    for i in range(64):
        #if maps[i] != 0:
        #   print(i%8, i//8)
        #   Board.BitBoard.print_bit_board(maps[i])
        index += generate_for_piece(MOVES, maps[i], occupancy, i, index)
    MOVES[index + 1] = 0



cdef void setup_pieces(bint side_to_move):
    global PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING, ENEMY_PAWN, ENEMY_KNIGHT, ENEMY_BISHOP, ENEMY_ROOK, ENEMY_QUEEN, ENEMY_KING
    if side_to_move:
        PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING  = 7, 8, 9, 10, 11, 12
        ENEMY_PAWN, ENEMY_KNIGHT, ENEMY_BISHOP, ENEMY_ROOK, ENEMY_QUEEN, ENEMY_KING = 1, 2, 3, 4, 5, 6
    else:
        PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING = 1, 2, 3, 4, 5, 6
        ENEMY_PAWN, ENEMY_KNIGHT, ENEMY_BISHOP, ENEMY_ROOK, ENEMY_QUEEN, ENEMY_KING = 7, 8, 9, 10, 11, 12
