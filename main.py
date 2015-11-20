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


import time
class DaqWorker(QObject):

    done = pyqtSignal()

    @pyqtSlot()
    def work(self):
        qDebug("begin work")
        time.sleep(10)
        qDebug("done work")
        self.done.emit()





class DaqControl(QObject):
    def __init__(self, parent=None):
        super().__init__(parent)

        self._channel = "/dev2/ai0"
        self._maxv = 10.
        self._rate = 100.
        self._avg = 10.


        self._running = False


    channelChanged = pyqtSignal()
    channel = simpleProperty('QString', 'channel', channelChanged)

    maxvChanged = pyqtSignal()
    maxv = simpleProperty(float, 'maxv', maxvChanged)

    rateChanged = pyqtSignal()
    rate = simpleProperty(int, 'rate', rateChanged)

    runningChanged = pyqtSignal()
    running = simpleProperty(bool, 'running', runningChanged)

#    @running.setter
#    def running(self, running):
#        qDebug(running)

    dostart = pyqtSignal()

    @pyqtSlot()
    def start(self):
        qDebug("start")
        self.dostart.emit()

    @pyqtSlot()
    def stop(self):
        qDebug("stop")





app = QGuiApplication(sys.argv)
engine = QQmlApplicationEngine()

ctx = engine.rootContext()
# create an instance to be accesable from QML
daq_control = DaqControl()
ctx.setContextProperty("daq_control", daq_control)



thread = QThread()
worker = DaqWorker()
worker.moveToThread(thread)
#thread.started.connect(worker.work)
daq_control.dostart.connect(worker.work)
thread.start()
ctx.setContextProperty("worker", worker)

engine.load(QUrl("main.qml"))



if __name__ == '__main__':
    app.exec()
