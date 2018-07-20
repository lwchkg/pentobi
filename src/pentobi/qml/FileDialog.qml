import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0
import Qt.labs.folderlistmodel 2.11
import "." as Pentobi
import "Main.js" as Logic
import "Controls.js" as PentobiControls

Pentobi.Dialog {
    id: root

    property bool selectExisting: true
    property alias name: nameField.text
    property url folder
    property url fileUrl
    property string nameFilterText
    property string nameFilter

    property url _lastFolder

    footer: DialogButtonBox {
        Button {
            enabled: name.trim().length > 0
            text: selectExisting ?
                      PentobiControls.addMnemonic(
                          qsTr("Open"),
                          //: Mnemonic for button Open. Leave empty for no mnemonic.
                          qsTr("O")) :
                      PentobiControls.addMnemonic(
                          qsTr("Save"),
                          //: Mnemonic for button Save. Leave empty for no mnemonic.
                          qsTr("S"))
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }
        Button {
            text: PentobiControls.addMnemonic(
                      qsTr("Cancel"),
                      //: Mnemonic for button Cancel. Leave empty for no mnemonic.
                      qsTr("C"))
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
    }
    onOpened: {
        if (! isAndroid) {
            var pos = name.lastIndexOf(".")
            if (pos < 0)
                nameField.selectAll()
            else
                nameField.select(0, pos)
        }
        view.currentIndex = -1
    }
    onAccepted: {
        folder = folderModel.folder
        fileUrl = folder + "/" + name
    }

    Item {
        implicitWidth: {
            // Qt 5.11 doesn't correctly handle dialog sizing if dialog (incl.
            // frame) is wider than window and Default style never makes footer
            // wider than content (potentially eliding button texts).
            var w = font.pixelSize * 30
            w = Math.min(w, 0.9 * rootWindow.width)
            return w
        }
        implicitHeight: columnLayout.implicitHeight

        Action {
            shortcut: "Alt+Left"
            onTriggered: backButton.onClicked()
        }
        ColumnLayout
        {
            id: columnLayout

            anchors.fill: parent

            TextField {
                id: nameField

                visible: ! selectExisting
                focus: ! isAndroid
                onAccepted: if (name.trim().length > 0) root.accept()
                Layout.fillWidth: true
                Component.onCompleted: nameField.cursorPosition = nameField.length
            }
            RowLayout {
                Layout.fillWidth: true

                ToolButton {
                    id: backButton

                    property bool hasParent: ! folderModel.folder.toString().endsWith(":///")

                    enabled: hasParent
                    onClicked:
                        if (hasParent) {
                            _lastFolder = folderModel.folder
                            folderModel.folder = folderModel.parentFolder
                            if (selectExisting)
                                name = ""
                        }
                    icon {
                        source: "icons/filedialog-parent.svg"
                        width: 16; height: 16
                    }
                }
                Label {
                    text: Logic.getFileFromUrl(folderModel.folder)
                    elide: Text.ElideLeft
                    Layout.fillWidth: true
                }
            }
            Frame {
                id: frame

                padding: 0.1 * font.pixelSize
                focusPolicy: Qt.TabFocus
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(font.pixelSize* 40, 0.4 * rootWindow.height)

                Rectangle {
                    anchors.fill: parent
                    color: frame.palette.base
                }
                ListView {
                    id: view

                    anchors.fill: parent
                    clip: true
                    model: folderModel
                    boundsBehavior: Flickable.StopAtBounds
                    highlight: Rectangle { color: frame.palette.highlight }
                    highlightMoveDuration: 0
                    focus: true
                    onActiveFocusChanged:
                        if (activeFocus && currentIndex < 0 && count)
                            currentIndex = 0
                    delegate: AbstractButton {
                        width: view.width
                        height: 2 * font.pixelSize
                        focusPolicy: Qt.NoFocus
                        contentItem: Row {
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: folderModel.isFolder(index)
                                width: 0.8 * font.pixelSize; height: width
                                source: "icons/filedialog-folder.svg"
                                sourceSize { width: width; height: height }
                            }
                            Text {
                                text: index < 0 ? "" : fileName
                                anchors.verticalCenter: parent.verticalCenter
                                leftPadding: 0.2 * font.pixelSize
                                color: view.currentIndex == index ?
                                           frame.palette.highlightedText :
                                           frame.palette.text
                                horizontalAlignment: Text.AlignHLeft
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }
                        onClicked: {
                            view.currentIndex = index
                            if (folderModel.isFolder(index)) {
                                if (! folderModel.folder.toString().endsWith("/"))
                                    folderModel.folder = folderModel.folder + "/"
                                folderModel.folder = folderModel.folder + fileName
                                view.currentIndex = -1
                                if (selectExisting)
                                    name = ""
                            }
                            else
                                name = fileName
                        }
                        onDoubleClicked:
                            if (! (folderModel.isFolder(index)))
                                root.accept()
                    }

                    FolderListModel {
                        id: folderModel

                        folder: root.folder
                        nameFilters: [ root.nameFilter ]
                        showDirsFirst: true
                        onStatusChanged:
                            if (status === FolderListModel.Ready) {
                                var i = folderModel.indexOf(_lastFolder)
                                if (i >= 0)
                                    view.currentIndex = i
                            }
                    }
                }
            }
            ComboBox {
                id: comboBoxNameFilter

                model: [ nameFilterText, qsTr("All files (*)") ]
                onCurrentIndexChanged:
                    if (currentIndex == 0) folderModel.nameFilters = [ root.nameFilter ]
                    else folderModel.nameFilters = [ "*" ]
                Layout.preferredWidth: Math.min(font.pixelSize * 18, 0.9 * rootWindow.width)
                Layout.alignment: Qt.AlignRight
            }
        }
    }
}
