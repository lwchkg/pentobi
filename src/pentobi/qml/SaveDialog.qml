//-----------------------------------------------------------------------------
/** @file pentobi/qml/SaveDialog.qml
    @author Markus Enzenberger
    @copyright GNU General Public License version 3 or later */
//-----------------------------------------------------------------------------

import QtQuick 2.0
import "Main.js" as Logic
import "." as Pentobi

Pentobi.FileDialog {
    title: isDesktop ? qsTr("Save") : ""
    selectExisting: false
    nameFilterText: qsTr("Blokus games (*.blksgf)")
    nameFilter: "*.blksgf"
    folder: rootWindow.folder
    onAccepted: {
        rootWindow.folder = folder
        if (gameModel.checkFileExists(Logic.getFileFromUrl(fileUrl)))
            Logic.showQuestion(qsTr("Overwrite existing file?"), save)
        else
            save()
    }

    function save() { Logic.saveFile(Logic.getFileFromUrl(fileUrl)) }
}