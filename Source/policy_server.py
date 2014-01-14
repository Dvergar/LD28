from twisted.internet import protocol, reactor
from twisted.protocols import basic
from twisted.protocols.policies import TimeoutMixin


class FlashPolicyProtocol(basic.LineOnlyReceiver, TimeoutMixin):
    delimiter = '\0'
    MAX_LENGTH = 64
    TIMEOUT = 15  # seconds

    def __init__(self):
        self.setTimeout(self.TIMEOUT)

    def lineReceived(self, request):
        print "received"
        if request != '<policy-file-request/>':
            self.transport.loseConnection()
            return
        self.transport.write(self.factory.response_body)
        self.resetTimeout()


class FlashPolicyFactory(protocol.ServerFactory):
    protocol = FlashPolicyProtocol

    def __init__(self):
        with open('mypolicy.xml', 'rb') as f:
            self.response_body = f.read() + '\0'

reactor.listenTCP(843, FlashPolicyFactory())
reactor.run()
