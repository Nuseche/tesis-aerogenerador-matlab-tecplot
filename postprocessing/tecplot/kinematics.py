"""Tecplot mathematical annotation helpers."""
def m(s):return s
def var(s):return '<i>'+s+'</i>'
def sub(s):return '<sub>'+str(s)+'</sub>'
def sup(s):return '<sup>'+str(s)+'</sup>'
def v(s,index='',frame=''):
    return '<b><i>'+s+'</i></b>'+(sub(index) if index!='' else '')+(sup(frame) if frame else '')
def greek(s):return '<greek>'+s+'</greek>'
def e(i,frame=''):return v('e',i,frame)
def E(i):return v('E',i)
