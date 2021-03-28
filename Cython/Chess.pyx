#cython: language_level=3
from cython.parallel import prange
import numpy as np
cimport numpy as np

cdef dict PIECES = {".": 0, "p": 1, "n": 2, "b": 3, "r": 4, "q": 5, "k": 6, "P": 7, "N": 8, "B": 9, "R": 10, "Q": 11, "K": 12}
cdef dict PIECES_REV = {value: key for (key, value) in PIECES.items()}
cdef str DEFAULT_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
cdef unsigned long long ROOK_MAPS[64][4096]
cdef unsigned long long BISHOP_MAPS[64][512]
cdef unsigned long long KNIGHT_MAPS[64]
cdef unsigned long long KING_MAPS[64]
cdef unsigned long long WHITE_PAWN_MAPS[64]
cdef unsigned long long BLACK_PAWN_MAPS[64]
cdef unsigned long long rook_magics[64]
rook_magics[:] = [9979994641325359136uLL,
90072129987412032uLL,
180170925814149121uLL,
72066458867205152uLL,
144117387368072224uLL,
216203568472981512uLL,
9547631759814820096uLL,
2341881152152807680uLL,
140740040605696uLL,
2316046545841029184uLL,
72198468973629440uLL,
81205565149155328uLL,
146508277415412736uLL,
703833479054336uLL,
2450098939073003648uLL,
576742228899270912uLL,
36033470048378880uLL,
72198881818984448uLL,
1301692025185255936uLL,
90217678106527746uLL,
324684134750365696uLL,
9265030608319430912uLL,
4616194016369772546uLL,
2199165886724uLL,
72127964931719168uLL,
2323857549994496000uLL,
9323886521876609uLL,
9024793588793472uLL,
562992905192464uLL,
2201179128832uLL,
36038160048718082uLL,
36029097666947201uLL,
4629700967774814240uLL,
306244980821723137uLL,
1161084564161792uLL,
110340390163316992uLL,
5770254227613696uLL,
2341876206435041792uLL,
82199497949581313uLL,
144120019947619460uLL,
324329544062894112uLL,
1152994210081882112uLL,
13545987550281792uLL,
17592739758089uLL,
2306414759556218884uLL,
144678687852232706uLL,
9009398345171200uLL,
2326183975409811457uLL,
72339215047754240uLL,
18155273440989312uLL,
4613959945983951104uLL,
145812974690501120uLL,
281543763820800uLL,
147495088967385216uLL,
2969386217113789440uLL,
19215066297569792uLL,
180144054896435457uLL,
2377928092116066437uLL,
9277424307650174977uLL,
4621827982418248737uLL,
563158798583922uLL,
5066618438763522uLL,
144221860300195844uLL,
281752018887682uLL]
cdef unsigned long long bishop_magics[64]
bishop_magics[:] = [18018832060792964uLL,
9011737055478280uLL,
4531088509108738uLL,
74316026439016464uLL,
396616115700105744uLL,
2382975967281807376uLL,
1189093273034424848uLL,
270357282336932352uLL,
1131414716417028uLL,
2267763835016uLL,
2652629010991292674uLL,
283717117543424uLL,
4411067728898uLL,
1127068172552192uLL,
288591295206670341uLL,
576743344005317120uLL,
18016669532684544uLL,
289358613125825024uLL,
580966009790284034uLL,
1126071732805635uLL,
37440604846162944uLL,
9295714164029260800uLL,
4098996805584896uLL,
9223937205167456514uLL,
153157607757513217uLL,
2310364244010471938uLL,
95143507244753921uLL,
9015995381846288uLL,
4611967562677239808uLL,
9223442680644702210uLL,
64176571732267010uLL,
7881574242656384uLL,
9224533161443066400uLL,
9521190163130089986uLL,
2305913523989908488uLL,
9675423050623352960uLL,
9223945990515460104uLL,
2310346920227311616uLL,
7075155703941370880uLL,
4755955152091910658uLL,
146675410564812800uLL,
4612821438196357120uLL,
4789475436135424uLL,
1747403296580175872uLL,
40541197101432897uLL,
144397831292092673uLL,
1883076424731259008uLL,
9228440811230794258uLL,
360435373754810368uLL,
108227545293391872uLL,
4611688277597225028uLL,
3458764677302190090uLL,
577063357723574274uLL,
9165942875553793uLL,
6522483364660839184uLL,
1127033795058692uLL,
2815853729948160uLL,
317861208064uLL,
5765171576804257832uLL,
9241386607448426752uLL,
11258999336993284uLL,
432345702206341696uLL,
9878791228517523968uLL,
4616190786973859872uLL]
cdef int rook_relevant_bits[64]
rook_relevant_bits[:] = [
12, 11, 11, 11, 11, 11, 11, 12,
11, 10, 10, 10, 10, 10, 10, 11,
11, 10, 10, 10, 10, 10, 10, 11,
11, 10, 10, 10, 10, 10, 10, 11,
11, 10, 10, 10, 10, 10, 10, 11,
11, 10, 10, 10, 10, 10, 10, 11,
11, 10, 10, 10, 10, 10, 10, 11,
12, 11, 11, 11, 11, 11, 11, 12
]
cdef unsigned long long ROOK_MASKS[64]

