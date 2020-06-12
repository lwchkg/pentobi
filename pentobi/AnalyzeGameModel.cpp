//-----------------------------------------------------------------------------
/** @file pentobi/AnalyzeGameModel.cpp
    @author Markus Enzenberger
    @copyright GNU General Public License version 3 or later */
//-----------------------------------------------------------------------------

#include "AnalyzeGameModel.h"

#include <QSettings>
#include <QtConcurrentRun>
#include "GameModel.h"
#include "PlayerModel.h"
#include "libboardgame_base/SgfUtil.h"

using libboardgame_base::ArrayList;
using libboardgame_base::is_main_variation;
using libboardgame_base::find_root;
using libpentobi_base::ColorMove;

//-----------------------------------------------------------------------------

AnalyzeGameElement::AnalyzeGameElement(QObject* parent, int moveColor,
                                       double value)
    : QObject(parent),
      m_moveColor(moveColor),
      m_value(value)
{
}

//-----------------------------------------------------------------------------

AnalyzeGameModel::AnalyzeGameModel(QObject* parent)
    : QObject(parent)
{
    connect(&m_watcher, &QFutureWatcher<void>::finished, this, [this]
    {
        updateElements();
        // Set isRunning after updating elements because in GameViewDesktop
        // either isRunning must be true or elements.length > 0 to show the
        // analysis and we don't want it to disappear if a game with one move
        // was analyzed.
        setIsRunning(false);
    });
}

AnalyzeGameModel::~AnalyzeGameModel()
{
    cancel();
}

void AnalyzeGameModel::asyncRun(const Game* game)
{
    auto progressCallback =
        [&]([[maybe_unused]] unsigned movesAnalyzed,
            [[maybe_unused]] unsigned totalMoves)
        {
            // Use invokeMethod() because callback runs in different thread
            QMetaObject::invokeMethod(this, "updateElements",
                                      Qt::BlockingQueuedConnection);
        };
    m_analyzeGame.run(*game, *m_search, m_nuSimulations, progressCallback);
}

void AnalyzeGameModel::autoSave(GameModel* gameModel)
{
    auto& bd = gameModel->getGame().get_board();
    QVariantList list;
    auto variant = bd.get_variant();
    auto nuMoves = m_analyzeGame.get_nu_moves();
    QSettings settings;
    if (nuMoves == 0 || m_analyzeGame.get_variant() != variant)
        settings.remove(QStringLiteral("analyzeGame"));
    else
    {
        list.append(to_string_id(variant));
        list.append(nuMoves);
        for (unsigned i = 0; i < nuMoves; ++i)
        {
            auto mv = m_analyzeGame.get_move(i);
            list.append(mv.color.to_int());
            list.append(bd.to_string(mv.move).c_str());
            list.append(m_analyzeGame.get_value(i));
        }
        settings.setValue(QStringLiteral("analyzeGame"),
                          QVariant::fromValue(list));
    }
}

void AnalyzeGameModel::cancel()
{
    if (! m_isRunning)
        return;
    m_search->abort();
    m_watcher.waitForFinished();
    setIsRunning(false);
}

void AnalyzeGameModel::clear()
{
    cancel();
    if (m_elements.empty())
        return;
    m_analyzeGame.clear();
    m_markMoveNumber = -1;
    m_elements.clear();
    emit elementsChanged();
}

QQmlListProperty<AnalyzeGameElement> AnalyzeGameModel::elements()
{
#if QT_VERSION >= QT_VERSION_CHECK(5, 15, 0)
    return {this, &m_elements};
#else
    return {this, m_elements};
#endif
}

void AnalyzeGameModel::gotoMove(GameModel* gameModel, int moveNumber)
{
    if (moveNumber < 0)
        return;
    auto n = static_cast<unsigned>(moveNumber);
    if (n >= m_analyzeGame.get_nu_moves())
        return;
    auto& game = gameModel->getGame();
    if (game.get_variant() != m_analyzeGame.get_variant())
        return;
    auto& tree = game.get_tree();
    auto node = &tree.get_root();
    if (tree.has_move(*node))
    {
        // Move in root node not supported.
        setMarkMoveNumber(-1);
        return;
    }
    for (unsigned i = 0; i < n; ++i)
    {
        auto mv = m_analyzeGame.get_move(i);
        bool found = false;
        for (auto& child : node->get_children())
            if (tree.get_move(child) == mv)
            {
                found = true;
                node = &child;
                break;
            }
        if (! found)
        {
            setMarkMoveNumber(-1);
            return;
        }
    }
    gameModel->gotoNode(*node);
    setMarkMoveNumber(moveNumber);
}

