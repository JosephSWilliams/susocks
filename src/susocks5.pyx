#!/usr/bin/env python
import socket, sys, os
sys.path.append('/services/susocks/')
sys.dont_write_bytecode=1
import config

b='\x05'+os.read(0,1)
if (len(b)<2)|(ord(b[0])!=5):
  sys.exit(0)

b+=os.read(0,ord(b[1]))
if (len(b)<2+ord(b[1]))|\
   (not('\x00'in b[2:])):
  sys.exit(0)
os.write(1,'\x05\x00')

b=os.read(0,4)
if (len(b)<4)    |(b[0]!='\x05')|\
   (b[1]!='\x01')|(b[2]!='\x00')|(
   (b[3]!='\x01')&(b[3]!='\x03')):
  sys.exit(0)

if b[3]=='\x01':
  addr=os.read(0,6)
  if len(addr)<6:
    sys.exit(0)
  dst=(
    str(ord(addr[0]))+'.'+str(ord(addr[1]))+'.'+\
    str(ord(addr[2]))+'.'+str(ord(addr[3])),
    ord(addr[4])*256+ord(addr[5])
  )

if b[3]=='\x03':
  addr=os.read(0,1)
  if len(addr)<1:
    sys.exit(0)
  addr+=os.read(0,ord(addr)+2)
  if len(addr)<1+ord(addr[0])+2:
    sys.exit(0)
  dst=(
    addr[1:1+ord(addr[0])],
    ord(addr[::-1][1])*256+ord(addr[::-1][0])
  )

if config.filter(dst)<1:
  sys.exit(0)

s=socket.socket(2,1)
s.setsockopt(1,2,1)

if config.chain(dst)>0:
  try:
    s.connect((config.FORWARD_ADDR,config.FORWARD_PORT))

    if config.FORWARD_TYPE=='SOCKS5':
      os.write(3,'\x05\x01\x00')
      if os.read(3,2)!='\x05\x00':
        sys.exit(0)
      if os.read(3,os.write(3,b+addr))[:2]!='\x05\x00':
        sys.exit(0)

    elif config.FORWARD_TYPE=='SOCKS4A':
      os.write(3,
        '\x04\x01'
        +addr[len(addr)-2:]
        +'\x00\x00\x00\x01'
        +'\x73\x75\x73\x6F\x63\x6B\x73\x00'
        +dst[0]+'\x00'
      )
      if os.read(3,8)[:2]!='\x00\x5A':
        sys.exit(0)

    elif config.FORWARD_TYPE=='SOCKS4':
      os.write(3,
        '\x04\x01'
        +addr[len(addr)-2:]
        +socket.inet_aton(socket.gethostbyname(dst[0]))
        +'\x73\x75\x73\x6F\x63\x6B\x73\x00'
      )
      if os.read(3,8)[:2]!='\x00\x5A':
        sys.exit(0)

    elif config.FORWARD_TYPE=='CONNECT':
      os.write(3,'CONNECT '+dst[0]+':'+str(dst[1])+' HTTP/1.0\n\n')
      if not(' 200 'in os.read(3,1024)):
        sys.exit(0)

    else:
      sys.exit(0)
  except:
    sys.exit(0)

else:
  try:
    s.connect(dst)
  except:
    sys.exit(0)

os.write(1,'\x05\x00'+b[2:]+addr)
del b, addr, dst
os.execvp('/services/susocks/sustream',[str()])
