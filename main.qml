import QtQuick 2.5
import QtQuick.Window 2.2

import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1

Window {
    id: window
    visible: true
    title: "PID"
    minimumWidth: 200
    minimumHeight: 200
    maximumWidth: 200
    maximumHeight: 200

    FontLoader { source: "fontawesome-webfont.ttf" }


    Rectangle {
        id: pid_panel
        width: 200
        height: 200
        anchors.verticalCenterOffset: 0
        anchors.horizontalCenterOffset: 0
        anchors.centerIn: parent
//        color: "red"

        Switch {
            id: pid_switch
            x: 8
            y: 14
            checked: false
        }

        SpinBox {
            id: target_box
            x: 125
            y: 92
            width: 67
            height: 20
            maximumValue: 10
            stepSize: 0.01
            value: 0.5
            decimals: 3
        }

        Label {
            x: 8
            y: 72
            text: qsTr("Input")
        }

        TextField {
            id: input_field
            x: 8
            y: 92
            width: 80
            height: 20
            text: "0"
            readOnly: true
        }

        Label {
            x: 125
            y: 72
            text: qsTr("Target")
        }

        Button {
            id: transfer_button
            x: 95
            y: 92
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
            x: 168
            y: 10
            width: 24
            height: 24
            text: "\uf013"
            style: ButtonStyle {
                label: Text {
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "FontAwesome"
                    font.pointSize: 14
                    color: "#303030"
                    text: control.text
                }
            }
            enabled: !daq_control.running
            onClicked: settings_panel.state = "on"
        }

        Switch {
            id: daq_switch
            x: 40
            y: 71
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



        Label {
            x: 67
            y: 138
            text: qsTr("Output")
        }
        SpinBox {
            id: output_box
            x: 67
            y: 158
            width: 67
            height: 20
            maximumValue: 100
            stepSize: 1
            decimals: 2
        }

    } // PID Panel

    Rectangle {
        id: settings_panel
        color: "#adadad"
        width: parent.width
        height: parent.height
        z: 2

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
