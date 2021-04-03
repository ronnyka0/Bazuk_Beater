#cython: language_level=3
cdef unsigned long long get_king_maps(int) nogil
cdef unsigned long long get_pawn_maps(int, bint) nogil
cdef unsigned long long get_rook_maps(int, unsigned long long) nogil
cdef unsigned long long get_bishop_maps(int, unsigned long long) nogil
cdef unsigned long long get_queen_maps(int, unsigned long long) nogil
cdef unsigned long long get_knight_maps(int) nogil
