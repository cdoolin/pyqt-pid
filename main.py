#
# pyqt-pid
#
# a simple pid controller with UI written with qt/qml
#
# Callum Doolin (doolin@uablerta.ca) 2015

import sys

from PyQt5.QtCore import qDebug, QUrl, QObject, pyqtProperty, pyqtSignal, pyqtSlot, QThread
from PyQt5.QtGui import QGuiApplication
from PyQt5.QtQml import QQmlApplicationEngine, qmlRegisterType


from PyDAQmx import *
import numpy

# helper function to create simple properties on QObjects
# which read and write to a _propertyname variable on the class
#
def simpleProperty(type, name, notify, readonly=False):
    _name = "_" + name
    def getter(obj):
        return getattr(obj, _name)

    def setter(obj, value):
        if getattr(obj, _name) != value:
            qDebug("set %s %s" % (_name, value))
            setattr(obj, _name, value)
            notify.__get__(obj).emit()

    fset = setter
    if readonly:
        fset = None

    return pyqtProperty(type, fget=getter, fset=fset, notify=notify)




class DaqControl(QObject):
    def __init__(self, parent=None):
        super(DaqControl, self).__init__(parent)

        self._channel = "/dev2/ai0"
        self._maxv = 10.
        self._rate = 100.
        self._downsample = 10
        self._avg = 10.
        self._running = False

        # nidaq stuff
        self.task = Task()
        self.read = int32()
        self.buff = numpy.zeros(1024)

        # signals
        self.start.connect(self._start)


    channelChanged = pyqtSignal()
    channel = simpleProperty('QString', 'channel', channelChanged)

    maxvChanged = pyqtSignal()
    maxv = simpleProperty(float, 'maxv', maxvChanged)

    rateChanged = pyqtSignal()
    rate = simpleProperty(int, 'rate', rateChanged)

    downsampleChanged = pyqtSignal()
    downsample = simpleProperty(int, 'running', downsampleChanged)

    runningChanged = pyqtSignal()
    running = simpleProperty(bool, 'running', runningChanged)


    def configure_task(self):
        self.task.ClearTask()
        self.task = Task()
        qDebug(self.channel)
        self.task.CreateAIVoltageChan(self.channel, "",  # no custom name
            DAQmx_Val_RSE,        # measure w/ respect to ground
            -self.maxv, self.maxv, # v lims
            DAQmx_Val_Volts, None) # volts, not custom scale

        self.task.CfgSampClkTiming("", self.rate, DAQmx_Val_Rising, # config onboard clock
            DAQmx_Val_ContSamps, 1024)  # continuos & buff size

    def get_volt(self):
        self.task.ReadAnalogF64(int(self.downsample), 10.0, # nsamps, timeout
            DAQmx_Val_GroupByChannel, self.buff, len(self.buff),
            byref(self.read), None)
        return numpy.mean(self.buff[:self.read.value])

    # call this signal from QML instead of slot to make
    # threading work properly.
    start = pyqtSignal()

    @pyqtSlot()
    def _start(self):
        self.configure_task()
        self.task.StartTask()
        self.running = True
        i = 0
        while self._running:
            volt = self.get_volt()

            if i % 5 is 0:
                qDebug("%.3f V" % volt)

        self.task.StopTask()
        qDebug("stopped")



app = QGuiApplication(sys.argv)
engine = QQmlApplicationEngine()

ctx = engine.rootContext()
# create an instance to be accesable from QML
daq_control = DaqControl()

ctx.setContextProperty("daq_control", daq_control)

engine.load(QUrl("main.qml"))
thread = QThread()
daq_control.moveToThread(thread)
thread.start()





if __name__ == '__main__':
    app.exec_()
