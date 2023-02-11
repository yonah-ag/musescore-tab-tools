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
   description: "TAB Tools 1.4.2";
   requiresScore: true;
   version: "1.4.2";
   menuPath: "Plugins.TabTools";
   pluginType: "dock";
   width:  250;
   height: 670;
   
   property var inkElm8 : "#808080"; // element ink colour
   property var inkElmA : "#A0A0A0"; // element ink colour
   property var inkElmC : "#C0C0C0"; // element ink colour

// Voices 1 to 4 are numbered internally 0 to 3

   property var volVox1 : parseInt(voffVox1.text); // Volume voice 1 (or 255 to keep original)
   property var volVox2 : parseInt(voffVox2.text); // Volume voice 2
   property var volVox3 : parseInt(voffVox3.text); // Volume voice 3
   property var volVox4 : parseInt(voffVox4.text); // Volume voice 4

   property var visStem1 : chkVox1.checked; // Stem visibility
   property var visStem2 : chkVox2.checked;
   property var visStem3 : chkVox3.checked;
   property var visStem4 : chkVox4.checked;

   property var visRest1 : chkRest1.checked; // Rest visibility
   property var visRest2 : chkRest2.checked
   property var visRest3 : chkRest3.checked
   property var visRest4 : chkRest4.checked
   property var offRest1 : -4; // Y-Offset for voice 1 & 3 rests
   property var offRest2 : 4.5; // Y-Offset for voice 2 & 4 rests

   property var dynSymb  : [ "pp", "p" , "mp", "m", "mf", "f", "ff", "fff" ]
   property var dynMIDI  : [ 36, 48, 60, 72, 84, 96, 108, 120 ]
   property var ringTxt  : [ "1", "2", "3", "4", "5", "6", "7", "8" ]
   property var ringLen  : [ 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000 ]
   property var rgbElem : [ 20, 11, 42, 19, 25, 32, 33, 34 ]
   property var fingRGB  : [ "#202020", "#6900B4", "#0042c8", "#006e00", "#b900b9", "#808080", "#A0A0A0", "#C0C0C0" ]
   

   function inkElement(element, vox)  // vox = 1 or 2
   {
      if(element.type == Element.CHORD)
      {
         if(vox==1)
         {
            var volOff = volVox1;
            var visElm = visStem1;
         }
         else
         {
            var volOff = volVox2;
            var visElm = visStem2;
         }
         if(element.stem)
         {
            element.stem.color = inkElmA;
            element.stem.visible = visElm;
         }
         if(element.hook)
         {
            element.hook.color = inkElmA;
            element.hook.visible = visElm;
         }
         if(element.beam)
         {
            element.beam.color = inkElmA;
            element.beam.visible = visElm;
         }
         var note = element.notes[0];
         if(volOff < 128) note.veloOffset = volOff;
      }   
      else if (element.type == Element.REST)
      {
         element.autoplace = false;   
         element.color = inkElm8;
         if(vox == 1)
         {
            element.visible = visRest1;
            element.offsetY = offRest1;
         }
         else
         {
            element.visible = visRest2;
            element.offsetY = offRest2;
         }
      }
   }

   function tidyElement(element, vox) // vox = 3 or 4
   {
      if(element.type == Element.CHORD)
      {
         if(vox==3)
         {
            var visElm = visStem3;
            var volOff = volVox3;
         }
         else
         {
            var visElm = visStem4;
            var volOff = volVox4;
         }
         if(element.stem){
            element.stem.visible = visElm;
            element.stem.color = inkElmA;
         }
         if(element.hook){
            element.hook.visible = visElm;
            element.hook.color = inkElmA;
         }
         if(element.beam){
            element.beam.visible = visElm;
            element.beam.color = inkElmA;
         }
         var note = element.notes[0];
         note.small = true;
         if(volOff < 128) note.veloOffset = volOff;
      }
      else if (element.type == Element.REST)
      {
         element.visible = false;
         if(vox == 3)
         {
            element.visible = visRest3;
            element.offsetY = offRest1;
         }
         else
         {
            element.visible = visRest4;
            element.offsetY = offRest2;
         }
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
            var vox = voice+1;
            while (cursor.segment) {
               if (cursor.element) inkElement(cursor.element, vox);
               cursor.next();
            }
         }
      }