void AnalyzeGameModel::loadAutoSave(GameModel* gameModel)
{
    QSettings settings;
    auto list =
            settings.value(
                QStringLiteral("analyzeGame")).value<QVariantList>();
    int size = list.size();
    int index = 0;
    if (index >= size)
        return;
    auto variant = list[index++].toString();
    auto& bd = gameModel->getGame().get_board();
    if (variant != to_string_id(bd.get_variant()))
        return;
    if (index >= size)
        return;
    auto nuMoves = list[index++].toUInt();
    vector<ColorMove> moves;
    vector<double> values;
    for (unsigned i = 0; i < nuMoves; ++i)
    {
        if (index >= size)
            return;
        auto color = list[index++].toUInt();
        if (color >= bd.get_nu_colors())
            return;
        if (index >= size)
            return;
        auto moveString = list[index++].toString();
        Move mv;
        if (! bd.from_string(mv, moveString.toLatin1().constData()))
            return;
        if (index >= size)
            return;
        auto value = list[index++].toDouble();
        moves.emplace_back(Color(static_cast<Color::IntType>(color)), mv);
        values.push_back(value);
    }
    m_analyzeGame.set(bd.get_variant(), moves, values);
    updateElements();
}

void AnalyzeGameModel::markCurrentMove(GameModel* gameModel)
{
    auto& game = gameModel->getGame();
    auto& node = game.get_current();
    int moveNumber = -1;
    if (is_main_variation(node))
    {
        ArrayList<ColorMove, Board::max_moves> moves;
        auto& tree = game.get_tree();
        auto current = &find_root(node);
        while (current)
        {
            auto mv = tree.get_move(*current);
            if (! mv.is_null() && moves.size() < Board::max_moves)
                moves.push_back(mv);
            if (current == &node)
                break;
            current = current->get_first_child_or_null();
        }
        if (moves.size() <= m_analyzeGame.get_nu_moves())
        {
            for (unsigned i = 0; i < moves.size(); ++i)
                if (moves[i] != m_analyzeGame.get_move(i))
                    return;
            moveNumber = static_cast<int>(moves.size());
        }
    }
    setMarkMoveNumber(moveNumber);
}

void AnalyzeGameModel::setIsRunning(bool isRunning)
{
    if (m_isRunning == isRunning)
        return;
    m_isRunning = isRunning;
    emit isRunningChanged();
}

void AnalyzeGameModel::setMarkMoveNumber(int markMoveNumber)
{
    if (m_markMoveNumber == markMoveNumber)
        return;
    m_markMoveNumber = markMoveNumber;
    emit markMoveNumberChanged();
}

void AnalyzeGameModel::start(GameModel* gameModel, PlayerModel* playerModel,
                             int nuSimulations)
{
    if (nuSimulations <= 0)
        return;
    m_markMoveNumber = -1;
    m_nuSimulations = static_cast<size_t>(nuSimulations);
    cancel();
    m_search = &playerModel->getSearch();
    auto future = QtConcurrent::run(this, &AnalyzeGameModel::asyncRun,
                                    &gameModel->getGame());
    m_watcher.setFuture(future);
    setIsRunning(true);
}

void AnalyzeGameModel::updateElements()
{
    m_elements.clear();
    for (unsigned i = 0; i < m_analyzeGame.get_nu_moves(); ++i)
    {
        auto moveColor = m_analyzeGame.get_move(i).color.to_int();
        // Values of search are supposed to be win/loss probabilities but can
        // be slightly outside [0..1] (see libpentobi_mcts::State).
        auto value = max(0., min(1., m_analyzeGame.get_value(i)));
        m_elements.append(new AnalyzeGameElement(this, moveColor, value));
    }
    emit elementsChanged();
}

//-----------------------------------------------------------------------------
