#! usr/bin/env python

import socket
from Crypto.PublicKey import RSA
from Crypto import Random

def get_ip_address():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    host = s.getsockname()[0]
    s.close()
    return host


#Generating private key and public key
random_generator = Random.new().read
private_key = RSA.generate(1024, random_generator)
public_key = private_key.publickey()

#Declarations
mysocket = socket.socket()
#host = "10.27.82.129"
host = get_ip_address()
port = 9876
encrypt_str = "encrypted_message="

if host == "127.0.0.1" :
    import commands
    host = commands.getoutput("hostname")
print "host = " + host

# Prevent socket errror [Erno 98] Address already in use
mysocket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

mysocket.bind((host, port))
mysocket.listen(5)

c, addr = mysocket.accept()

while True :
    data = c.recv(1024)
    data = data.replace("\r\n", '')
    
    if data == "Client: OK" :
        c.send("public_key=" + public_key.exportKey() + '\n')
        print "public key sent"
    
    elif encrypt_str in data:
        #remove encrypt_str
        data = data.replace(encrypt_str, '')

        #decrypt
        decrypted = private_key.decrypt(data)

        #remove padding : https://stackoverflow.com/questions/22398745/rsa-encrypt-decrypt-between-c-and-python
        if len(decrypted) > 0 and decrypted[0] == '\x02':
            pos = decrypted.find('\x00')
            if pos > 0:
                c.send("Server: OK")
                message = decrypted[pos+1:]
                print message

    elif data == "Quit": break


c.send("Server stopped\n")
print "Server stopped"
c.close()
