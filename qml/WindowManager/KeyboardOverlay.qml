/*
 * Copyright (C) 2013 Christophe Chapuis <chris.chapuis@gmail.com>
 * Copyright (C) 2013 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.0
import QtQuick.Window 2.2
import LunaNext.Common 0.1
import WebOSCompositorBase 1.0
import WebOSCoreCompositor 1.0

Item {
    id: keyboardOverlayItem
    property var compositorInstance

    WindowModel {
        id: listKeyboardsModel
        surfaceSource: compositorInstance.surfaceModel
        windowType: "_WEBOS_WINDOW_TYPE_KEYBOARD"

        onRowsInserted: (index, first, last) => {
            appendKeyboardWindow(listKeyboardsModel.get(last));
        }
    }

    Rectangle {
        id: overlayBackgroundArea
        anchors.fill: parent
        color: "grey"
        opacity: 0.2
        visible: associatedPopupWindow !== null
        property Item associatedPopupWindow
        MouseArea {
            anchors.fill: overlayBackgroundArea
            onClicked: {
                compositorInstance.closeWindow(overlayBackgroundArea.associatedPopupWindow);
                overlayBackgroundArea.associatedPopupWindow = null;
            }
        }
    }

    onWidthChanged:  updateOverlaySizes();
    onHeightChanged: updateOverlaySizes();

    /*!
     * The size a keyboard's panel window is: the screen's. webos-keyboard draws
     * the keys along the bottom of a screen-sized window and masks away the rest
     * (and keeps it screen-sized whatever it is asked for, since a panel window
     * the compositor had shrunk stopped being shown - webos-keyboard 35de21b), so
     * that is what it is asked for, and the window is drawn at that size with its
     * bottom on the overlay's. Asked for the overlay's size and stretched to fill
     * it, as before, the screen-sized surface it sent back anyway was scaled down
     * into the overlay, which stops at the status bar and the gesture area: on a
     * KEY2 1620 px into 1445, every key at 89% of its height.
     *
     * The screen as the overlay stands: turned on its side while the shell is in
     * landscape (it rotates itself, not the output, so Screen stays portrait).
     */
    readonly property bool landscape: keyboardOverlayItem.width > keyboardOverlayItem.height
    readonly property size keyboardWindowSize: landscape
        ? Qt.size(Math.max(Screen.width, Screen.height), Math.min(Screen.width, Screen.height))
        : Qt.size(Math.min(Screen.width, Screen.height), Math.max(Screen.width, Screen.height))

    onKeyboardWindowSizeChanged: updateOverlaySizes();

    function updateOverlaySizes() {
        console.log("new keyboard overlay window size = " + keyboardOverlayItem.width +"x"+ keyboardOverlayItem.height);
        for( var i = 0; i < listKeyboardsModel.count; ++i ) {
            var window = listKeyboardsModel.get(i);
            if(!window.isPopup) {
                window.changeSize(keyboardOverlayItem.keyboardWindowSize);
            }
        }
    }

    function appendKeyboardWindow(window) {
        console.log("KeyboardOverlay: adding " + window);

        window.parent = keyboardOverlayItem;
        if(!window.isPopup) {
            // Screen-sized (see keyboardWindowSize) and drawn 1:1: across the
            // overlay, its bottom on the overlay's, the keys just above the
            // gesture area. Above the overlay it is transparent and masked out.
            window.anchors.left = keyboardOverlayItem.left;
            window.anchors.right = keyboardOverlayItem.right;
            window.anchors.bottom = keyboardOverlayItem.bottom;
            window.height = Qt.binding(function() { return keyboardOverlayItem.keyboardWindowSize.height; });
            window.changeSize(keyboardOverlayItem.keyboardWindowSize);
        }
        else {
            window.anchors.centerIn = keyboardOverlayItem;
            overlayBackgroundArea.associatedPopupWindow = window;
        }
    }
}
