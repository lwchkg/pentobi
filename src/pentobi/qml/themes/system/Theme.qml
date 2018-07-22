//-----------------------------------------------------------------------------
/** @file pentobi/qml/themes/system/Theme.qml
    @author Markus Enzenberger
    @copyright GNU General Public License version 3 or later */
//-----------------------------------------------------------------------------

import QtQuick 2.11
import "../light" as Light

Light.Theme {
    SystemPalette { id: palette }

    property color colorBackground: palette.window
    property color colorButtonPressed: palette.dark
    property color colorCommentBorder: palette.mid
    property color colorCommentFocus: palette.highlight
    property color colorMessageText: colorText
    property color colorMessageBase: palette.base
    property color colorSelectedText: palette.highlightedText
    property color colorSelection: palette.highlight
    property color colorText: palette.text

    property real opacitySubduedText: 0.4
    property real toPlayColorLighter: 1.5 - colorBackground.hslLightness
}