// Tidy Voices 3 and 4

      cursor = curScore.newCursor();
      cursor.rewind(0);
      for (var stave = staveBeg; stave <= staveEnd; ++stave)
      {
         for (var voice = 2; voice < 4; ++voice)
         {
            cursor.staffIdx = stave;
            cursor.voice = voice;
            cursor.rewind(0);
            cursor.staffIdx = stave;
            cursor.voice = voice;
            var vox = voice+1;
            while (cursor.segment)
            {
               if (cursor.element) tidyElement(cursor.element, vox);
               cursor.next();
            }
         }
      }

// Tidy Segments

      cursor.track = 0;
      cursor.filter = Segment.TimeSig | Segment.HeaderClef;
      cursor.rewind(0);
      do
      {
         cursor.segment.elementAt(0).color = inkElm8;
      }
      while(cursor.next());
      curScore.endCmd();
   }


// Let Ring

   function findNote()
   {
      var selection = curScore.selection;
      var elements = selection.elements;
      if (elements.length == 1)
      {
         var element = elements[0];
         if (element.type == 20)
         {
            var note = element;
            return note;
         }
      }
      return false;
   }

   function viewNote()
   {
      var note = findNote();
      if (!note) return;
      lblDyn2.text = "" + note.veloOffset;
      var events = note.playEvents;
      var pe0 = events[0];
      offTime.text = "" + pe0.len;
   }


   function setlength(ix)
   {
       var note = findNote();
       if (!note) return false;
       var mpe0 = note.playEvents[0];
       curScore.startCmd();
       mpe0.len = ringLen[ix];
       curScore.endCmd();
       offTime.text = ringLen[ix]
       return true;
   }

   function setDynamic(dvol)
   {
      var cursor = curScore.newCursor();
      cursor.rewind(1);
      var selection = curScore.selection;
      var elements = selection.elements;
      if (elements.length == 1)
      {
         var element = elements[0];
         if (element.type == 20)
         {
            curScore.startCmd();
            element.veloType = 1;
            element.veloOffset = dynMIDI[dvol];
            curScore.endCmd();
            cursor.rewind(1);
         }
      }
   }
   
   function setColour(fing)
   {
      var cursor = curScore.newCursor();
      cursor.rewind(1);
      var selection = curScore.selection;
      var elements = selection.elements;
      if (elements.length == 1)
      {
         var element = elements[0];
         if(rgbElem.indexOf(element.type) >= 0)
         {
            curScore.startCmd();
            element.color = fingRGB[fing];
            curScore.endCmd();
            cursor.rewind(1);
         }
         else
            console.log(element.type);
      }
   }

// Event Handlers
   
   onScoreStateChanged:
   {
      viewNote();
   }

   onRun:
   {
      btnRing0.text = ringTxt[0];
      btnRing1.text = ringTxt[1];
      btnRing2.text = ringTxt[2];
      btnRing3.text = ringTxt[3];
      btnRing4.text = ringTxt[4];
      btnRing5.text = ringTxt[5];
      btnRing6.text = ringTxt[6];
      btnRing7.text = ringTxt[7];
      
      btnDyna0.text = dynSymb[0] + dynMIDI[0];
      btnDyna1.text = dynSymb[1] + dynMIDI[1];
      btnDyna2.text = dynSymb[2] + dynMIDI[2];
      btnDyna3.text = dynSymb[3] + dynMIDI[3];
      btnDyna4.text = dynSymb[4] + dynMIDI[4];
      btnDyna5.text = dynSymb[5] + dynMIDI[5];
      btnDyna6.text = dynSymb[6] + dynMIDI[6];
      btnDyna7.text = dynSymb[7] + dynMIDI[7];
   }


