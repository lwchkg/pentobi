//-----------------------------------------------------------------------------
/** @file twogtp/OutputTree.h
    @author Markus Enzenberger
    @copyright GNU General Public License version 3 or later */
//-----------------------------------------------------------------------------

#ifndef TWOGTP_OUTPUT_TREE_H
#define TWOGTP_OUTPUT_TREE_H

#include <random>
#include "libpentobi_base/Board.h"
#include "libpentobi_base/PentobiTree.h"

using namespace std;
using libboardgame_base::PointTransform;
using libboardgame_util::ArrayList;
using libpentobi_base::Board;
using libpentobi_base::Color;
using libpentobi_base::Move;
using libpentobi_base::PentobiTree;
using libpentobi_base::Point;
using libpentobi_base::Variant;

//-----------------------------------------------------------------------------

/** Merges opening moves played by the players into a tree.

    Keeps statistics of the average game result for each move and player.
    This class can also speed up playing test games by generating opening moves
    according to the measured probability distributions. With some probabilty,
    which decreases with the number of times a position was visited but stays
    non-zero, the player generates a real move, which is used to update the
    distributions, otherwise a move from the tree is played. In the limit, the
    player plays an infinite number of real moves in each position, so the
    measured distributions approach the real distributions and the result of
    the test games approaches the result as if only real moves had been
    played. */
class OutputTree
{
public:
    OutputTree(Variant variant);

    ~OutputTree();

    void load(const string& file);

    void save(const string& file);

    /** Generate a move for a player from the tree.
        @param is_player_black
        @param bd The board with the current position and color to play.
        @param mv[out] The generated move or undefined if the result is false.
        @return false, if no move for this position and player is in the tree
        or if the player should generate a real move now. */
    bool generate_move(bool is_player_black, const Board& bd, Color to_play,
                       Move& mv);

    /** Add the moves of a game to the tree and update the move counters. */
    void add_game(const Board& bd, unsigned player_black, float result,
                  array<bool, Board::max_game_moves>& is_real_move);

private:
    typedef libboardgame_base::PointTransform<Point> PointTransform;

    PentobiTree m_tree;

    vector<unique_ptr<PointTransform>> m_transforms;

    vector<unique_ptr<PointTransform>> m_inv_transforms;

    mt19937 m_random;

    bool generate_move(bool is_player_black, const Board& bd, Color to_play,
                       const PointTransform& transform,
                       const PointTransform& inv_transform, Move& mv);
};

//-----------------------------------------------------------------------------

#endif // TWOGTP_OUTPUT_TREE_H
