import QtQuick 2.5
import QtQuick.Window 2.2

import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1

Window {
    id: window
    visible: true
    title: "PID"
    width: 300
    height: 200
    minimumWidth: width
    minimumHeight: height
    maximumWidth: width
    maximumHeight: height

    FontLoader { source: "fontawesome-webfont.ttf" }


    Rectangle {
        id: pid_panel
        width: parent.width
        height: parent.height
        anchors.verticalCenterOffset: 0
        anchors.horizontalCenterOffset: 0
        anchors.centerIn: parent
        //        color: "red"

        Image {
            anchors.fill: parent
            source: "pid-bg.svg"

            SpinBox {
                id: target_box
                x: 14
                y: 26
                width: 60
                height: 20
                maximumValue: 10
                stepSize: 0.01
                value: 0.5
                decimals: 3
            }

            TextField {
                id: input_field
                x: 14
                y: 118
                width: 60
                height: 20
                text: "0"
                readOnly: true
            }

            SpinBox {
                id: output_box
                x: 230
                y: 75
                width: 60
                height: 20
                maximumValue: 100
                stepSize: 1
                decimals: 2
            }

            TextField {
                id: textField1
                x: 125
                y: 24
                width: 40
                text: "0"
                placeholderText: qsTr("Text Field")
            }

            TextField {
                id: textField2
                x: 125
                y: 75
                width: 40
                text: "0.2"
                placeholderText: qsTr("Text Field")
            }

            TextField {
                id: textField3
                x: 125
                y: 120
                width: 40
                text: "0"
                placeholderText: qsTr("Text Field")
            }
        }

        Switch {
            id: pid_switch
            x: 244
            y: 10
            checked: false
        }

        Button {
            id: transfer_button
            x: 64
            y: 161
            width: 20
            height: 20
            text: "\uf061"
            style: ButtonStyle {
                label: Text {
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "FontAwesome"
                    font.pointSize: 10
                    color: "#303030"
                    text: control.text
                }
            }
        }

        Button {
            id: settings_button
            x: 222
            y: 10
            width: 16
            height: 16
            text: "\uf013"
            style: ButtonStyle {
                label: Text {
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "FontAwesome"
                    font.pointSize: 10
                    color: "#303030"
                    text: control.text
                }
            }
            enabled: !daq_control.running
            onClicked: settings_panel.state = "on"
        }

        Switch {
            id: daq_switch
            x: 10
            y: 163
            checked: false

            signal start()

            onClicked: {
                console.log(checked)
                if (checked && !daq_control.running) {
                    daq_control.start();
                }
                else
                    daq_control.running = false
            }
        }



    } // PID Panel

    Rectangle {
        id: settings_panel
        color: "#adadad"
        width: parent.width
        height: parent.height
        z: -2

        state: "off"
        states: [
            State {
                name: "on"
                PropertyChanges {target: settings_panel; x: 0}
            },
            State {
                name: "off"
                PropertyChanges {target: settings_panel; x: settings_panel.width}
            }
        ]

        transitions: Transition {
            NumberAnimation {
                properties: "x"
                easing.type: Easing.InOutQuad
                duration: 500
            }
        }

        GridLayout {
            //        anchors.left: parent.left
            //        anchors.right: parent.right
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            columns: 2

            Text { text: "Channel: "; Layout.alignment: Qt.AlignRight }
            TextField {
                id: channel_field
                text: daq_control.channel
                onEditingFinished: daq_control.channel = text
            }

            Text { text: "Sample Rate: "; Layout.alignment: Qt.AlignRight }
            TextField {
                id: rate_field
                text: daq_control.rate
                validator: IntValidator {bottom: 1; top: 10000}
                onEditingFinished: daq_control.rate = text
            }

            Text { text: "Max Volt: "; Layout.alignment: Qt.AlignRight }
            TextField {
                id: maxv_field
                text: daq_control.maxv
                validator: DoubleValidator {
                    decimals: 1
                    bottom: 0
                    top: 10.
                }
                onEditingFinished: daq_control.maxv = text
            }

            Text { text: "lasernet: "; Layout.alignment: Qt.AlignRight }
            TextField {
                id: lasernet_field
                text: "localhost"
            }

            Item {width: 1}

            Button {
                text: "OK"
                Layout.alignment: Qt.AlignRight

                onClicked: {
                    // take focus away from text fields causing editingFinished signals
                    pid_panel.forceActiveFocus()
                    settings_panel.state = "off"
                }
            }
        } // Settings Grid Layout
    } // Settings Panel



}
