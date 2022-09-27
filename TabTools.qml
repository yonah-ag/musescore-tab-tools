/* Copyright © 2022 yonah_ag
 *
 *  This program is free software; you can redistribute it or modify it under
 *  the terms of the GNU General Public License version 3 as published by the
 *  Free Software Foundation and appearing in the accompanying LICENSE file.
 *
 *  Description
 *  -----------
 *  Tidy TAB score by tidying rests, stems, hooks and beams
 *  Set element colour in voices 1 & 2
 *  Set vertical position of rests in voices 1 & 2
 *  Hide element in voices 3 & 4
 *
 */

import MuseScore 3.0
import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1

MuseScore 
{
   description: "TAB Tools";
   requiresScore: true;
   version: "1.0.3";
   menuPath: "Plugins.TabTools";
   pluginType: "dock";
   width:  240;
   height: 240;
   
   property var inkElmA : "#A8A8A8"; // element ink colour
   property var inkElmB : "#808080"; // element ink colour
   property var offRest0 : -4; // Offset for voice 1 rests
   property var offRest1 : 4.5; // Offset for voice 2 rests
   property var fingrgb : [ "#202020", "#6900B4", "#0042c8", "#006e00", "#b900b9", "#808080", "#A8A8A8", "#C0C0C0" ]
   
   onScoreStateChanged:
   {
      viewNote();
   }

// ---------------

   function inkElement(element, voice)
   {
      if(element.type == Element.CHORD) {
         if(element.stem) element.stem.color = inkElmA;
         if(element.hook) element.hook.color = inkElmA;
         if(element.beam) element.beam.color = inkElmA;
         var tie = element.notes[0].tieForward;
         if (tie) {
            tie.color = inkElmB;
            tie.lineType = 2;
         }
      }
      else if (element.type == Element.REST) {
         if(element.dots) console.log(element.dots.length);
         element.autoplace = false;   
         element.color = inkElmA;
         if(voice == 0)
            element.offsetY = offRest0
         else
            element.offsetY = offRest1;
      }
   }

   function tidyElement(element)
   {
      if(element.type == Element.CHORD) {
         if(element.stem) element.stem.visible = false;
         if(element.hook) element.hook.visible = false;
         if(element.beam) element.beam.visible = false;
      }
      else if (element.type == Element.REST) {
          element.visible = false;
      }
   }

   function tidyScore()
   {
      var staveBeg;
      var staveEnd;
      var tickEnd;
      var toEOF;
      var cursor = curScore.newCursor();

      staveBeg = 0;
      staveEnd = curScore.nstaves - 1;

// Tidy Voices 1 and 2

      curScore.startCmd();
      cursor.rewind(0);
      for (var stave = staveBeg; stave <= staveEnd; ++stave) {
         for (var voice = 0; voice < 2; ++voice) {
            cursor.staffIdx = stave;
            cursor.voice = voice;
            cursor.rewind(0);
            cursor.staffIdx = stave;
            cursor.voice = voice;
            while (cursor.segment) {
               if (cursor.element) inkElement(cursor.element, voice);
               cursor.next();
            }
         }
      }

// Tidy Voices 3 and 4

      cursor = curScore.newCursor();
      cursor.rewind(0);
      for (var stave = staveBeg; stave <= staveEnd; ++stave) {
         for (var voice = 2; voice < 4; ++voice) {
            cursor.staffIdx = stave;
            cursor.voice = voice;
            cursor.rewind(0);
            cursor.staffIdx = stave;
            cursor.voice = voice;
            while (cursor.segment) {
               if (cursor.element) tidyElement(cursor.element);
               cursor.next();
            }
         }
      }

// Tidy Segments

      cursor.track = 0;
      cursor.filter = Segment.TimeSig | Segment.HeaderClef;
      cursor.rewind(0);
      do {
         cursor.segment.elementAt(0).color = inkElmB;
      }
      while(cursor.next());
      curScore.endCmd();
   }


// Let Ring

   function find_note()
   {
      var selection = curScore.selection;
      var elements = selection.elements;
      if (elements.length == 1)
      {
         var element = elements[0];
         if (element.type == 20) {
            var note = element;
            return note;
         }
      }
      return false;
   }

   function viewNote()
   {
      var note = find_note();
      if (!note) return;
      var events = note.playEvents;
      var pe0 = events[0];
      onTime.text = "" + pe0.ontime;
      offTime.text = "" + (pe0.ontime + pe0.len);
   }


   function articulate()
   {
       var note = find_note();
       if (!note) return false;
       var on_time = parseInt(onTime.text);
       var off_time = parseInt(ringTime.text);
       var mpe0 = note.playEvents[0];
       curScore.startCmd();
       mpe0.len = off_time - mpe0.ontime;
       curScore.endCmd();
       offTime.text = ringTime.text;
       return true;
   }

   function setFingerColour(fing)
   {
      var cursor = curScore.newCursor();
      cursor.rewind(1);
      var selection = curScore.selection;
      var elements = selection.elements;
      if (elements.length == 1)
      {
         var element = elements[0];
         if (element.type == 20 || element.type == 11 || element.type == 42) {
            curScore.startCmd();
            element.color = fingrgb[fing];
            curScore.endCmd();
            cursor.rewind(1);
         }
         else
            console.log(element.type);
      }
   }

   GridLayout { id: 'mainLayout'

      anchors.fill: parent
      anchors.margins: 10
      columns: 4
      columnSpacing: 2
      rowSpacing: 2

// Tidy

      Label { id: lblTidy
         visible: true
         Layout.columnSpan: 1
         Layout.topMargin: 0
         Layout.bottomMargin: 4
         text: "Tidy Tab"
      }
      Button { id: btnTidy
         visible: true
         enabled: true
         text: "Tidy"
         Layout.preferredWidth: 50
         onClicked: tidyScore();
      }
      Label { id: spcTidy1
         visible: true
         text:  ""
      }
      Label { id: spcTidy2
         visible: true
         text:  ""
      }

// Let Ring

      Label { id: section1
         visible: true
         Layout.columnSpan: 1
         text: "Let Ring"
      }
      Button { id: applyButton
         visible: true
         enabled: true
         Layout.preferredWidth: 50
         text: "Apply"
         onClicked: articulate();
      }
      Label { id: ringLabel
         visible: true
         text:  "  Length"
      }
      TextField { id: ringTime
         visible: true
         enabled: true
         implicitHeight: 21
         implicitWidth: 50
         textColor: "#990000"
         text: "2000"
      }
      Label { id: onTimeLabel
         visible: true
         text:  "OnTime"
      }
      TextField { id: onTime
         visible: true
         enabled: false
         implicitHeight: 21
         implicitWidth: 50
         textColor: "#000099"
         placeholderText: "0"
      }
      Label { id: offTimeLabel
         visible: true
         text:  "  OffTime"
      }
      TextField { id: offTime
         visible: true
         enabled: false
         implicitHeight: 21
         implicitWidth: 50
         textColor: "#000099"
         placeholderText: "1000"
      }
      
// Note Colouring

      Label { id: section2
         visible: true
         Layout.columnSpan: 4
         Layout.topMargin: 8
         Layout.bottomMargin: 0
         text: "Note Colouring"
      }
      Rectangle { id: setFret1
         width: 50; height: 25
         color: fingrgb[1]
         MouseArea {
             anchors.fill: parent
             onClicked: { setFingerColour(1) }
         }
      }
      Rectangle { id: setFret2
         width: 50; height: 25
         color: fingrgb[2]
         MouseArea {
            anchors.fill: parent
            onClicked: { setFingerColour(2) }
         }
      }
      Rectangle { id: setFret3
         width: 50; height: 25
         color: fingrgb[3]
         MouseArea {
            anchors.fill: parent
            onClicked: { setFingerColour(3) }
         }
      }
      Rectangle { id: setFret4
         width: 50; height: 25
         color: fingrgb[4]
         MouseArea {
            anchors.fill: parent
            onClicked: { setFingerColour(4) }
         }
      }
      Rectangle { id: setFret0
         width: 50; height: 25
         color: fingrgb[0]
         MouseArea {
             anchors.fill: parent
             onClicked: { setFingerColour(0) }
         }
      }
      Rectangle { id: setFret5
         width: 50; height: 25
         color: fingrgb[5]
         MouseArea {
            anchors.fill: parent
            onClicked: { setFingerColour(5) }
         }
      }
      Rectangle { id: setFret6
         width: 50; height: 25
         color: fingrgb[6]
         MouseArea {
            anchors.fill: parent
            onClicked: { setFingerColour(6) }
         }
      }
      Rectangle { id: setFret7
         width: 50; height: 25
         color: fingrgb[7]
         MouseArea {
            anchors.fill: parent
            onClicked: { setFingerColour(7) }
         }
      }
    } // GridLayout
}