cdef int bishop_relevant_bits[64]
bishop_relevant_bits[:] = [
6, 5, 5, 5, 5, 5, 5, 6,
5, 5, 5, 5, 5, 5, 5, 5,
5, 5, 7, 7, 7, 7, 5, 5,
5, 5, 7, 9, 9, 7, 5, 5,
5, 5, 7, 9, 9, 7, 5, 5,
5, 5, 7, 7, 7, 7, 5, 5,
5, 5, 5, 5, 5, 5, 5, 5,
6, 5, 5, 5, 5, 5, 5, 6
]
cdef unsigned long long BISHOP_MASKS[64]




cdef class BitBoard:
#holds all critical information of the board
#side_to_move True if white is to move False if black is to move
#bit_board a memory efficient method of storing positional information of the board
#castle_rights a array of bools describing whether each side has castling rights or not
#enpessant a 16 bit unsigned short representing enpessant rights
#counts the half moves relevant for the 50-move draw (which is if 50 moves occur without a pawn move or capture

    cdef bint side_to_move
    cdef unsigned long long bit_boards[13]
    cdef bint castle_rights[4]
    cdef unsigned short enpessant
    cdef int half_move_counter
    cdef int full_move_counter


    def __init__(self, str FEN_str = DEFAULT_FEN):
        board = FEN_str.split(' ')
        self.parse_board(board[0])
        self.side_to_move = 1 if board[1] == 'w' else 0
        self.castle_rights[:] = ["K" in board[2], "Q" in board[2], "k" in board[2], "q" in board[2]]
        self.parse_enpessant()



    def parse_board(self, str board_fen):
        #given the positional knowledge of fen converts it into a bitboard
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


    def __str__(self):
        board = ""
        bit_boards = self.bit_boards
        cdef unsigned long long val
        for i in range(8):
            for j in range(8):
                for p in range (13):
                    val = bit_boards[p]
                    if BitBoard.read_bit(j + 1, i + 1, val):
                        board += PIECES_REV[p] + str(i) + ", " + str(j) + " "
            board += "\n"
        return board


    cdef inline void make_move(self, unsigned long long prev_location, unsigned long long next_location, int piece):
        #assumes all inputs are valid in relation to the board
        cdef int i = 0
        self.side_to_move = ~self.side_to_move
        for i in range(1,13):
            self.bit_boards[i] &= ~prev_location
        self.bit_boards[0] |= prev_location
        self.bit_boards[piece] |= next_location
        self.bit_boards[0] &= ~next_location



    @staticmethod
    cdef inline bint read_bit(int file, int rank, unsigned long long board):
        #returns a bit at a given square of a given board
        return board >> ((rank-1) * 8 + file - 1) & 1uLL


    @staticmethod
    cdef inline unsigned long long write_bit(int file, int rank):
        #returns a board with a bit lit on the location given (mainly used with |= statements)
        if file >= 1 and file <=8 and rank >= 1 and rank <= 8:
            return 1 << ((rank - 1) * 8 + file - 1)
        return 0


    @staticmethod
    cdef inline unsigned long long get_rook_attacks(int index, unsigned long long occupancy) nogil:
        occupancy &= ROOK_MASKS[index]
        occupancy *= rook_magics[index]
        occupancy >>= 64 - rook_relevant_bits[index]
        return ROOK_MAPS[index][occupancy]


    @staticmethod
    cdef inline unsigned long long get_bishop_attacks(int index, unsigned long long occupancy) nogil:
        occupancy &= BISHOP_MASKS[index]
        occupancy *= bishop_magics[index]
        occupancy >>= 64 - bishop_relevant_bits[index]
        return BISHOP_MAPS[index][occupancy]


    @staticmethod
    cdef inline unsigned long long get_queen_attacks(int index, unsigned long long occupancy) nogil:
        return BitBoard.get_bishop_attacks(index, occupancy) | BitBoard.get_rook_attacks(index, occupancy)


    @staticmethod
    cdef inline unsigned long long get_knight_attacks(int index) nogil:
        return KNIGHT_MAPS[index]


    @staticmethod
    cdef inline unsigned long long get_king_attacks(int index) nogil:
        return KING_MAPS[index]


    @staticmethod
    cdef inline unsigned long long get_pawn_attacks(int index, bint side) nogil:
        if side:
            return WHITE_PAWN_MAPS[index]
        else:
            return BLACK_PAWN_MAPS[index]


    @staticmethod
    def print_bit_board(unsigned long long bit_board):
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


    @staticmethod
    cdef unsigned long long modify_mask(unsigned long long mask, int p):
        #a mask is a bitboard in which only the relevant occopancy bits of a certain pi ece in a certain location are lit
        #takes a mask and a integer and returns a variation of the mask according to that integer
        cdef int k
        cdef int m
        cdef unsigned long long modified_mask = 0
        for k in range(8):
            for m in range(8):
                if BitBoard.read_bit(m + 1, k + 1, mask):
                    if p & 1:
                        modified_mask |= BitBoard.write_bit(m + 1, k + 1)
                    p = p >> 1
        return modified_mask

    #===========================
    #rook maps related functions
    #===========================

    @staticmethod
    cdef void setup_rook_attacks():
        #fills up ROOK_MAPS which is the final product of all rook setup functions and the array used in calculations
        cdef unsigned long long relevant_bit_board
        cdef unsigned long long cur_occupancy
        cdef int i
        cdef int j
        cdef int k
        cdef int m
        cdef int p
        cdef int cur_p
        for i in range(8):
            for j in range(8):
                relevant_bit_board = ROOK_MASKS[i * 8 + j]
                relevant_bits = rook_relevant_bits[i * 8 + j]
                for p in range(2 ** relevant_bits):
                    cur_p = p
                    cur_occupancy = BitBoard.modify_mask(relevant_bit_board, p)
                    magic_index = cur_occupancy * rook_magics[i * 8 + j] >> 64 - relevant_bits
                    ROOK_MAPS[i * 8 + j][magic_index] = BitBoard.calculate_rook_attacks_on_the_fly(j + 1, i + 1, cur_occupancy)
                    if BitBoard.read_bit(j + 1, i + 1, cur_occupancy):
                        ROOK_MAPS[i * 8 + j][magic_index] = 0


    @staticmethod
    cdef void setup_rook_masks():
        #fills an array of rook masks with the appropriate mask given to each sqaure
        cdef int i
        cdef int j
        cdef unsigned long long rook_attacks
        for rank in range(8):
            for file in range(8):
                rook_attacks = 0uLL
                #calculates file mask
                for i in range(6):
                    rook_attacks |= BitBoard.write_bit(i + 2, rank + 1)
                #calculates rank mask
                for i in range(6):
                    rook_attacks |= BitBoard.write_bit(file + 1, i + 2)
                rook_attacks = rook_attacks ^ (BitBoard.write_bit(file + 1, rank + 1) * BitBoard.read_bit(file + 1, rank + 1, rook_attacks))
                ROOK_MASKS[rank * 8 + file] = rook_attacks



    @staticmethod
    cdef unsigned long long calculate_rook_attacks_on_the_fly(int rf, int rr, unsigned long long board_occupied):
    #calculates rook attacks naively
        cdef unsigned long long rook_attacks = 0
        cdef int i = rr
        cdef int j = rf
        #calculates down
        while i > 1 and not BitBoard.read_bit(rf, i, board_occupied):
            i -= 1
            rook_attacks |= BitBoard.write_bit(rf, i)
        i = rr
        #calculates up
        while i < 8 and not BitBoard.read_bit(rf, i, board_occupied):
            i += 1
            rook_attacks |= BitBoard.write_bit(rf, i)
        # calculates right
        while j < 8 and not BitBoard.read_bit(j, rr, board_occupied):
            j += 1
            rook_attacks |= BitBoard.write_bit(j, rr)
        # calculates left
        j = rf
        while j > 1 and not BitBoard.read_bit(j, rr, board_occupied):
            j -= 1
            rook_attacks |= BitBoard.write_bit(j, rr)
        return rook_attacks

    #==============================
    #bishop masks related functions
    #==============================

    @staticmethod
    cdef void setup_bishop_attacks():
        #fills up BISHOP_MAPS which is the final product of all bishop setup functions and the array used in calculations
        cdef unsigned long long relevant_bit_board
        cdef unsigned long long cur_occupancy
        cdef int i
        cdef int j
        cdef int k
        cdef int m
        cdef int p
        cdef int cur_p
        for i in range(8):
            for j in range(8):
                relevant_bit_board = BISHOP_MASKS[i * 8 + j]
                relevant_bits = bishop_relevant_bits[i * 8 + j]
                for p in range(2 ** relevant_bits):
                    cur_p = p
                    cur_occupancy = BitBoard.modify_mask(relevant_bit_board, p)
                    magic_index = cur_occupancy * bishop_magics[i * 8 + j] >> 64 - relevant_bits
                    BISHOP_MAPS[i * 8 + j][magic_index] = BitBoard.calculate_bishop_attacks_on_the_fly(j + 1, i + 1, cur_occupancy)


    @staticmethod
    cdef void setup_bishop_masks():
        cdef unsigned long long frame = 0
        for i in range(6):
            for j in range(6):
                frame |= BitBoard.write_bit(i + 2, j + 2)
        for i in range(8):
            for j in range(8):
                BISHOP_MASKS[i * 8 + j] = BitBoard.calculate_bishop_attacks_on_the_fly(j + 1, i + 1, 0) & frame


    @staticmethod
    cdef calculate_bishop_attacks_on_the_fly(int bf, int br, unsigned long long board_occupied):
        cdef int i = br
        cdef int j = bf
        cdef unsigned long long bishop_attacks = 0
        #up right
        while i < 8 and j < 8 and not BitBoard.read_bit(j, i, board_occupied):
            i += 1
            j += 1
            bishop_attacks |= BitBoard.write_bit(j, i)
        i = br
        j = bf
        #bottom right
        while i > 1 and j < 8 and not BitBoard.read_bit(j, i, board_occupied):
            i -= 1
            j += 1
            bishop_attacks |= BitBoard.write_bit(j, i)
        i = br
        j = bf
        #top left
        while i < 8 and j > 1 and not BitBoard.read_bit(j, i, board_occupied):
            i += 1
            j -= 1
            bishop_attacks |= BitBoard.write_bit(j, i)
        i = br
        j = bf
        #bottom left
        while i > 1 and j > 1 and not BitBoard.read_bit(j, i, board_occupied):
            i -= 1
            j -= 1
            bishop_attacks |= BitBoard.write_bit(j, i)
        return bishop_attacks

    #=============================
    #knight maps related functions
    #=============================

    @staticmethod
    cdef void setup_knight_attacks():
    #sets up an array of appropriate bitboards according to knight position (knight attack maps are independent on the rest of the board)
        cdef int i
        cdef int j
        for i in range(8):
            for j in range(8):
                KNIGHT_MAPS[i * 8 + j] = BitBoard.calculate_knight_attacks_on_the_fly(i + 1, j + 1)


    @staticmethod
    cdef unsigned long long calculate_knight_attacks_on_the_fly(int kf, int kr):
    #calculates the attack map of a knight
        cdef unsigned long long knight_attacks = 0
        if kr - 2 >= 1:
            if kf - 1 >= 1:
                knight_attacks |= BitBoard.BitBoard.write_bit(kf - 1, kr - 2)
            if kf + 1 <= 8:
                knight_attacks |= BitBoard.BitBoard.write_bit(kf + 1, kr - 2)
        if kr + 2 <= 8:
            if kf - 1 >= 1:
                knight_attacks |= BitBoard.BitBoard.write_bit(kf - 1, kr + 2)
            if kf + 1 <= 8:
                knight_attacks |= BitBoard.BitBoard.write_bit(kf + 1, kr + 2)
        if kf - 2 >= 1:
            if kr - 1 >= 1:
                knight_attacks |= BitBoard.BitBoard.write_bit(kf - 2, kr - 1)
            if kr + 1 <= 8:
                knight_attacks |= BitBoard.BitBoard.write_bit(kf - 2, kr + 1)
        if kf + 2 <= 8:
            if kr - 1 >= 1:
                knight_attacks |= BitBoard.BitBoard.write_bit(kf + 2, kr - 1)
            if kr + 1 <= 8:
                knight_attacks |= BitBoard.BitBoard.write_bit(kf + 2, kr + 1)
        return knight_attacks

    #===========================
    #king maps related functions
    #===========================

    @staticmethod
    cdef void setup_king_attacks():
    #setup an array of king attack boards based on position
        cdef int i
        cdef int j
        for i in range(8):
            for j in range(8):
                KING_MAPS[i * 8 + j] = BitBoard.calculate_king_attacks_on_the_fly(i + 1, j + 1)


    @staticmethod
    cdef unsigned long long calculate_king_attacks_on_the_fly(int i, int j):
    #calculates king attack maps on the fly
        return BitBoard.write_bit(i + 1, j + 1) | BitBoard.write_bit(i + 1, j) | BitBoard.write_bit(i + 1, j - 1) | BitBoard.write_bit(i, j + 1) | BitBoard.write_bit(i, j - 1) | BitBoard.write_bit(i -1, j + 1) | BitBoard.write_bit(i - 1, j) | BitBoard.write_bit(i - 1, j - 1)

    #===========================
    #pawn maps related functions
    #===========================

    @staticmethod
    cdef void setup_pawn_attacks():
        #setup an array of pawn attacks based on position
        cdef int i
        cdef int j
        for i in range(8):
            for j in range(8):
                WHITE_PAWN_MAPS[i * 8 + j] = BitBoard.calculate_pawn_attacks_on_the_fly(i + 1, j + 1, 1)
                BLACK_PAWN_MAPS[i * 8 + j] = BitBoard.calculate_pawn_attacks_on_the_fly(i + 1, j + 1, 0)


    @staticmethod
    cdef unsigned long long calculate_pawn_attacks_on_the_fly(int i, int j, bint side):
        #calculates pawn attacks on the fly
        #side is 1 if white 0 if black
        if side:
            return BitBoard.write_bit(i - 1, j + 1) | BitBoard.write_bit(i - 1, j - 1)
        else:
            return BitBoard.write_bit(i + 1, j + 1) | BitBoard.write_bit(i + 1, j - 1)


    @staticmethod
    cdef setup_vars():
        #sets all the global variables needed for fast attack/defend map calculations
        BitBoard.setup_rook_masks()
        BitBoard.setup_bishop_masks()
        BitBoard.setup_rook_attacks()
        BitBoard.setup_bishop_attacks()
        BitBoard.setup_knight_attacks()
        BitBoard.setup_king_attacks()


    @staticmethod
    def test():
        board = BitBoard()
        print(board)
        board.make_move(1uLL, 1uLL , 4)
        print(board)


    @staticmethod
    def test1():
        BitBoard.setup_vars()

def generate_legal_moves(bint side):
    pass