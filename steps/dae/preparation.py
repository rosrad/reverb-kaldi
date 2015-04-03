#!/home/14/ren/local/bin/python

import os
import numpy
import glob
import subprocess
from threading import Thread
from Queue import Queue
import theano
import theano.tensor as T

separated="separated_egs"
train="train"
# train="test"
label="label"
stacked="stacked.npy"
egs="egs"
def TargetFiles(dir,i):
    tr="%s/%s/%s%d" % (dir,separated,train,i)
    lb="%s/%s/%s%d" % (dir,separated,label,i)
    return (tr,lb)

def ExtractEgs(index,file):
    dir=os.path.join(os.path.dirname(file))
    train,label = TargetFiles(dir,index)
    
    cmd="separate-egs ark:%s %s %s" % (file, train, label)
    if os.path.exists(file) :
        subprocess.call(cmd.split())
    else:
        print "no exist file %s" % file


def Worker(q,i):
    while True:
        index,file = q.get()
        print "%dth file is processed at thread %d" % (index,i)
        ExtractEgs(index,file)
        q.task_done()

def Filter(file):
    with open(file) as f:
        for l in f:
            yield l.translate(None,"[]")

            

def FindEgs(dir) :
    egs_dir=os.path.join(dir,egs)

    separated_dir=os.path.join(egs_dir,separated)
    if not os.path.exists(separated_dir):
        os.mkdir(separated_dir)

    q = Queue()
    threads = []
    for i in range(5):
        t = Thread(target=Worker, args=(q,i))
        threads.append(t)
        t.start()
        
    index = []
    for i,f in enumerate(glob.glob(egs_dir+"/egs.*.ark")):
        print "Input %dth file:%s" %(i,f)
        q.put((i,f))
        index.append(i)
        q.join()
        
    # concatenate all train and label files 
    data=[]
    for i in index:
        tr,lb=TargetFiles(egs_dir,i)
        print "Generating array from file :%s" % tr
        data.append(numpy.genfromtxt(Filter(tr), dtype='f'))
        print "Stacking array from %d arrays" % len(data)
        stacked_data= numpy.vstack((data))
        stacked_file=os.path.join(egs_dir,stacked)
        print "Saving stacked array to %s" % stacked_file
        numpy.save(stacked_file, stacked_data)
        print "Saved!"
        
def ReadEgs(dir):

    tr_f=os.path.join(dir,egs,stacked)
    print "Reading arrays from %s" %tr_f
    train=numpy.load(tr_f)
    return train

def LoadShared(dir="/home/14/ren/rev_kaldi/tmp/exp/mfcc/normal/DNN/egs/"):
    train = ReadEgs(dir)
    valid = train[0:100, :]
    test = train[100:200, :]
    def shared_dataset(data_xy, borrow=True):
        data_x, data_y = data_xy
        shared_x = theano.shared(numpy.asarray(data_x,
                                               dtype=theano.config.floatX),
                                 borrow=borrow)
        shared_y = theano.shared(numpy.asarray(data_y,
                                               dtype=theano.config.floatX),
                                 borrow=borrow)
        return shared_x, T.cast(shared_y, 'int32')

    train_x,train_y=shared_dataset((train,numpy.zeros(train.shape[0])))
    valid_x,valid_y=shared_dataset((valid,numpy.zeros(valid.shape[0])))
    test_x,test_y=shared_dataset((test,numpy.zeros(test.shape[0])))

    rval = [(train_x, train_y), (valid_x, valid_y),
            (test_x, test_y)]
    return rval

if __name__ == "__main__":
    
    dst="/home/14/ren/rev_kaldi/tmp/exp/mfcc/normal/DNN/egs"
    # FindEgs(dst)
    train=LoadShared(dst)
    print train

