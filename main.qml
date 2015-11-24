import QtQuick 2.5
import QtQuick.Window 2.2

import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1

Window {
    id: window
    visible: true
    title: "PID"
    width: 320
    height: 170
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

        MouseArea {
            // fill panel with a mouse area to deactivate fields
            // and submit changes when clicked
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: pid_panel.forceActiveFocus()
        }

        Image {
            anchors.fill: parent
            source: "pid-bg.svg"
        }

        SpinBox {
            id: target_spin
            x: 10
            y: 26
            width: 70
            height: 20
            suffix: " V"
            maximumValue: 10
            stepSize: 0.01
            decimals: 3

            value: pid_control.target
            onEditingFinished: {
                pid_control.target = value
            }
        }

        TextField {
            id: input_field
            x: 15
            y: 123
            width: 60
            height: 20
            horizontalAlignment: Qt.AlignHCenter
            text: pid_control.input.toFixed(3) + " V"
            readOnly: true
        }

        SpinBox {
            id: output_spin
            x: 239
            y: 75
            width: 70
            height: 20
            suffix: " %"
            maximumValue: 100
            stepSize: 1
            decimals: 2

            value: pid_control.output
            onEditingFinished: {
                pid_control.output = value
            }
        }

        SpinBox {
            id: kp_spin
            x: 116
            y: 25
            width: 55
            height: 20
            stepSize: 0.02
            decimals: 2

            value: pid_control.kp
            onEditingFinished: {
                pid_control.kp = value
            }
        }

        SpinBox {
            id: ki_spin
            x: 116
            y: 75
            width: 55
            height: 20
            stepSize: 0.02
            decimals: 2

            value: pid_control.ki
            onEditingFinished: {
                pid_control.ki = value
            }
        }

        SpinBox {
            id: kd_spin
            x: 116
            y: 120
            width: 55
            height: 20
            stepSize: 0.02
            decimals: 2

            value: pid_control.kd
            onEditingFinished: {
                pid_control.kd = value
            }
        }

        CheckBox {
            id: inverse_check
            x: 78
            y: 68
            onClicked: {
                pid_control.inverse = checked;
            }
        }


        Switch {
            id: pid_switch
            x: 264
            y: 8
            checked: pid_control.running

            onClicked: {
                if (checked) {
                    pid_control.start()
                } else {
                    pid_control.running = false
                }
            }


        }

        Button {
            id: settings_button
            x: 242
            y: 8
            width: 16
            height: 16
            text: "\uf013"
            style: ButtonStyle {
                label: Text {
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "FontAwesome"
                    font.pointSize: 10
                    color: pid_control.running ? "#909090" :  "#303030"
                    text: control.text
                }
            }
            enabled: !pid_control.running
            onClicked: pid_control.unconfigure()
        }
    } // PID Panel

    Rectangle {
        id: settings_panel
        color: "#c0c0c0"
        width: parent.width
        height: parent.height
        z: 2

        state: pid_control.configured? "off" : "on"
        states: [
            State {
                name: "on"
                PropertyChanges {target: settings_panel; y: 0}
            },
            State {
                name: "off"
                PropertyChanges {target: settings_panel; y: -settings_panel.height}
            }
        ]

        transitions: Transition {
            NumberAnimation {
                properties: "y"
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
                text: "/dev2/ai0"
                onAccepted: ok_button.configure()
            }

            Text { text: "Sample Rate: "; Layout.alignment: Qt.AlignRight }
            TextField {
                id: rate_field
                text: "100"
                validator: IntValidator {bottom: 1; top: 10000}
                onAccepted: ok_button.configure()
            }

            Text { text: "Max Volt: "; Layout.alignment: Qt.AlignRight }
            TextField {
                id: maxv_field
                text: "2"
                validator: DoubleValidator {
                    decimals: 1
                    bottom: 0
                    top: 10.
                }
                onAccepted: ok_button.configure()
            }

            Text { text: "lasernet: "; Layout.alignment: Qt.AlignRight }
            TextField {
                id: lasernet_field
                text: "farfetchd"
                onAccepted: ok_button.configure()
            }

            Item {width: 1}
            Button {
                id: ok_button
                text: "OK"
                Layout.alignment: Qt.AlignRight

                function configure() {
                    // take focus away from text fields causing editingFinished signals
                    pid_panel.forceActiveFocus()
    //                    settings_panel.state = "off"
                    pid_control.configure(
                                channel_field.text,
                                rate_field.text,
                                maxv_field.text,
                                lasernet_field.text);
                }

                onClicked: configure()
            }
        } // Settings Grid Layout
    } // Settings Panel



}
