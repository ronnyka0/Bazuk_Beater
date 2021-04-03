#cython: language_level=3
cdef class Move:
#holds all critical information for a given move
    #a move is a 16 bit short interger
    #first 6 bits describe the starting position and the next 6 describe the ending position while the last 4 are flags
    #the flags are as follows: promotion flag, capture flag, special 1, special 2

    def __cinit__(self, unsigned short starting_pos, unsigned short final_pos, bint is_capture = 0, bint is_castle = 0, bint castle_type = 0, bint is_pawn_special = 0, bint is_promotion = 0, unsigned short promotion_type = 0):
        self.move = (starting_pos << 10) + (final_pos << 4) + (is_promotion << 3) + (is_capture << 2) + promotion_type + (is_castle << 1) + castle_type + is_pawn_special


    def __str__(self):
        return str(bin(self.move))[2:] + "\n" \
        "starting positon = " + str(self.move >> 10) + "\n" \
        + "ending position = " + str((self.move % (1 << 10)) >> 4) + "\n" \
        + "flags = " + str(bin(self.move % (1<< 4)))[2:]

    @staticmethod
    def test():
        move = Move(1, 1, 1, 0, 0, 0, 1, 3)
        print(move)