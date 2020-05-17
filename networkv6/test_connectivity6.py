import json
import socket
with open('output.json') as f:
    data = json.load(f)
private_svr_ipv6 = data['private-svr-ipv6']['value'] 
pub_svr_ipv6 = data['pub-svr-ipv6']['value']

def isOpen(ip, port):
        s = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
        s.settimeout(5)
        try:
                s.connect((ip, int(port)))
                s.shutdown(socket.SHUT_RDWR)
                return True
        except:
                return False
        finally:
                s.close()

def test_public_svr():
    assert isOpen(pub_svr_ipv6,22) == True
        
def test_private_svr():
        assert isOpen(private_svr_ipv6,22) == True