// ------------------
// | User Interface |
// ------------------

      GridLayout { id: 'mainLayout'

      anchors.fill: parent
      anchors.margins: 10
      columns: 4
      columnSpacing: 2
      rowSpacing: 2

// Tidy

      Button { id: btnTidy
         visible: true
         enabled: true
         text: "Tidy"
         Layout.preferredWidth: 40
         onClicked: tidyScore();
      }
      Label { id:lblVov; text: " Velo"; Layout.topMargin: 5 }
      Label { id:lblVos; text: "Stems"; Layout.topMargin: 5 }
      Label { id:lblVor; text: "Rests"; Layout.topMargin: 5 }

      Label { id: lblVox1; Layout.leftMargin: 15; text: "1" }
      TextField { id: voffVox1
         implicitHeight: 21; implicitWidth: 40
         textColor: "#000000"; text: "255"
      }
      CheckBox {id: chkVox1; Layout.leftMargin: 10; checked: true; text: "" }
      CheckBox {id: chkRest1; Layout.leftMargin: 10; checked: true; text: "" }
      
      Label { id: lblVox2; Layout.leftMargin: 15; text: "2" }
      TextField { id: voffVox2
         implicitHeight: 21; implicitWidth: 40
         textColor: "#000000"; text: "255"
      }
      CheckBox {id: chkVox2; Layout.leftMargin: 10; checked: true; text: "" }
      CheckBox {id: chkRest2; Layout.leftMargin: 10; checked: true; text: "" }

      Label { id: lblVox3; Layout.leftMargin: 15; text: "3" }
      TextField { id: voffVox3
         implicitHeight: 21; implicitWidth: 40
         textColor: "#000000"; text: "255"
      }
      CheckBox {id: chkVox3; Layout.leftMargin: 10; checked: false; text: "" }
      CheckBox {id: chkRest3; Layout.leftMargin: 10; checked: false; text: "" }

      Label { id: lblVox4; Layout.leftMargin: 15; text: "4" }
      TextField { id: voffVox4
         implicitHeight: 21; implicitWidth: 40
         textColor: "#000000"; text: "255"
      }
      CheckBox {id: chkVox4; Layout.leftMargin: 10; checked: false; text: ""       }
      CheckBox {id: chkRest4; Layout.leftMargin: 10; checked: false; text: "" }
      
// Dynamics

      Label { id:lblDyn1; text: " Dynamics"; Layout.topMargin: 10; Layout.columnSpan: 2 }
      Label { id:lblDyn2; text: "0"; Layout.topMargin: 10; color:"#000099" }
      Label { id:lblDynX; text: " "; Layout.topMargin: 10 }

      Button { id: btnDyna0
         visible: true; enabled: true
         Layout.preferredWidth: 40; Layout.topMargin: 5
         text: "#"
         onClicked: { setDynamic(0) }
      }       
      Button { id: btnDyna1
         visible: true; enabled: true
         Layout.preferredWidth: 40; Layout.topMargin: 5
         text: "#"
         onClicked: { setDynamic(1) }
      }       
      Button { id: btnDyna2
         visible: true; enabled: true
         Layout.preferredWidth: 40; Layout.topMargin: 5
         text: "#"
         onClicked: { setDynamic(2) }
      }       
      Button { id: btnDyna3
         visible: true; enabled: true
         Layout.preferredWidth: 40; Layout.topMargin: 5
         text: "#"
         onClicked: { setDynamic(3) }
      }       
      Button { id: btnDyna4
         visible: true; enabled: true
         Layout.preferredWidth: 40
         text: "#"
         onClicked: { setDynamic(4) }
      }       
      Button { id: btnDyna5
         visible: true; enabled: true
         Layout.preferredWidth: 40
         text: "#"
         onClicked: { setDynamic(5) }
      }       
      Button { id: btnDyna6
         visible: true; enabled: true
         Layout.preferredWidth: 40
         text: "#"
         onClicked: { setDynamic(6) }
      }       
      Button { id: btnDyna7
         visible: true; enabled: true
         Layout.preferredWidth: 40
         text: "#"
         onClicked: { setDynamic(7) }
      }       

// Let Ring

      Label { id:lblRing1; text: " Let Ring"; Layout.topMargin: 10; Layout.columnSpan: 2 }
      Label { id: offTime; Layout.topMargin: 10; color: "#000099"; text: "1000" }
      Label { id:lblRingX; text: " "; Layout.topMargin: 10 }

      Button { id: btnRing0
         visible: true; enabled: true
         Layout.preferredWidth: 40; Layout.topMargin: 5
         text: "#"
         onClicked: { setlength(0) }
      }       
      Button { id: btnRing1
         visible: true; enabled: true
         Layout.preferredWidth: 40; Layout.topMargin: 5
         text: "#"
         onClicked: { setlength(1) }
      }       
      Button { id: btnRing2
         visible: true; enabled: true
         Layout.preferredWidth: 40; Layout.topMargin: 5
         text: "#"
         onClicked: { setlength(2) }
      }       
      Button { id: btnRing3
         visible: true; enabled: true
         Layout.preferredWidth: 40; Layout.topMargin: 5
         text: "#"
         onClicked: { setlength(3) }
      }
      Button { id: btnRing4
         visible: true; enabled: true
         Layout.preferredWidth: 40; Layout.topMargin: 0
         text: "#"
         onClicked: { setlength(4) }
      }       
      Button { id: btnRing5
         visible: true; enabled: true
         Layout.preferredWidth: 40; Layout.topMargin: 0
         text: "#"
         onClicked: { setlength(5) }
      }       
      Button { id: btnRing6
         visible: true; enabled: true
         Layout.preferredWidth: 40; Layout.topMargin: 0
         text: "#"
         onClicked: { setlength(6) }
      }       
      Button { id: btnRing7
         visible: true; enabled: true
         Layout.preferredWidth: 40; Layout.topMargin: 0
         text: "#"
         onClicked: { setlength(7) }
      }
      
// Note Colouring

      Rectangle { id: setFret0
         width: 40; height: 25
         Layout.topMargin: 10;
         color: fingRGB[0]
         MouseArea {
             anchors.fill: parent
             onClicked: { setColour(0) }
         }
      }
      Rectangle { id: setFret1
         width: 40; height: 25
         Layout.topMargin: 10;
         color: fingRGB[1]
         MouseArea {
             anchors.fill: parent
             onClicked: { setColour(1) }
         }
      }
      Rectangle { id: setFret2
         width: 40; height: 25
         Layout.topMargin: 10;
         color: fingRGB[2]
         MouseArea {
            anchors.fill: parent
            onClicked: { setColour(2) }
         }
      }
      Rectangle { id: setFret3
         width: 40; height: 25
         Layout.topMargin: 10;
         color: fingRGB[3]
         MouseArea {
            anchors.fill: parent
            onClicked: { setColour(3) }
         }
      }
      Rectangle { id: setFret4
         width: 40; height: 25
         color: fingRGB[4]
         MouseArea {
            anchors.fill: parent
            onClicked: { setColour(4) }
         }
      }
      Rectangle { id: setFret5
         width: 40; height: 25
         color: fingRGB[5]
         MouseArea {
            anchors.fill: parent
            onClicked: { setColour(5) }
         }
      }
      Rectangle { id: setFret6
         width: 40; height: 25
         color: fingRGB[6]
         MouseArea {
            anchors.fill: parent
            onClicked: { setColour(6) }
         }
      }
      Rectangle { id: setFret7
         width: 40; height: 25
         color: fingRGB[7]
         MouseArea {
            anchors.fill: parent
            onClicked: { setColour(7) }
         }
      }
    } // GridLayout
}