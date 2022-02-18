//==============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Copyright (C) 2012 Werner Schweer
//  Copyright (C) 2013-2017 Nicolas Froment, Joachim Schmitz
//  Copyright (C) 2019 Bernard Greenberg
//  Copyright (C) 2020 Andrew Grant
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public Licence version 2 as
//  published by the Free Software Foundation and appearing in the file LICENCE
//==============================================================================

import QtQuick 2.2
import MuseScore 3.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1

MuseScore {

    version:  "1.0"
    description: "Plugin for Guitar Tab"
    menuPath: "Plugins.TAB Tools"

    pluginType: "dock";
    dockArea: "left";
    implicitWidth: 165;
    implicitHeight: 360;

    property var range_mode : false;
    property var the_note : null;
    property var stop_recurse : false;
    property var nnflag : "not-note";
    property var display_up : false;
    property variant fingrgb : [ "#202020", "#6900b4", "#0042c8", "#006e00", "#b900b9", "#c0c0c0" ]

    onRun:
    {
        if ((mscoreMajorVersion != 3) || (mscoreMinorVersion < 3)) {
            versionError.open();
            Qt.quit();
            return;
        }
        stop_recurse = false;
        clear_all();
        pitchField.text = "-";
        display_up = false;
    }

    onScoreStateChanged:
    {
        if (stop_recurse) return;
        if (state.selectionChanged) {
            get_notes();
        }
        else if (display_up) {
            // This complex test fires the first time a user clicks blank space
            // when something is selected. This hook is called, but state.selectionChanged
            // is not on (it should be). The second time the blank space is clicked, it
            // works properly (v. 3.5).  Unfortunately, this turns off the nice feature
            // of triggering on keyboard-entered notes (to be solved).

            if (!curScore.selection || !curScore.selection.elements ||
               (curScore.selection.elements.len == undefined) ||
               (curScore.selection.elements.len == 0) ) clear_all();
        }
     }

    function get_notes()
    {
        the_note = false;
        var note_count = 0;
        clearButton.visible = false;
        var val = find_note();
        if (val == nnflag) {
            clear_all();
            return;
        }
        the_note = val;
        range_mode = false;

        if (!the_note) {
            applyToNotes(function(note, cursor) { note_count += 1;}, 2);
            if (note_count > 0) range_mode = true;
        }
        if (range_mode) {
            pitchField.text = "#" + note_count;
            onTime.text = "";
            offTime.text = "";
            showButton.enabled = true; showButton.text = "Show";
            resetButton.enabled = true; resetButton.text = "Reset";
            applyButton.enabled = true; applyButton.text = "Apply"
            display_up = true;
        }
        else if (the_note) {
            var events = the_note.playEvents;
            var pe0 = events[0];
            showButton.enabled = false; showButton.text = "";
            resetButton.enabled = true; resetButton.text = "Reset";
            applyButton.enabled = true; applyButton.text = "Apply";
            onTime.text = pe0.ontime + "";
            offTime.text = (pe0.ontime + pe0.len) + "";
            var tpc = get_tpc(the_note.tpc1);
            var octave = get_octave(tpc, the_note.pitch)
            pitchField.text = tpc + octave;
            display_up = true;
        }
        else clear_all();
    }

    function clear_all()
    {
        pitchField.text = "-";
        onTime.text = "-";
        offTime.text = "-";
        showButton.enabled = false;
        showButton.text = "";
        applyButton.enabled = false;
        applyButton.text = "";
        resetButton.enabled = false;
        resetButton.text = "";
        the_note = false;
        display_up = false;
    }

    function get_tpc(tpc)
    {
        var based_0 = tpc + 1;
        var result = "FCGDAEB"[based_0 % 7];
        var diverge = Math.floor(based_0 / 7);
        var appenda = ["bb", "b", "", "#", "##"];
        result = result + appenda[diverge];
        return result;
    }

    function get_octave(tpc, pitch)
    {
        var answer = Math.floor(pitch / 12) - 1;
        if (tpc == "B#" || tpc == "B##") {
            answer -= 1;
        }
        else if (tpc == "Cb" || tpc == "Cbb") {
            answer += 1;
        }
        return answer + "";
    }


    function find_note()
    {
        var selection = curScore.selection;
        var elements = selection.elements;
        if (elements.length == 1) { // We have a selection
            for (var idx = 0; idx < elements.length; idx++) {
                var element = elements[idx];
                if (element.type == Element.NOTE) {
                    var note = element;
                    var events = note.playEvents;
                    if (events.length == 1) {
                        var mpe0 = events[0];
                        return note;
                    }
                    else return nnflag;
                }
                else return nnflag;
            }
        }
        return false;
    }

    function is_num(val)
    {
        return /^\d+$/.test(val);
    }

    function resetChanges()
    {
        ringTime.text = "1000";
        applyChanges();
        ringTime.text = "2000";
    }

    function applyChanges()
    {
        if (!is_num(ringTime.text)) {
            // Doesn't work -- input boxes can't receive input until
            // score is focused first, unclear why, so comment out.
            inputError.open();
            return false;
        }
        var off_time = parseInt(ringTime.text);
        if (range_mode) {
            stop_recurse = true;
            curScore.startCmd();
            applyToNotes(function(note, cursor) {
                var mpe0 = note.playEvents[0];
                mpe0.len = off_time - mpe0.ontime;
            }, 1);
            curScore.endCmd();
            stop_recurse = false;
            return true;
        }
        var note = find_note();
        if (!note) return false;
        if (!is_num(onTime.text)) return false;
        var on_time = parseInt(onTime.text);
        stop_recurse = true;
        curScore.startCmd();
        var mpe0 = note.playEvents[0];
        mpe0.len = off_time - on_time;
        curScore.endCmd();
        offTime.text = ringTime.text;
        stop_recurse = false;
        return true;
    }

    function applyToNotes(func, nofvoc)
    {
        var cursor = curScore.newCursor();
        cursor.rewind(1);
        if (!cursor.segment) return; // no selection
        var endStaff;
        var startStaff = cursor.staffIdx;
        cursor.rewind(2);
        var endStaff = cursor.staffIdx;
        var endTick;
        if (cursor.tick === 0) {
            // this happens when the selection includes the last measure of the score.
            // rewind(2) goes behind the last segment (where there's none) and sets tick=0
            endTick = curScore.lastSegment.tick + 1;
        }
        else {
            endTick = cursor.tick;
        }
        cursor.rewind(1);

        for (var staff = startStaff; staff <= endStaff; staff++) {
            for (var voice = 0; voice < nofvoc; voice++) {
                cursor.rewind(1); // sets voice to 0
                cursor.voice = voice; //voice has to be set after goTo
                cursor.staffIdx = staff;
                while (cursor.segment && (cursor.tick < endTick)) {
                    if (cursor.element && cursor.element.type === Element.CHORD) {
                        var notes = cursor.element.notes;
                        for (var k = 0; k < notes.length; k++) {
                            var note = notes[k];
                            if (note.type == Element.NOTE) func(note, cursor);
                        }
                    }
                    cursor.next();
                }
            }
        }
        cursor.rewind(1); // otherwise score gets in non-notable state
    }

    function showTime(note, cursor)
    {
        var npe0 = note.playEvents[0];
        var on_time = npe0.ontime;
        var off_time = on_time + npe0.len;
        var timeText = off_time;
        var staffText = newElement(Element.STAFF_TEXT);
        staffText.text = timeText;
        staffText.placement = Placement.BELOW;
        staffText.fontSize = 6;
        cursor.add(staffText);
    }

    function showTimesInScore ()
    {
        applyButton.enabled = false;
        showButton.visible = false;
        clearButton.visible = true;
        curScore.startCmd();
        applyToNotes(showTime, 2);
        curScore.endCmd();
    }

    function setFingerColour(fing)
    {
        var cursor = curScore.newCursor();
        cursor.rewind(1);
        var note = find_note();
        if (!note) return false;
        curScore.startCmd();
        note.color = fingrgb[fing];
        curScore.endCmd();
        cursor.rewind(1);
    }

    GridLayout { id: 'mainLayout'

        anchors.fill: parent
        anchors.margins: 10
        columns: 3
        columnSpacing: 2
        rowSpacing: 2

        Label { id: section1
            visible: true
            Layout.columnSpan: 3
            Layout.topMargin: 0
            Layout.bottomMargin: 4
            text: "LET RING"
        }
        Label { id: pitchLabel
            visible : true
            text: "Selected"
        }
        TextField { id: pitchField
            visible:true
            enabled: false
            implicitHeight: 21
            implicitWidth: 40
            textColor: "#000099"
            placeholderText: "-"
        }
        Button { id: showButton
           visible: true
           enabled: false
           text: "Show"
           Layout.preferredWidth: 40
           onClicked: showTimesInScore();
        }
        Button { id: clearButton
            visible: false
            text: "Clear"
            Layout.preferredWidth: 40
            onClicked: {
                cmd("undo");
                clearButton.visible = false;
                showButton.visible = true;
            }
        }
        Label { id: onTimeLabel
            visible: true
            text:  "OnTime"
        }
        TextField { id: onTime
            visible: true
            enabled: false
            implicitHeight: 21
            implicitWidth: 40
            textColor: "#000099"
            placeholderText: "0"
        }
        Label { id: onTimeLaber
            visible: true
            text:  ""
        }
        Label { id: offTimeLabel
            visible: true
            text:  "OffTime"
        }
        TextField { id: offTime
            visible: true
            enabled: false
            implicitHeight: 21
            implicitWidth: 40
            textColor: "#000099"
            placeholderText: "1000"
        }
        Button { id: resetButton
            visible: true
            enabled: false
            Layout.preferredWidth: 40
            text: "Reset"
            onClicked: resetChanges();
        }
        Label { id: ringLabel
            visible: true
            text:  "Length"
        }
        TextField { id: ringTime
            visible: true
            enabled: true
            implicitHeight: 21
            implicitWidth: 40
            textColor: "#990000"
            text: "2000"
            Keys.onReturnPressed: applyChanges();
        }
        Button { id: applyButton
            visible: true
            enabled: false
            Layout.preferredWidth: 40
            text: "Apply"
            onClicked: applyChanges();
        }
        Label { id: section2
            visible: true
            Layout.columnSpan: 3
            Layout.topMargin: 8
            Layout.bottomMargin: 4
            text: "NOTE COLOURING"
        }
        Rectangle { id: setFret0
            width: 40; height: 20
            color: fingrgb[0]
            MouseArea {
                anchors.fill: parent
                onClicked: { setFingerColour(0) }
            }
        }
        Rectangle { id: setFret1
            width: 40; height: 20
            color: fingrgb[1]
            MouseArea {
                anchors.fill: parent
                onClicked: { setFingerColour(1) }
            }
        }
        Rectangle { id: setFret2
            width: 40; height: 20
            color: fingrgb[2]
            MouseArea {
                anchors.fill: parent
                onClicked: { setFingerColour(2) }
            }
        }
        Rectangle { id: setFret5
            width: 40; height: 20
            color: fingrgb[5]
            MouseArea {
                anchors.fill: parent
                onClicked: { setFingerColour(5) }
            }
        }
        Rectangle { id: setFret3
            width: 40; height: 20
            color: fingrgb[3]
            MouseArea {
                anchors.fill: parent
                onClicked: { setFingerColour(3) }
            }
        }
        Rectangle { id: setFret4
            width: 40; height: 20
            color: fingrgb[4]
            MouseArea {
                anchors.fill: parent
                onClicked: { setFingerColour(4) }
            }
        }
    } // GridLayout
    

    MessageDialog { id: inputError
        visible: false
        title: "Input error"
        text: "Not a number or out of range."
        onAccepted: { close(); get_notes() }
    }

    MessageDialog { id: versionError
        visible: false
        title: qsTr("Unsupported MuseScore Version")
        text: qsTr("This plugin requires MuseScore 3.3 to 3.9")
        onAccepted: Qt.quit();
   }

}
