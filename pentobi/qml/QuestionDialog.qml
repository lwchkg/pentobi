//-----------------------------------------------------------------------------
/** @file pentobi/qml/QuestionDialog.qml
    @author Markus Enzenberger
    @copyright GNU General Public License version 3 or later */
//-----------------------------------------------------------------------------

import QtQuick 2.0
import QtQuick.Controls 2.2
import "Main.js" as Logic

PentobiDialog {
    function openWithCallback(text, acceptedFunc) {
        label.text = text
        _acceptedFunc = acceptedFunc
        open()
    }

    property var _acceptedFunc

    footer: DialogButtonBoxOkCancel { }
    onAccepted: Qt.callLater(_acceptedFunc)

    Item {
        implicitWidth:
            Math.max(Math.min(label.implicitWidth,
                              font.pixelSize * 25, maxContentWidth),
                     font.pixelSize * 15, minContentWidth)
        implicitHeight: label.implicitHeight

        Label {
            id: label

            anchors.fill: parent
            wrapMode: Text.Wrap
        }
    }
}
