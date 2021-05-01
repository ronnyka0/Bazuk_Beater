#cython: language_level=3
import Move_Gen
import Maps
cimport Move_Gen
cimport Maps
cimport misc
cdef dict PIECES = {".": 0, "p": 1, "n": 2, "b": 3, "r": 4, "q": 5, "k": 6, "P": 7, "N": 8, "B": 9, "R": 10, "Q": 11, "K": 12}
cdef dict PIECES_REV = {value: key for (key, value) in PIECES.items()}
cdef str DEFAULT_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

#TODO: replace PIECES dict with enum
#TODO: implement an incrementally updating array of checking pieces and pinned pieces
cdef class Board:
#holds all critical information of the board
#side_to_move True if white is to move False if black is to move
#bit_board a memory efficient method of storing positional information of the board
#castle_rights a array of bools describing whether each side has castling rights or not
#enpessant a 16 bit unsigned short representing enpessant rights where the first 8 bits signify whites side and the rest are black
#counts the half moves relevant for the 50-move draw (which is if 50 moves occur without a pawn move or capture


    def __init__(self):
        pass

    @staticmethod
    cdef Board board_from_board(Board board):
        board_copy = Board()
        board_copy.side_to_move = board.side_to_move
        for i in range(13):
            board_copy.bit_boards[i] = board.bit_boards[i]
        board_copy.castle_rights = board.castle_rights
        board_copy.enpessant = board.enpessant
        board_copy.half_move_counter = board.half_move_counter
        board_copy.full_move_counter = board.full_move_counter
        return board_copy

    @staticmethod
    def board_from_fen(str FEN_str = DEFAULT_FEN):
        #a typical FEN contains all relevant knowledge of the board and is of the form (position) (side to move) (castle rights) (enpessant) (half moves) (full moves)
        board_ret = Board()
        board = FEN_str.split(' ')
        board_ret.parse_board(board[0])
        board_ret.side_to_move = 1 if board[1] == 'w' else 0
        board_ret.castle_rights[:] = ["K" in board[2], "Q" in board[2], "k" in board[2], "q" in board[2]]
        board_ret.parse_enpessant(board[3])
        return board_ret

    def parse_board(self, str board_fen):
        #given the positional knowledge of FEN converts it into a bitboard
        cdef int index = 0
        for i in board_fen:
            if i.isdigit():
                for i in range(int(i)):
                    self.bit_boards[0] |= 1uLL << index
                    index += 1
            elif i == "/":
                pass
            else:
                self.bit_boards[PIECES[i]] |= 1uLL << index
                index += 1

    def parse_enpessant(self, enpassant_string):
        #given the part of the FEN relevant to enpessant captures updates the board appropriately
        if not enpassant_string == "-":
            is_black = (enpassant_string[1] == "6")
            index = ord(enpassant_string[0]) - ord('a') + (8 * is_black)
            self.enpessant |= 1 << index

    cdef unsigned long long get_occupancy_side(self):
        if self.side_to_move:
            return self.get_white_occupancy()
        else:
            return self.get_black_occupancy()

    cdef unsigned long long get_white_occupancy(self):
        return self.bit_boards[7] | self.bit_boards[8] | self.bit_boards[9] | self.bit_boards[10] | self.bit_boards[11] | self.bit_boards[12]

    cdef unsigned long long get_black_occupancy(self):
        return self.bit_boards[1] | self.bit_boards[2] | self.bit_boards[3] | self.bit_boards[4] | self.bit_boards[5] | self.bit_boards[6]

    cpdef void make_move(self, unsigned short move_encoding):
        cdef int starting_pos = (move_encoding >> 10)
        cdef int final_pos = ((move_encoding >> 4) & ((1 << 6) - 1))
        cdef int flags = move_encoding & ((1 << 4) - 1)
        piece = 0
        for i in range(12):
            self.bit_boards[i+1] &= ~(1uLL << final_pos)
            if (self.bit_boards[i+1] >> starting_pos) & 1:
                piece = i + 1
                self.replace_piece(starting_pos, i+1, 0)
        if self.side_to_move:
            if (flags >> 3) & 1:
                self.bit_boards[1 + (move_encoding & ((1 << 4) - 1))]
            if flags == 5:
                self.replace_piece(final_pos + 8, 1, 0)
                self.enpessant = 0
            if flags == 3:
                self.replace_piece(59, 0, 10)
                self.replace_piece(56, 10, 0)
                self.castle_rights[0] = 0
                self.castle_rights[1] = 0
            if flags == 2:
                self.replace_piece(61, 0, 10)
                self.replace_piece(63, 10, 0)
                self.castle_rights[0] = 0
                self.castle_rights[1] = 0

        else:
            if (flags >> 3) & 1:
                self.bit_boards[7 + (move_encoding & ((1 << 4) - 1))]
            if (flags) == 5:
                self.replace_piece(final_pos - 8, 7, 0)
                self.enpessant = 0
            if flags == 3:
                self.replace_piece(6, 0, 4)
                self.replace_piece(0, 4, 0)
                self.castle_rights[2] = 0
                self.castle_rights[3] = 0
            if flags == 2:
                self.replace_piece(3, 0, 4)
                self.replace_piece(7, 4, 0)
                self.castle_rights[2] = 0
                self.castle_rights[3] = 0
        self.replace_piece(final_pos, 0, piece)
        self.side_to_move = ~self.side_to_move


    cdef inline void replace_piece(self, int square, int prev_piece, int next_piece):
        self.bit_boards[prev_piece] &= ~ (1uLL << square)
        self.bit_boards[next_piece] |= 1uLL << square

    cdef inline unsigned long long checking_bitboard(self, int king_square):
    #checks whether the current board state is a check
        cdef unsigned long long occupancy = ~self.bit_boards[0]
        cdef unsigned long long checking_squares = 0
        if self.side_to_move:
        #check if white is in check since u can only be in check if it is your turn
            checking_squares |= Maps.get_pawn_maps(king_square, self.side_to_move) & self.bit_boards[1]
            checking_squares |= Maps.get_knight_maps(king_square) & self.bit_boards[2]
            checking_squares |= Maps.get_bishop_maps(king_square, occupancy) & (self.bit_boards[3] | self.bit_boards[5])
            checking_squares |= Maps.get_rook_maps(king_square, occupancy) & (self.bit_boards[4] | self.bit_boards[5])
        else:
        #same for black
            checking_squares |= Maps.get_pawn_maps(king_square, self.side_to_move) & self.bit_boards[7]
            checking_squares |= Maps.get_knight_maps(king_square) & self.bit_boards[8]
            checking_squares |= Maps.get_bishop_maps(king_square, occupancy) & (self.bit_boards[9] | self.bit_boards[11])
            checking_squares |= Maps.get_rook_maps(king_square, occupancy) & (self.bit_boards[10] | self.bit_boards[11])
        return checking_squares





    #TODO: will be changed after addition of UI to turn the board into an FEN string
    def __str__(self):
        board = ""
        bit_boards = self.bit_boards
        cdef unsigned long long val
        for i in range(8):
            for j in range(8):
                for p in range (13):
                    val = bit_boards[p]
                    if BitBoard.read_bit(j + 1, i + 1, val):
                        board += PIECES_REV[p] + " "
            board += "\n"
        return board


cdef class BitBoard:
#functions relevant to the manipulations of BitBoards


    @staticmethod
    cdef inline bint read_bit(int file, int rank, unsigned long long board):
        #returns a bit at a given square of a given board
        return board >> ((rank-1) * 8 + file - 1) & 1uLL


    @staticmethod
    cdef inline unsigned long long write_bit(int file, int rank):
        #returns a board with a bit lit on the location given (mainly used with |= statements)
        if file >= 1 and file <=8 and rank >= 1 and rank <= 8:
            return 1uLL << ((rank - 1) * 8 + file - 1)
        return 0


    #mostly used for testing purposes
    @staticmethod
    cdef void print_bit_board(unsigned long long bit_board):
        #prints a given bitboard
        cdef str r
        cdef int i
        cdef int j
        for i in range(8):
            r = ""
            for j in range(8):
                if (bit_board >> i * 8  + j) & 1uLL:
                    r += "1 "
                else:
                    r += "0 "
            print(r)
