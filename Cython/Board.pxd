#cython: language_level=3
cdef class BitBoard:
    @staticmethod
    cdef inline unsigned long long write_bit(int, int)
    @staticmethod
    cdef inline bint read_bit(int, int, unsigned long long)
    @staticmethod
    cdef void print_bit_board(unsigned long long)
