cdef int[67] lookup_table_log2
lookup_table_log2[:] = [0, 0, 1, 39, 2, 15, 40, 23, 3, 12, 16, 59, 41, 19, 24, 54, 4, 0, 13, 10, 17, 62, 60, 28, 42, 30, 20, 51, 25, 44, 55, 47, 5, 32, 0, 38, 14, 22, 11, 58, 18, 53, 63, 9, 61, 27, 29, 50, 43, 46, 31, 37, 21, 57, 52, 8, 26, 49, 45, 36, 56, 7, 48, 35, 6, 34, 33]
cdef int log2_pow2(unsigned long long number):
    #calculates the log2 of a whole power of two with a lookup table
    return lookup_table_log2[number % 67]


