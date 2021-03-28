#cython: language_level=3
from Board cimport BitBoard


cdef bint _INITED = False
#maps
cdef unsigned long long ROOK_MAPS[64][4096]
cdef unsigned long long BISHOP_MAPS[64][512]
cdef unsigned long long KNIGHT_MAPS[64]
cdef unsigned long long KING_MAPS[64]
cdef unsigned long long WHITE_PAWN_MAPS[64]
cdef unsigned long long BLACK_PAWN_MAPS[64]
#magic bit related constants
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
cdef int ROOK_RELEVANT_BITS[64]
ROOK_RELEVANT_BITS[:] = [
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

cdef int BISHOP_RELEVANT_BITS[64]
BISHOP_RELEVANT_BITS[:] = [
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


#============================================================================
#get functions for the maps that work efficiently using the magic bits method
#============================================================================


cdef inline unsigned long long get_rook_maps(int index, unsigned long long occupancy) nogil:
    occupancy &= ROOK_MASKS[index]
    occupancy *= rook_magics[index]
    occupancy >>= 64 - ROOK_RELEVANT_BITS[index]
    return ROOK_MAPS[index][occupancy]


cdef inline unsigned long long get_bishop_maps(int index, unsigned long long occupancy) nogil:
    occupancy &= BISHOP_MASKS[index]
    occupancy *= bishop_magics[index]
    occupancy >>= 64 - BISHOP_RELEVANT_BITS[index]
    return BISHOP_MAPS[index][occupancy]


cdef inline unsigned long long get_queen_maps(int index, unsigned long long occupancy) nogil:
    return get_bishop_maps(index, occupancy) | get_rook_maps(index, occupancy)


cdef inline unsigned long long get_knight_maps(int index) nogil:
    return KNIGHT_MAPS[index]


cdef inline unsigned long long get_king_maps(int index) nogil:
    return KING_MAPS[index]


cdef inline unsigned long long get_pawn_maps(int index, bint side) nogil:
    if side:
        return WHITE_PAWN_MAPS[index]
    else:
        return BLACK_PAWN_MAPS[index]


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
            relevant_bits = ROOK_RELEVANT_BITS[i * 8 + j]
            for p in range(2 ** relevant_bits):
                cur_p = p
                cur_occupancy = modify_mask(relevant_bit_board, p)
                magic_index = cur_occupancy * rook_magics[i * 8 + j] >> 64 - relevant_bits
                ROOK_MAPS[i * 8 + j][magic_index] = calculate_rook_attacks_on_the_fly(j + 1, i + 1, cur_occupancy)
                if BitBoard.read_bit(j + 1, i + 1, cur_occupancy):
                    ROOK_MAPS[i * 8 + j][magic_index] = 0


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
            relevant_bits = BISHOP_RELEVANT_BITS[i * 8 + j]
            for p in range(2 ** relevant_bits):
                cur_p = p
                cur_occupancy = modify_mask(relevant_bit_board, p)
                magic_index = cur_occupancy * bishop_magics[i * 8 + j] >> 64 - relevant_bits
                BISHOP_MAPS[i * 8 + j][magic_index] = calculate_bishop_attacks_on_the_fly(j + 1, i + 1, cur_occupancy)


cdef void setup_bishop_masks():
    cdef unsigned long long frame = 0
    for i in range(6):
        for j in range(6):
            frame |= BitBoard.write_bit(i + 2, j + 2)
    for i in range(8):
        for j in range(8):
            BISHOP_MASKS[i * 8 + j] = calculate_bishop_attacks_on_the_fly(j + 1, i + 1, 0) & frame


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

cdef void setup_knight_attacks():
#sets up an array of appropriate bitboards according to knight position (knight attack maps are independent on the rest of the board)
    cdef int i
    cdef int j
    for i in range(8):
        for j in range(8):
            KNIGHT_MAPS[i * 8 + j] = calculate_knight_attacks_on_the_fly(i + 1, j + 1)


cdef unsigned long long calculate_knight_attacks_on_the_fly(int kf, int kr):
#calculates the attack map of a knight
    cdef unsigned long long knight_attacks = 0
    if kr - 2 >= 1:
        if kf - 1 >= 1:
            knight_attacks |= BitBoard.write_bit(kf - 1, kr - 2)
        if kf + 1 <= 8:
            knight_attacks |= BitBoard.write_bit(kf + 1, kr - 2)
    if kr + 2 <= 8:
        if kf - 1 >= 1:
            knight_attacks |= BitBoard.write_bit(kf - 1, kr + 2)
        if kf + 1 <= 8:
            knight_attacks |= BitBoard.write_bit(kf + 1, kr + 2)
    if kf - 2 >= 1:
        if kr - 1 >= 1:
            knight_attacks |= BitBoard.write_bit(kf - 2, kr - 1)
        if kr + 1 <= 8:
            knight_attacks |= BitBoard.write_bit(kf - 2, kr + 1)
    if kf + 2 <= 8:
        if kr - 1 >= 1:
            knight_attacks |= BitBoard.write_bit(kf + 2, kr - 1)
        if kr + 1 <= 8:
            knight_attacks |= BitBoard.write_bit(kf + 2, kr + 1)
    return knight_attacks

#===========================
#king maps related functions
#===========================


cdef void setup_king_attacks():
#setup an array of king attack boards based on position
    cdef int i
    cdef int j
    for i in range(8):
        for j in range(8):
            KING_MAPS[i * 8 + j] = calculate_king_attacks_on_the_fly(i + 1, j + 1)


cdef unsigned long long calculate_king_attacks_on_the_fly(int i, int j):
#calculates king attack maps on the fly
    return BitBoard.write_bit(i + 1, j + 1) | BitBoard.write_bit(i + 1, j) | BitBoard.write_bit(i + 1, j - 1) | BitBoard.write_bit(i, j + 1) | BitBoard.write_bit(i, j - 1) | BitBoard.write_bit(i -1, j + 1) | BitBoard.write_bit(i - 1, j) | BitBoard.write_bit(i - 1, j - 1)

#===========================
#pawn maps related functions
#===========================

cdef void setup_pawn_attacks():
    #setup an array of pawn attacks based on position
    cdef int i
    cdef int j
    for i in range(8):
        for j in range(8):
            WHITE_PAWN_MAPS[i * 8 + j] = calculate_pawn_attacks_on_the_fly(i + 1, j + 1, 1)
            BLACK_PAWN_MAPS[i * 8 + j] = calculate_pawn_attacks_on_the_fly(i + 1, j + 1, 0)


cdef unsigned long long calculate_pawn_attacks_on_the_fly(int i, int j, bint side):
    #calculates pawn attacks on the fly
    #side is 1 if white 0 if black
    if side:
        return BitBoard.write_bit(i - 1, j + 1) | BitBoard.write_bit(i - 1, j - 1)
    else:
        return BitBoard.write_bit(i + 1, j + 1) | BitBoard.write_bit(i + 1, j - 1)


cdef void setup_vars():
    #sets all the global variables needed for fast attack/defend map calculations
    global _INITED
    if not _INITED:
        setup_rook_masks()
        setup_bishop_masks()
        setup_rook_attacks()
        setup_bishop_attacks()
        setup_knight_attacks()
        setup_king_attacks()
    _INITED = True

