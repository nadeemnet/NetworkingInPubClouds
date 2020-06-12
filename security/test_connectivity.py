import json
import socket
with open('output.json') as f:
    data = json.load(f)
jumphost_ip = data['jumphost_ip']['value'] 
pubsvr_ip = data['pub-svr-ipv4']['value']

def isOpen(ip, port):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(5)
        try:
                s.connect((ip, int(port)))
                s.shutdown(socket.SHUT_RDWR)
                return True
        except:
                return False
        finally:
                s.close()

def test_jumphost():
    assert isOpen(jumphost_ip,22) == True
        
def test_pubsvr():
        assert isOpen(pubsvr_ip,22) == False
