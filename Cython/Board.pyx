#cython: language_level=3
import Move_Gen
cimport Move_Gen
cdef dict PIECES = {".": 0, "p": 1, "n": 2, "b": 3, "r": 4, "q": 5, "k": 6, "P": 7, "N": 8, "B": 9, "R": 10, "Q": 11, "K": 12}
cdef dict PIECES_REV = {value: key for (key, value) in PIECES.items()}
cdef str DEFAULT_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

#TODO: implement an incrementally updating array of checking pieces and pinned pieces
cdef class Board:
#holds all critical information of the board
#side_to_move True if white is to move False if black is to move
#bit_board a memory efficient method of storing positional information of the board
#castle_rights a array of bools describing whether each side has castling rights or not
#enpessant a 16 bit unsigned short representing enpessant rights where the first 8 bits signify whites side and the rest are black
#counts the half moves relevant for the 50-move draw (which is if 50 moves occur without a pawn move or capture

    cdef bint side_to_move
    cdef unsigned long long bit_boards[13]
    cdef bint castle_rights[4]
    cdef unsigned short enpessant
    cdef int half_move_counter
    cdef int full_move_counter


    def __init__(self, str FEN_str = DEFAULT_FEN):
        #a typical FEN contains all relevant knowledge of the board and is of the form (position) (side to move) (castle rights) (enpessant) (half moves) (full moves)
        board = FEN_str.split(' ')
        self.parse_board(board[0])
        self.side_to_move = 1 if board[1] == 'w' else 0
        self.castle_rights[:] = ["K" in board[2], "Q" in board[2], "k" in board[2], "q" in board[2]]
        self.parse_enpessant(board[3])


    cdef void parse_board(self, str board_fen):
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

    cdef void parse_enpessant(self, enpassant_string):
        #given the part of the FEN relevant to enpessant captures updates the board appropriately
        if not enpassant_string == "-":
            is_black = (enpassant_string[1] == "6")
            index = ord(enpassant_string[0]) - ord('a') + (8 * is_black)
            self.enpessant |= 1 << index


    cpdef void make_move(self, Move_Gen.Move move):
        move_encoding = move.move
        starting_pos = (move_encoding >> 10)
        final_pos = ((move_encoding >> 4) & ((1 << 7) - 1))
        flags = move_encoding & ((1 << 4) - 1)
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

        else:
            if (flags >> 3) & 1:
                self.bit_boards[7 + (move_encoding & ((1 << 4) - 1))]
            if (flags) == 5:
                self.replace_piece(final_pos - 8, 7, 0)
            if flags == 3:
                self.replace_piece(3, 0, 4)
                self.replace_piece(0, 4, 0)
                self.castle_rights[2] = 0
                self.castle_rights[3] = 0
        self.replace_piece(final_pos, 0, piece)


    cdef inline replace_piece(self, int square, int prev_piece, int next_piece):
        self.bit_boards[prev_piece] &= ~ (1uLL << square)
        self.bit_boards[next_piece] |= 1uLL << square


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
                if (bit_board >> (7 - i) * 8  + j) & 1uLL:
                    r += "1 "
                else:
                    r += "0 "
            print(r)
