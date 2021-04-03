from Move_Gen import Move
from Board import BitBoard
from Board import Board
import timeit
ascii_board = "rnbqkbnrpppppppp................................PPPPPPPPRNBQKBNR"

board = Board("r3kbnr/pppppppp/8/8/8/8/PPPPPPPP/R3KBNR b KQkq - 0 1")
move = Move(4, 2, 0, 1, 1, 0)
print(move)
board.make_move(move)
print(board)
