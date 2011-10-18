//-----------------------------------------------------------------------------
/** @file pentobi_thumbnailer/Main.cpp */
//-----------------------------------------------------------------------------

#include <vector>
#include <boost/algorithm/string.hpp>
#include <boost/algorithm/string/case_conv.hpp>
#include <boost/program_options.hpp>
#include "libboardgame_sgf/TreeReader.h"
#include "libboardgame_sgf/Util.h"
#include "libpentobi_gui/BoardPainter.h"

using namespace std;
using boost::trim_copy;
using boost::algorithm::to_lower_copy;
using boost::program_options::command_line_parser;
using boost::program_options::options_description;
using boost::program_options::notify;
using boost::program_options::positional_options_description;
using boost::program_options::store;
using boost::program_options::value;
using boost::program_options::variables_map;
using libboardgame_sgf::Node;
using libboardgame_sgf::TreeReader;
using libpentobi_base::game_variant_classic;
using libpentobi_base::game_variant_classic_2;
using libpentobi_base::game_variant_duo;
using libpentobi_base::GameVariant;
using libpentobi_base::Geometry;
using libpentobi_base::FullGrid;
using libpentobi_base::PointState;
using libpentobi_base::PointStateExt;

//-----------------------------------------------------------------------------

namespace {

/** Get the board state of the final position of the main variation.
    Avoids constructing an instance of a Tree or Game, which would do a costly
    initialization of BoardConst and slow down the thumbnailer unnecessarily. */
bool getFinalPosition(const Node& root, GameVariant& gameVariant,
                      FullGrid<PointStateExt>& pointState)
{
    string game = root.get_property("GM", "");
    string s = to_lower_copy(trim_copy(game));
    unsigned int sz;
    if (s == "blokus duo")
    {
        gameVariant = game_variant_duo;
        sz = 14;
    }
    else if (s == "blokus")
    {
        gameVariant = game_variant_classic;
        sz = 20;
    }
    else if (s == "blokus two-player")
    {
        gameVariant = game_variant_classic_2;
        sz = 20;
    }
    else
        return false;
    const Geometry* geometry = Geometry::get(sz, sz);
    pointState.init(*geometry);
    pointState.fill_onboard(PointState::empty());
    const Node* node = &root;
    while (node != 0)
    {
        Color c = Color(0); // initialize to avoid compiler warning
        string id;
        vector<string> values;
        if (gameVariant == game_variant_duo)
        {
            if (node->has_property("B"))
            {
                id = "B";
                c = Color(0);
            }
            else if (node->has_property("W"))
            {
                id = "W";
                c = Color(1);
            }
        }
        else
        {
            if (node->has_property("1"))
            {
                id = "1";
                c = Color(0);
            }
            else if (node->has_property("2"))
            {
                id = "2";
                c = Color(1);
            }
            else if (node->has_property("3"))
            {
                id = "3";
                c = Color(2);
            }
            else if (node->has_property("4"))
            {
                id = "4";
                c = Color(3);
            }
            else if (node->has_property("BLUE"))
            {
                id = "BLUE";
                c = Color(0);
            }
            else if (node->has_property("YELLOW"))
            {
                id = "YELLOW";
                c = Color(1);
            }
            else if (node->has_property("RED"))
            {
                id = "RED";
                c = Color(2);
            }
            else if (node->has_property("GREEN"))
            {
                id = "GREEN";
                c = Color(3);
            }
        }
        if (! id.empty())
        {
            values = node->get_multi_property(id);
            if (! (values.size() == 1 && values[0].empty()))
            {
                BOOST_FOREACH(const string& s, values)
                {
                    if (trim_copy(s).empty())
                        return false;
                    Point p = Point::from_string(s);
                    if (geometry->is_onboard(p))
                        pointState[p] = c;
                }
            }
        }
        node = node->get_first_child_or_null();
    }
    return true;
}

} //namespace

//-----------------------------------------------------------------------------

int main(int argc, char* argv[])
{
    int size = 128;
    vector<string> files;
    options_description normal_options("Options");
    normal_options.add_options()
        ("size,s", value<int>(&size), "Image size");
    options_description hidden_options;
    hidden_options.add_options()
        ("files", value<vector<string>>(&files),
         "input-file output-file");
    options_description all_options;
    all_options.add(normal_options).add(hidden_options);
    positional_options_description positional_options;
    positional_options.add("files", -1);
    variables_map vm;
    store(command_line_parser(argc, argv).options(all_options).
          positional(positional_options).run(), vm);
    notify(vm);
    if (size <= 0)
    {
        cerr << "Invalid image size\n";
        return 1;
    }
    if (files.size() > 2)
    {
        cerr << "Too many file arguments\n";
        return 1;
    }
    if (files.size() < 2)
    {
        cerr << "Need input and output file argument\n";
        return 1;
    }

    TreeReader reader;
    reader.set_read_only_main_variation(true);
    try
    {
        reader.read(files[0]);
    }
    catch (const TreeReader::ReadError& e)
    {
        cerr << e.what() << '\n';
        return 1;
    }
    GameVariant gameVariant =
        game_variant_classic; // Initialize to avoid compiler warning
    FullGrid<PointStateExt> pointState;
    if (! getFinalPosition(reader.get_tree(), gameVariant, pointState))
    {
        cerr << "Not a valid Blokus SGF file";
        return 1;
    }

    BoardPainter boardPainter;
    QImage image(size, size, QImage::Format_ARGB32);
    image.fill(Qt::transparent);
    QPainter painter;
    painter.begin(&image);
    boardPainter.paint(painter, size, size, gameVariant, pointState);
    painter.end();
    QImageWriter writer(files[1].c_str());
    writer.setFormat("png");
    if (! writer.write(image))
    {
        cerr << writer.errorString().toStdString() << '\n';
        return 1;
    }
    return 0;
}

//-----------------------------------------------------------------------------
