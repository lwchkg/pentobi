//-----------------------------------------------------------------------------
/** @file pentobi/qml/GameInfoDialog.qml
    @author Markus Enzenberger
    @copyright GNU General Public License version 3 or later */
//-----------------------------------------------------------------------------

import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.0
import "." as Pentobi

Pentobi.Dialog {
    title: isDesktop ? qsTr("Game Info") : ""
    footer: OkCancelButtons { }
    onOpened: {
        textFieldPlayerName0.text = gameModel.playerName0
        textFieldPlayerName1.text = gameModel.playerName1
        textFieldPlayerName2.text = gameModel.playerName2
        textFieldPlayerName3.text = gameModel.playerName3
        textFieldDate.text = gameModel.date
        textFieldTime.text = gameModel.time
        textFieldEvent.text = gameModel.event
        textFieldRound.text = gameModel.round
    }
    onAccepted: {
        gameModel.playerName0 = textFieldPlayerName0.text
        gameModel.playerName1 = textFieldPlayerName1.text
        gameModel.playerName2 = textFieldPlayerName2.text
        gameModel.playerName3 = textFieldPlayerName3.text
        gameModel.date = textFieldDate.text
        gameModel.time = textFieldTime.text
        gameModel.event = textFieldEvent.text
        gameModel.round = textFieldRound.text
    }

    Flickable {
        implicitWidth: Math.min(font.pixelSize * 25, 0.9 * rootWindow.width)
        implicitHeight: Math.min(gridLayout.implicitHeight, 0.7 * rootWindow.height)
        contentHeight: gridLayout.implicitHeight
        clip: true

        GridLayout {
            id: gridLayout

            anchors.fill: parent
            columns: 2

            Label {
                text: {
                    if (gameModel.nuColors === 4 && gameModel.nuPlayers === 2)
                        return qsTr("Player Blue/Red:")
                    if (gameModel.gameVariant === "duo")
                        return qsTr("Player Purple:")
                    if (gameModel.gameVariant === "junior")
                        return qsTr("Player Green:")
                    return qsTr("Player Blue:")
                }
            }
            TextField {
                id: textFieldPlayerName0

                Layout.fillWidth: true
            }
            Label {
                text: {
                    if (gameModel.nuColors === 4 && gameModel.nuPlayers === 2)
                        return qsTr("Player Yellow/Green:")
                    if (gameModel.gameVariant === "duo" || gameModel.gameVariant === "junior")
                        return qsTr("Player Orange:")
                    if (gameModel.nuColors === 2)
                        return qsTr("Player Green:")
                    return qsTr("Player Yellow:")
                }
            }
            TextField {
                id: textFieldPlayerName1

                Layout.fillWidth: true
            }
            Label {
                visible: textFieldPlayerName2.visible
                text: qsTr("Player Red:")
            }
            TextField {
                id: textFieldPlayerName2

                visible: gameModel.nuPlayers > 2
                Layout.fillWidth: true
            }
            Label {
                visible: textFieldPlayerName3.visible
                text: qsTr("Player Green:")
            }
            TextField {
                id: textFieldPlayerName3

                visible: gameModel.nuPlayers > 3
                Layout.fillWidth: true
            }
            Label { text: qsTr("Date:") }
            TextField {
                id: textFieldDate

                Layout.fillWidth: true
            }
            Label { text: qsTr("Time:") }
            TextField {
                id: textFieldTime

                Layout.fillWidth: true
            }
            Label { text: qsTr("Event:") }
            TextField {
                id: textFieldEvent

                Layout.fillWidth: true
            }
            Label { text: qsTr("Round:") }
            TextField {
                id: textFieldRound

                Layout.fillWidth: true
            }
        }
    }
}