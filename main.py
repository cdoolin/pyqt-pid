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


from labdrivers import websocks

#
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


#
# The main class that interfaces with the QML UI.
# An instance is created of it accessible from QML as pid_control
#

class PidControl(QThread):
    def __init__(self, parent=None):
        super(PidControl, self).__init__(parent)


        self.laser = None

        # PID settings
        self._running = False
        self._kp = 0.
        self._ki = 0.2
        self._kd = 0.

        self._target = 0.
        self._input = 0.
        self._output = 0.
        self._inverse = False

        self._downsample = 10
        self.error_sum = 0
        self.prev_error = 0

        # nidaq stuff
        self.task = None
        self.read = int32()
        self.buff = numpy.zeros(1024)

        # signals
#        self.start.connect(self._start_pid)

    # pid settings
    runningChanged = pyqtSignal()
    running = simpleProperty(bool, 'running', runningChanged)

    kpChanged = pyqtSignal()
    kp = simpleProperty(float, 'kp', kpChanged)
    kiChanged = pyqtSignal()
    ki = simpleProperty(float, 'ki', kiChanged)
    kdChanged = pyqtSignal()
    kd = simpleProperty(float, 'kd', kdChanged)

    targetChanged = pyqtSignal()
    target = simpleProperty(float, 'target', targetChanged)

    inputChanged = pyqtSignal()
    @pyqtProperty(float, notify=inputChanged)
    def input(self):
        return self._input

    outputChanged = pyqtSignal()
#    output = simpleProperty(float, 'output', targetChanged)
    @pyqtProperty(float, notify=outputChanged)
    def output(self):
        if self.laser is not None:
            return self.laser.get_volt()
        else:
            return 0

    @output.setter
    def output(self, value):
        if self.laser is not None:
            self.laser.set_volt(float(value))
            self.outputChanged.emit()

        qDebug("%f" % value)

    inverseChanged = pyqtSignal()
    inverse = simpleProperty(bool, 'inverse', inverseChanged)


    configuredChanged = pyqtSignal()
    @pyqtProperty(bool, notify=configuredChanged)
    def configured(self):
        return self.laser is not None and self.task is not None


    # finished qt properties

    @pyqtSlot('QString', float, float, 'QString')
    def configure(self, channel, rate, maxv, server):
        try:
            self.laser = websocks.LaserClient(server=server)
        except:
            self.laser = None

        if self.task is not None:
            self.task.ClearTask()
        self.task = Task()
        try:
            self.task.CreateAIVoltageChan(channel, "",  # no custom name
                DAQmx_Val_RSE,        # measure w/ respect to ground
                -maxv, maxv, # v lims
                DAQmx_Val_Volts, None) # volts, not custom scale

            self.task.CfgSampClkTiming("", rate, DAQmx_Val_Rising, # config onboard clock
                DAQmx_Val_ContSamps, 1024)  # continuos & buff size
        except:
            self.task.ClearTask()
            self.task = None

        self.dT = self._downsample / rate
        self.configuredChanged.emit()


    @pyqtSlot()
    def unconfigure(self):
        self.laser = None
        self.configuredChanged.emit()


    def get_volt(self):
        self.task.ReadAnalogF64(int(self._downsample), 10.0, # nsamps, timeout
            DAQmx_Val_GroupByChannel, self.buff, len(self.buff),
            byref(self.read), None)
        return numpy.mean(self.buff[:self.read.value])


    # call this signal from QML instead of slot to make
    # threading work properly.
#    start = pyqtSignal()

#    @pyqtSlot()
    def run(self):
        self.task.StartTask()
        self.running = True
        i = 0
        while self._running:
            self._input = self.get_volt()
            self.inputChanged.emit()

#            if i % 5 is 0:
#                qDebug("%.3f V" % volt)

        self.task.StopTask()
        qDebug("stopped")

    @pyqtSlot()
    def _start_pid(self):
        self.task.start()
        self.running = True
        i = 0
        while self._running:
            self._input = self.get_volt()
            error = (self._volt - self._target)
            if self._inverse:
                error = -error

            self._output = self.step(error)
            if self._output > 100.:
                self._output = 100.
                self.running = False

            if self._output < 0.:
                self._output = 0.
                self.running = False

            self.laser.set_volt(self._output)

            if i % 5 is 0:
                self.inputChanged.emit()
                self.outputChanged.emit()
                qDebug("%.3f V" % volt)

        self.task.StopTask()
        qDebug("stopped")
        self.inputChanged.emit()
        self.outputChanged.emit()

    def step(self, error):
        # compute ki in integral incase it's time dependant
        dT = self._downsample / self._rate
        self.error_sum += self._ki * error * dT
        dedt = (error - self.prev_error) / dT

        u = self.kp * error + self.error_sum + self.kd * dedt
        return u



app = QGuiApplication(sys.argv)
engine = QQmlApplicationEngine()

ctx = engine.rootContext()
# create an instance to be accesable from QML
pid_control = PidControl()
ctx.setContextProperty("pid_control", pid_control)

engine.load(QUrl("main.qml"))

# move pid_control to new thread so it runs asynchronously to the ui
#thread = QThread()
#pid_control.moveToThread(thread)
#thread.start()


if __name__ == '__main__':
    app.exec_()
