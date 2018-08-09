//-----------------------------------------------------------------------------
/** @file pentobi/qml/Main.qml
    @author Markus Enzenberger
    @copyright GNU General Public License version 3 or later */
//-----------------------------------------------------------------------------

import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import Qt.labs.settings 1.0
import pentobi 1.0
import "." as Pentobi
import "Main.js" as Logic

ApplicationWindow {
    id: rootWindow

    property bool computerPlays0
    property bool computerPlays1: true
    property bool computerPlays2: true
    property bool computerPlays3: true
    property bool isPlaySingleMoveRunning
    property bool isRated

    property alias gameDisplay: gameDisplayLoader.item

    // Was computer thinking on regular game move when game was autosaved?
    // If yes, it will automatically start a move generation on startup.
    property bool wasGenMoveRunning

    // If the user manually disabled all computer colors in the dialog, we
    // assume that they want to edit games rather than play, and we will not
    // initialize the computer colors on New Game but only clear the board.
    property bool initComputerColorsOnNewGame: true

    property bool isAndroid: Qt.platform.os === "android"
    property string themeName: isAndroid ? "dark" : "system"
    property QtObject theme: Logic.createTheme(themeName)
    property url folder: androidUtils.getDefaultFolder()

    property real defaultWidth:
        isAndroid ? Screen.desktopAvailableWidth
                  : Math.min(Screen.desktopAvailableWidth, 1200)
    property real defaultHeight:
        isAndroid ? Screen.desktopAvailableHeight
                  : Math.min(Screen.desktopAvailableHeight, 680)

    property int exportImageWidth: 420
    property bool busyIndicatorRunning: lengthyCommand.isRunning
                                        || playerModel.isGenMoveRunning
                                        || analyzeGameModel.isRunning

    property Actions actions: Actions { }

    minimumWidth: isDesktop ? 597 : 240
    minimumHeight: isDesktop ? 365 : 301
    width: defaultWidth; height: defaultHeight
    x: (Screen.width - defaultWidth) / 2
    y: (Screen.height - defaultHeight) / 2
    color: theme.colorBackground
    //: Main window title if no file is loaded.
    title: qsTr("Pentobi")
    onClosing: {
        if ( ! Logic.autoSaveAndQuit())
            close.accepted = false
    }
    Component.onCompleted: {
        Logic.init()
        show()
    }
    MouseArea {
        anchors.fill: parent
        onClicked: gameDisplay.dropCommentFocus()
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Pentobi.ToolBar {
            id: toolBar

            visible: ! (visibility === Window.FullScreen && isAndroid)
            Layout.fillWidth: true
            Layout.margins: isDesktop ? 2 : 0
        }
        Loader {
            id: gameDisplayLoader

            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: isDesktop ? componentGameDisplayDesktop : componentGameDisplayMobile

            Component {
                id: componentGameDisplayDesktop

                GameDisplayDesktop {
                    theme: rootWindow.theme
                    busyIndicatorRunning: rootWindow.busyIndicatorRunning
                    onPlay: Logic.play(pieceModel, gameCoord)
                }
            }
            Component {
                id: componentGameDisplayMobile

                GameDisplayMobile {
                    theme: rootWindow.theme
                    busyIndicatorRunning: rootWindow.busyIndicatorRunning
                    onPlay: Logic.play(pieceModel, gameCoord)
                }
            }
        }
    }
    MouseArea {
        visible: isDesktop
        enabled: false // only for setting cursor shape
        anchors.fill: parent
        cursorShape: busyIndicatorRunning ? Qt.BusyCursor : Qt.ArrowCursor
    }

    Settings {
        id: settings

        property alias x: rootWindow.x
        property alias y: rootWindow.y
        property alias width: rootWindow.width
        property alias height: rootWindow.height
        property alias folder: rootWindow.folder
        property alias themeName: rootWindow.themeName
        property alias exportImageWidth: rootWindow.exportImageWidth
        property alias showVariations: gameModel.showVariations
        property alias initComputerColorsOnNewGame: rootWindow.initComputerColorsOnNewGame
        property alias level: playerModel.level

        // Settings related to autosaved game (no aliases)
        property bool computerPlays0
        property bool computerPlays1
        property bool computerPlays2
        property bool computerPlays3
        property bool isRated
        property bool wasGenMoveRunning
    }
    GameModel {
        id: gameModel

        onPositionAboutToChange: Logic.cancelRunning(true)
        onPositionChanged: {
            gameDisplay.pickedPiece = null
            if (gameModel.canGoBackward || gameModel.canGoForward
                    || gameModel.moveNumber > 0)
                gameDisplay.setupMode = false
            analyzeGameModel.markCurrentMove(gameModel)
            gameDisplay.dropCommentFocus()
        }
        onInvalidSgfFile: Logic.showInfo(gameModel.lastInputOutputError)
        onRecentFilesChanged: toolBar.destroyMenu()
    }
    PlayerModel {
        id: playerModel

        gameVariant: gameModel.gameVariant
        onMoveGenerated: Logic.moveGenerated(move)
        onSearchCallback: gameDisplay.searchCallback(elapsedSeconds, remainingSeconds)
        onIsGenMoveRunningChanged:
            if (isGenMoveRunning) gameDisplay.startSearch()
            else gameDisplay.endSearch()
        Component.onCompleted:
            if (notEnoughMemory())
                Logic.showFatal(qsTr("Not enough memory."))
    }
    AnalyzeGameModel {
        id: analyzeGameModel

        onIsRunningChanged: if (! isRunning) gameDisplay.endAnalysis()
    }
    RatingModel {
        id: ratingModel

        gameVariant: gameModel.gameVariant
    }
    AndroidUtils { id: androidUtils }
    DialogLoader { id: aboutDialog; Component { AboutDialog { } } }
    DialogLoader { id: computerDialog; Component { ComputerDialog { } } }
    DialogLoader { id: fatalMessage; Component { FatalMessage { } } }
    DialogLoader { id: gameVariantDialog; Component { GameVariantDialog { } } }
    DialogLoader { id: gameInfoDialog; Component { GameInfoDialog { } } }
    DialogLoader { id: initialRatingDialog; Component { InitialRatingDialog { } } }
    DialogLoader { id: newFolderDialog; Component { NewFolderDialog { } } }
    DialogLoader { id: openDialog; Component { OpenDialog { } } }
    DialogLoader { id: exportImageDialog; Component { ExportImageDialog { } } }
    DialogLoader { id: imageSaveDialog; Component { ImageSaveDialog { } } }
    DialogLoader { id: asciiArtSaveDialog; Component { AsciiArtSaveDialog { } } }
    DialogLoader { id: gotoMoveDialog; Component { GotoMoveDialog { } } }
    DialogLoader { id: ratingDialog; Component { RatingDialog { } } }
    DialogLoader { id: saveDialog; Component { SaveDialog { } } }
    DialogLoader { id: infoMessage; Component { MessageDialog { } } }
    DialogLoader { id: questionMessage; Component { QuestionDialog { } } }
    DialogLoader { id: analyzeDialog; Component { AnalyzeDialog { } } }
    DialogLoader { id: appearanceDialog; Component { AppearanceDialog{ } } }
    DialogLoader { id: moveAnnotationDialog; Component { MoveAnnotationDialog{ } } }
    Loader {
        id: helpWindow

        Component {
            id: helpWindowComponent

            HelpWindow { }
        }
    }

    // Used to delay calls to Logic.checkComputerMove such that the computer
    // starts thinking and the busy indicator is visible after the current move
    // placement animation has finished
    Timer {
        id: delayedCheckComputerMove

        interval: 500
        onTriggered: Logic.checkComputerMove()
    }

    // Delay lengthy blocking function calls such that busy indicator is visible
    Timer {
        id: lengthyCommand

        property bool isRunning
        property var func

        function run(func) {
            lengthyCommand.func = func
            isRunning = true
            restart()
        }

        interval: 400
        onTriggered: {
            func()
            isRunning = false
        }
    }

    Connections {
        target: Qt.application
        onStateChanged:
            if (Qt.application.state === Qt.ApplicationSuspended)
                Logic.autoSaveNoVerify()
    }
}
