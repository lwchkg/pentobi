//-----------------------------------------------------------------------------
/** @file libboardgame_base/Grid.h
    @author Markus Enzenberger
    @copyright GNU General Public License version 3 or later */
//-----------------------------------------------------------------------------

#ifndef LIBBOARDGAME_BASE_GRID_H
#define LIBBOARDGAME_BASE_GRID_H

#include <algorithm>
#include <cstring>
#include <iomanip>
#include <sstream>
#include <type_traits>
#include "Point.h"
#include "Geometry.h"

namespace libboardgame_base {

using namespace std;

//-----------------------------------------------------------------------------

/** Elements assigned to on-board points.
    The elements must be default-constructible. This class is a POD if the
    element type is a POD.
    @tparam P An instantiation of libboardgame_base::Point (or compatible class)
    @tparam T The element type. */
template<class P, typename T>
class Grid
{
public:
    typedef P Point;

    typedef libboardgame_base::Geometry<P> Geometry;

    typedef typename libboardgame_base::Geometry<P>::Iterator Iterator;

    T& operator[](const Point& p);

    const T& operator[](const Point& p) const;

    /** Fill all on-board points for a given geometry with a value. */
    void fill(const T& val, const Geometry& geo);

    /** Fill points with a value. */
    void fill_all(const T& val);

    string to_string(const Geometry& geo) const;

    /** @pre is_trivially_copyable<T>::value */
    void memcpy_from(const Grid& grid, const Geometry& geo);

private:
    T m_a[Point::range];
};

template<class P, typename T>
inline T& Grid<P, T>::operator[](const Point& p)
{
    return m_a[p.to_int()];
}

template<class P, typename T>
inline const T& Grid<P, T>::operator[](const Point& p) const
{
    return m_a[p.to_int()];
}

template<class P, typename T>
inline void Grid<P, T>::fill(const T& val, const Geometry& geo)
{
    for (Iterator i(geo); i; ++i)
        (*this)[*i] = val;
}

template<class P, typename T>
inline void Grid<P, T>::fill_all(const T& val)
{
    std::fill(m_a, m_a + Point::range, val);
}

template<class P, typename T>
inline void Grid<P, T>::memcpy_from(const Grid& grid, const Geometry& geo)
{
    // Uncomment once is_trivially_copyable is implemented in GCC and MSVC
    //static_assert(is_trivially_copyable<T>::value, "")
    memcpy(m_a, grid.m_a, sizeof(T) * geo.get_range());
}

template<class P, typename T>
string Grid<P, T>::to_string(const Geometry& geo) const
{
    ostringstream buffer;
    size_t max_len = 0;
    for (Iterator i(geo); i; ++i)
    {
        buffer.str("");
        buffer << (*this)[*i];
        max_len = max(max_len, buffer.str().length());
    }
    buffer.str("");
    auto width = geo.get_width();
    auto height = geo.get_height();
    string empty(max_len, ' ');
    for (unsigned y = 0; y < height; ++y)
    {
        for (unsigned x = 0; x < width; ++x)
        {
            Point p(x, y, width);
            if (geo.is_onboard(p))
                buffer << setw(int(max_len)) << (*this)[p];
            else
                buffer << empty;
            if (x < width - 1)
                buffer << ' ';
        }
        buffer << '\n';
    }
    return buffer.str();
}

//-----------------------------------------------------------------------------

} // namespace libboardgame_base

#endif // LIBBOARDGAME_BASE_GRID_H
