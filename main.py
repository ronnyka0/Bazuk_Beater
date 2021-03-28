NOTATION_FIXER = {"a": 1, "b": 2, "c": 3, "d": 3, "e": 5, "f": 6, "g": 7, "h": 8}
PIECE_VALUES = {"P": 100, "p": 100, "N": 290, "n": 290, "B": 300, "b": 300, "R": 500, "r": 500, "Q": 850, "q": 800, "K": 10000, "k": 10000}
import timeit
import numpy as np
import Chess

def defence_attack_maps_initial (board_FEN, piece_values, positions):
    #finds attack and defend maps for a given chess position takes material values as input
    #white_fen = board_FEN.replace(" b", " w")
    #black_fen = board_FEN.replace(" w", " b")
    board = chess.Board(board_FEN)
    maps = np.zeros((2, 8, 8))
    moves = board.legal_moves
    for i in [move.uci() for move in moves]:
        pos_x_old = int(positions[i[0]])
        pos_y_old = int(i[1])
        pos_x = int(positions[i[2]])
        pos_y = int(i[3])
        piece = str(board)[pos_x + 8 * pos_y]
        maps[0][pos_x-1][pos_y-1] += 1
        maps[1][pos_x-1][pos_y-1] += piece_values[piece]
    return maps

#cy = timeit.timeit('attack', setup = 'from main import defence_attack_maps_initial', number = 500000)
print(defence_attack_maps_initial("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", PIECE_VALUES, NOTATION_FIXER))
