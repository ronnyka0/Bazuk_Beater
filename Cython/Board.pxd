#cython: language_level=3
cdef class BitBoard:
    cdef bint side_to_move
    cdef unsigned long long bit_boards[13]
    cdef bint castle_rights[4]
    cdef unsigned short enpessant
    cdef int half_move_counter
    cdef int full_move_counter


    @staticmethod
    cdef inline unsigned long long write_bit(int, int)

    @staticmethod
    cdef inline bint read_bit(int, int, unsigned long long)

    @staticmethod
    cdef void print_bit_board(unsigned long long)
