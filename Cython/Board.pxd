#cython: language_level=3

cimport Move_Gen

cdef class Board:
    cdef bint side_to_move
    cdef unsigned long long bit_boards[13]
    cdef bint castle_rights[4]
    cdef unsigned short enpessant
    cdef int half_move_counter
    cdef int full_move_counter

    @staticmethod
    cdef Board board_from_board(Board)

    cpdef void make_move(self, unsigned short)

    cdef void replace_piece(self, int, int, int)

    cdef unsigned long long checking_bitboard(self, int)

    cdef unsigned long long get_occupancy_side(self)

    cdef unsigned long long get_white_occupancy(self)

    cdef unsigned long long get_black_occupancy(self)


cdef class BitBoard:

    @staticmethod
    cdef inline unsigned long long write_bit(int, int)

    @staticmethod
    cdef inline bint read_bit(int, int, unsigned long long)

    @staticmethod
    cdef void print_bit_board(unsigned long long)
