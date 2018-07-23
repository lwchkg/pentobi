//-----------------------------------------------------------------------------
/** @file pentobi/qml/MenuExport.qml
    @author Markus Enzenberger
    @copyright GNU General Public License version 3 or later */
//-----------------------------------------------------------------------------

import "." as Pentobi

Pentobi.Menu {
    title: addMnemonic(qsTr("Export"),
                       //: Mnemonic for menu Export. Leave empty for no mnemonic.
                       qsTr("E"))

    Pentobi.MenuItem {
        text: addMnemonic(qsTr("Image"),
                          //: Mnemonic for menu item Image. Leave empty for no mnemonic.
                          qsTr("M"))
        onTriggered: exportImageDialog.open()
    }
    Pentobi.MenuItem {
        text: addMnemonic(qsTr("ASCII Art"),
                          //: Mnemonic for menu item ASCII Art. Leave empty for no mnemonic.
                          qsTr("A"))
        onTriggered: asciiArtSaveDialog.open()
    }
}