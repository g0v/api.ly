#!/usr/bin/env python
import os, tempfile, sys, subprocess, fcntl, time, threading

# this script feeds specified command with two fifo.
# and redirect one of them to stdout
# usage: divide.py [your-command]
# tweak your wait time, read size and command para format below

# configuration
WAIT_TIME = 10          # in second
READ_SIZE = 1024        # size of each read from fifo

# formatter for command.
#CMD_FORMAT = "%s %s %s"
CMD_FORMAT = "%s -o %s -o %s '%s'"


#################################################################

if len(sys.argv)<3:
  print("usage: divide.py [command] [arg]")
  sys.exit(-1)

stream = None      # chosen fifo file name
spawner = None     # thread for running specified command
trial = 0          # attempt count to create temp fifo pair
is_done = False    # specified command is done

# try to create a temp fifo pair, named fifo1 and fifo2
while 1:
  try:
    tmpdir = tempfile.mkdtemp()
    fifo1 = os.path.join(tmpdir, "fifo1")
    fifo2 = os.path.join(tmpdir, "fifo2")
    os.mkfifo(fifo1)
    os.mkfifo(fifo2)
    break
  except:
    trial += 1
    if trial >=3:
      print("try creating named pipe but failed.")
      sys.exit(-1)

# run assigned command (as thread). trigger fifo reader while ended
def runproc():
  global is_done
  proc = subprocess.Popen(CMD_FORMAT%(sys.argv[1], fifo1, fifo2, sys.argv[2]), shell=True, stdout=subprocess.PIPE)
  [stdout, stderr] = proc.communicate(None)
  is_done = True
  while not stream: time.sleep(1)
  if stream!="failed":
    s = os.open(stream , os.O_WRONLY)
    os.write(s, "")
    os.close(s)

# open fifo pair non-blockingly for peeking data
f1 = os.open(fifo1, os.O_RDONLY | os.O_NONBLOCK)
f2 = os.open(fifo2, os.O_RDONLY | os.O_NONBLOCK)

# run command after readers are ready
spawner = threading.Thread(target=runproc)
spawner.start()

time.sleep(1)
stdout = os.fdopen(sys.stdout.fileno(), "wb", 0) # binary write, no buffer

count = 0
buf, d1, d2 = "", "",""
while True:
  d1, d2 = "", ""
  try:
    d1 = os.read(f1, READ_SIZE)
    d2 = os.read(f2, READ_SIZE)
  except: pass
  if len(d1):
    count += len(d1)
    buf += d1
  if d2 or count >= 114845: break
  if is_done:
    stream = "failed"
    sys.stderr.writelines("command stopped too soon.\n")
    spawner.join()
    sys.exit(-1)

# choose fifo1 if no data in fifo2. else choose fifo2
os.close(f1)
os.close(f2)
stream = fifo2 if d2 else fifo1

# dump data first, if got any
data = d2 if d2 else buf
sys.stderr.writelines("\ndata length: fifo1:%d  / fifo2:%d\n"%(count, len(d2)))
sys.stderr.writelines("use %s\n"%("fifo2" if d2 else "fifo1"))
if data:
  stdout.write(data)
  stdout.flush()

# read chosen fifo until the specified command is over.
handle = os.open(stream, os.O_RDONLY)
while True:
  try: data = os.read(handle, READ_SIZE)
  except OSError: continue
  if len(data)>0:
    stdout.write(data)
    stdout.flush()
  elif is_done:
    spawner.join()
    break
