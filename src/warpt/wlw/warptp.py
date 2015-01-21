"""
Warping of well logs from Teapot Dome survey.
Author: Dave Hale, Colorado School of Mines
Version: 2013.12.28
"""

from java.awt import *
from java.io import *
from java.nio import *
from java.lang import *
from java.util import *

from edu.mines.jtk.awt import *
from edu.mines.jtk.dsp import *
from edu.mines.jtk.interp import *
from edu.mines.jtk.io import *
from edu.mines.jtk.mesh import *
from edu.mines.jtk.mosaic import *
from edu.mines.jtk.util import *
from edu.mines.jtk.util.ArrayMath import *

from tp import *
from warpt import *

wlw = WellLogWarpingTest()
#wlw = WellLogWarpingT()
curve = "d"
curves = ["v"]
#curves = ["v","p"]
#curves = ["v","p","d"]
#curves  = ["v", "d", "p", "g"]
weights = [1.0]
#weights = [1.5, 1.0, 0.5]
#weights = [0.0, 1.0, 0.0, 0.0]
wells = None
logs = None
fnull = -999.2500

def main(args):
  global logs
  logs = getLogs("d",curve)
  global wells
  wells = getWells("d",curves)
  #goStats()
  #goHistogram()
  goShifts()
  #goErrorsM()
  #goRGT()
  #goHorizon()
  #goWarping()
  #goWarpingTest()
  #goErrors()
  #goErrorsIJ()
  #goResample()
  #goSort()
  #goMesh()
  #goCreateLog()
  #goShiftTest()
  #goShiftGapTest()
  #goUnconformityTest()

def goStats():
  sz,wl = resampleMulti(wells,curves)
  #wl = [wl[24],wl[32],wl[33],wl[67],wl[68]]
  wl = [wl[ 4],wl[10],wl[15],wl[16],wl[24],
        wl[25],wl[32],wl[33],wl[35],wl[38],
        wl[50],wl[57],wl[64],wl[65],wl[67],
        wl[68],wl[80],wl[82],wl[93],wl[95],
        wl[107],wl[119],wl[121],wl[122],wl[128],
        wl[133],wl[154],wl[159],wl[165]] # all velocity logs (v,d,p)

  nl = len(wl)
  for i,c in enumerate(curves):
    for l in range(nl):
      print "log",l,"curve",c
      wlw.stats(wl[l][i])

def goHistogram():
  sz,wl = resampleMulti(wells,curves)
  wl = [wl[24]]
  #wl = [wl[24],wl[32],wl[33],wl[67],wl[68]]
  #wl = [wl[ 4],wl[10],wl[15],wl[16],wl[24],
  #      wl[25],wl[32],wl[33],wl[35],wl[38],
  #      wl[50],wl[57],wl[64],wl[65],wl[67],
  #      wl[68],wl[80],wl[82],wl[93],wl[95],
  #      wl[107],wl[119],wl[121],wl[122],wl[128],
  #      wl[133],wl[154],wl[159],wl[165]] # all velocity logs (v,d,p)

  nl = len(wl)
  for i,c in enumerate(curves):
    for l in range(nl):
      print "log",l,"curve",c
      wlw.histogram(c,wl[l][i])
      wlw.normalize(wl[l][i])
      wlw.histogram(c+" normalized",wl[l][i])

def goErrorsM():
  sz,wl = resampleMulti(wells,curves)
  #wl = [wl[ 4],wl[36],wl[37],wl[41],wl[43],
  #      wl[50],wl[78],wl[81],wl[88],wl[163]] # density and porosity
  #wl = [wl[ 1],wl[ 7],wl[37],wl[56],wl[65],
  #      wl[70],wl[73],wl[81]] # porosity and velocity
  wl = [wl[24],wl[68],wl[80],wl[107],wl[128]]
  #wl = [wl[32],wl[33]]
  nl = len(wl)
  wlw.setPowError(0.25)
  wlw.setMaxShift(250)

  #pairs = [(0,1)] 
  pairs = [(3,4)] 
  #pairs = [(3,4),(2,4)] 
  #pairs = [(1,2),(2,3),(3,4),(5,6)] 
  wlw.normalize(wl)
  iqr = wlw.iqr(wl)
  for pair in pairs:
    ia,ib = pair[0],pair[1]
    #e = wlw.computeErrors(wl[ia],wl[ib])
    e = wlw.computeErrors(0,iqr,wl[ia],wl[ib])
    wlw.interpolateOddErrors(e)
    nl,nk = len(e[0]),len(e)
    lmax = (nl-1)/2
    lmin = -lmax
    sl = Sampling(nl,1,lmin)
    sk = Sampling(nk,1,0)
    title = "("+str(ia)+","+str(ib)+")"
    sp = SimplePlot()
    sp.setSize(890,550)
    #sp.setSize(1440,873)
    #sp.setSize(780,555)
    sp.setTitle(title)
    sp.setHLabel("Depth index k")
    sp.setVLabel("Lag index l")
    sp.setHLimits(0,nk)
    sp.setHFormat("%5f")
    #sp.addColorBar("e[k,l]")
    pv = sp.addPixels(sk,sl,transpose(e))
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    pv.setPercentiles(0,100)
    #sp.setFontSizeForSlide(1.0,1.0,16.0/9.0)
    #sp.paintToPng(720.0,3.55,"ae1.png")
    sp1 = SimplePlot()
    #sp1.setSize(1440,873)
    sp1.setSize(890,550)
    #sp1.setSize(780,555)
    sp1.setTitle(title)
    sp1.setHLabel("Depth index k")
    sp1.setVLabel("Lag index l")
    sp1.setHLimits(0,nk)
    sp1.setHFormat("%5f")
    #sp1.addColorBar("e[k,l]")
    pv = sp1.addPixels(sk,sl,transpose(e))
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    pv.setPercentiles(0,100)
    d = wlw.accumulateErrors(e)
    wlw.interpolateOddErrors(d)
    kw,lw = wlw.findWarping(d)
    kw = wlw.toFloat(kw)
    lw = wlw.toFloat(lw)
    pv1 = sp1.addPoints(kw,lw)
    pv1.setLineColor(Color.RED)
    pv1.setLineStyle(PointsView.Line.DASH)
    pv1.setLineWidth(2.0)
    #sp1.setFontSizeForSlide(1.0,1.0,16.0/9.0)
    #sp1.paintToPng(720.0,3.55,"ae2.png")
    """
    sp = SimplePlot()
    #sp.setSize(780,555)
    sp.setSize(1440,873)
    sp.setTitle(title)
    sp.setHLabel("Depth index k")
    sp.setVLabel("Lag index l")
    sp.setHFormat("%5f")
    pv = sp.addPixels(sk,sl,transpose(d))
    #pv.setColorModel(cjet)
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    pv.setPercentiles(0,90)
    kw,lw = wlw.findWarping(d)
    kw = wlw.toFloat(kw)
    lw = wlw.toFloat(lw)
    pv = sp.addPoints(kw,lw)
    pv.setLineColor(Color.WHITE)
    """
def goWarpingTest():
  pairs = [(0,1),(2,3)]
  sz,wl = resampleMulti(wells,curves)
  wl = [wl[0],wl[4]]
  nk = len(wl[0][0])
  nc = len(wl[0])
  nl = len(wl)
  random = Random(314159)
  for i in range(nl):
    for c in range(nc):
      igood = wlw.findGood(wl[i][c])
      for k in range(nk):
        wl[i][c][k] = wlw.value(random,igood,wl[i][c],k)
  wtest = zerofloat(nk,nc,nl)
  for i in range(nl):
    for c in range(nc):
      for k in range(nk):
        wtest[i][c][k] = wl[i][c][nk-1-k]
  
  wl = [wl[0],wl[1],wtest[0],wtest[1]]
  nl = len(wl)
  wlw.setPowError(0.25)
  wlw.setMaxShift(250)
  freplace = -2.0
  vlabel = "Velocity (km/s)"
  if curve=="d":
    freplace = 1.0
    vlabel = "Density (g/cc)"
  if curve=="p":
    freplace = 0.0
    vlabel = "Porosity"
  if curve=="g":
    freplace = 30.0
    vlabel = "Gamma ray (API)"
  for pair in pairs:
    jf,jg = pair[0],pair[1]
    fi,gj = wl[jf][0],wl[jg][0]
    e = wlw.computeErrors(fi,gj)
    nl,nk = len(e[0]),len(e)
    d = wlw.accumulateErrors(e)
    kl = wlw.findWarping(d)
    fk,gk = wlw.applyWarping(kl,fi,gj)
    fi = wlw.replaceNulls(fi,freplace)
    gj = wlw.replaceNulls(gj,freplace)
    fk = wlw.replaceNulls(fk,freplace)
    gk = wlw.replaceNulls(gk,freplace)
    ii,ff = removeZeros(fi)
    jj,gg = removeZeros(gj)
    for ij in range(len(ff)):
      if ff[ij] == -2.0:
        ff[ij] = 3.0
    for ij in range(len(gg)):
      if gg[ij] == -2.0:
        gg[ij] = 3.0
    sff = Sampling(len(ff),sz.getDelta(),sz.getFirst() +ii*sz.getDelta())
    sgg = Sampling(len(gg),sz.getDelta(),sz.getFirst() +jj*sz.getDelta())
    title = "("+str(jf)+","+str(jg)+")"
    sk = Sampling(2*sz.count-1,0.5*sz.delta,sz.first)
    if True:
      sp = SimplePlot()
      sp.setSize(750,500)
      sp.setTitle(title)
      sp.setHLabel("Depth (km)")
      sp.setVLabel(vlabel)
      #sp.setVLimits(2,2.8)
      sp.setVLimits(2,6.5)
      pv = sp.addPoints(sz,fi)
      pv.setLineColor(Color.BLACK)
      pv = sp.addPoints(sz,gj)
      pv.setLineColor(Color.RED)

      """
      pv = pp.addPoints(0,0,sz,fi)
      pv.setLineColor(Color.BLACK)
      #pv = pp.addPoints(0,0,sz,gj)
      #pv.setLineColor(Color.RED)
      pv.setLineWidth(2.0)

      pv = pp.addPoints(0,0,sff,ff) ## to start plotting at first depth
      pv.setLineColor(Color.BLACK)
      #pv = pp.addPoints(0,0,sgg,gg)
      #pv.setLineColor(Color.RED)
      pv.setLineWidth(2.0)
      """
    if True:
      sp = SimplePlot()
      sp.setSize(750,500)
      sp.setTitle(title)
      sp.setHLabel("Depth (km)")
      sp.setVLabel(vlabel)
      #sp.setVLimits(2,2.8)
      sp.setVLimits(2,6.5)
      pv = sp.addPoints(sk,fk)
      pv.setLineColor(Color.BLACK)
      pv = sp.addPoints(sk,gk)
      pv.setLineColor(Color.RED)

      #pv = pp.addPoints(0,0,sk,fk)
      #pv.setLineColor(Color.BLACK)
      #pv = pp.addPoints(0,0,sk,gk)
      #pv.setLineColor(Color.RED)
      #pv.setLineWidth(2.0)

def goShifts():
  sz,wl = resampleMulti(wells,curves)
  wl = [wl[0],wl[4],wl[9],wl[11],wl[14],wl[17],wl[20]] # deepest 7 velocity logs
  #wl = [wl[0],wl[4],wl[9],wl[14],wl[17],wl[20]] # deepest 6 velocity logs
  #wl = [wl[16],wl[18],wl[19],wl[28],wl[33],
  #      wl[34],wl[35],wl[37],wl[38],wl[39],
  #      wl[45],wl[50],wl[68]] # deepest 13 porosity logs
  #wl = [wl[ 6],wl[16],wl[18],wl[31],wl[32],wl[33],wl[36],
  #      wl[38],wl[48],wl[55],wl[86]] # deepest 11 gamma logs
  #wl = [wl[ 1],wl[ 2],wl[ 3],wl[ 4],wl[ 7],
  #      wl[11],wl[21],wl[22],wl[33],wl[35],
  #      wl[43],wl[48],wl[50],wl[56],wl[66],
  #      wl[81],wl[88],wl[163]] # deepest 18 density logs
  #wl = [wl[  1],wl[ 80],wl[ 90],wl[ 91],wl[ 94],
  #      wl[121],wl[122],wl[123],wl[125],wl[127],
  #      wl[128],wl[130],wl[134],wl[138],wl[139],
  #      wl[146],wl[149],wl[150],wl[151],wl[152],
  #      wl[159],wl[168]]
  nl = len(wl)
  wlw.setPowError(0.25)
  wlw.setMaxShift(350)
  s = wlw.findShifts(weights, wl)
  fs = zerofloat(len(wl[0][0]),nl)
  freplace = 2.0
  fclips = (2.0,6.0)
  cblabel = "Velocity (km/s)"
  s = mul(1000*sz.delta,s) # convert shifts to m
  for i,c in enumerate(curves):
    for j in range(nl):
      fs[j] = wl[j][i]
      gs = wlw.applyShifts(fs,s)
      if c=="d":
        freplace = 1.0
        fclips = (2.0,2.8)
        cblabel = "Density (g/cc)"
      if c=="p":
        freplace = 0.0
        fclips = (0.0,0.45)
        cblabel = "Porosity"
      if c=="g":
        freplace = 30.0
        fclips = (30.0,160.0)
        cblabel = "Gamma ray (API)"
    fs = wlw.replaceNulls(fs,freplace)
    gs = wlw.replaceNulls(gs,freplace)
    sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
    sp.setSize(500,900) # CWPposter
    sp.setVLabel("Depth (km)")
    sp.setHLabel("Log index")
    sp.addColorBar(cblabel)
    sp.plotPanel.setColorBarWidthMinimum(90)
    pv = sp.addPixels(sz,Sampling(nl,1,1),fs)
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    pv.setColorModel(cjet)
    pv.setClips(fclips[0],fclips[1])
    #sp.setFontSizeForPrint(12.0,222) #GP newsletter
    #sp.setFontSizeForSlide(1.0,1.0,16.0/9.0)
    #sp.paintToPng(720.0,3.08,c+"before.png")
    sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
    sp.setSize(500,900) # CWPposter
    sp.setVLabel("Relative geologic time")
    sp.setHLabel("Log index")
    sp.addColorBar(cblabel)
    sp.plotPanel.setColorBarWidthMinimum(90)
    pv = sp.addPixels(sz,Sampling(nl,1,1),gs)
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    pv.setColorModel(cjet)
    pv.setClips(fclips[0],fclips[1])
    #sp.setFontSizeForPrint(12.0,222) #GP newsletter
    #sp.setFontSizeForSlide(1.0,1.0,16.0/9.0)
    #sp.paintToPng(720.0,3.08,c+"after.png")
  """
  sp1 = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp1.setSize(650,550)
  sp1.setSize(800,500) # CWPposter
  sp1.setVLabel("Relative geologic time")
  sp1.setHLabel("Log index")
  sp1.addColorBar("Shifts (RGT)")
  sp1.plotPanel.setColorBarWidthMinimum(90)
  pv = sp1.addPixels(sz,Sampling(nl,1,1),s)
  pv.setClips(-250,250)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  """


def goRGT():
  sz,fs = resample(logs,curve)
  #fs = [fs[0],fs[4],fs[9],fs[14],fs[17],fs[20]] # deepest 6 velocity logs
  #fs = [fs[0],fs[4],fs[9],fs[11],fs[14],fs[17],fs[20]]
  #fs = [fs[ 1],fs[ 2],fs[ 3],fs[ 4],fs[ 7],
  #      fs[11],fs[21],fs[22],fs[33],fs[35],
  #      fs[43],fs[48],fs[50],fs[56],fs[66],
  #      fs[81],fs[88],fs[163]] # deepest 18 density logs
  nk,nl = len(fs[0]),len(fs)
  wlw.setPowError(0.25)
  wlw.setMaxShift(250)
  s = wlw.findShifts(fs)
  freplace = 2.0
  if curve=="d":
    freplace = 1.0
  fclips = (2.0,6.0)
  if curve=="d":
    fclips = (2.0,2.8)
  fs = wlw.replaceNulls(fs,freplace)
  tz = zerofloat(nk,nl)
  for il in range(nl):
    for ik in range(nk):
      #print ik, s[il][ik]
      tz[il][ik] = ik+s[il][ik] #FIX

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  sp.setSize(650,550)
  sp.setVLabel("Depth (km)")
  sp.setHLabel("Log index")
  sp.addColorBar("RGT")
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(sz,Sampling(nl),tz)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  sp.setSize(650,550)
  sp.setVLabel("Depth (km)")
  sp.setHLabel("Log index")
  sp.addColorBar("Velocity (km/s)")
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(sz,Sampling(nl),fs)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])

def goHorizon():
  sz,fs = resample(logs,curve)
  #fs = [fs[0],fs[4],fs[9],fs[14],fs[17],fs[20]] # deepest 6 velocity logs
  #fs = [fs[0],fs[4],fs[9],fs[11],fs[14],fs[17],fs[20]]
  #fs = [fs[ 1],fs[ 2],fs[ 3],fs[ 4],fs[ 7],
  #      fs[11],fs[21],fs[22],fs[33],fs[35],
  #      fs[43],fs[48],fs[50],fs[56],fs[66],
  #      fs[81],fs[88],fs[163]] # deepest 18 density logs
  nk,nl = len(fs[0]),len(fs)
  wlw.setPowError(0.25)
  wlw.setMaxShift(250)
  s = wlw.findShifts(fs)
  st = copy(s)
  wlw.invertShifts(st)
  """
  gs = wlw.applyShifts(fs,s)
  s = mul(1000*sz.delta,s) # convert shifts to m
  freplace = 2.0
  if curve=="d":
    freplace = 1.0
  fclips = (2.0,6.0)
  if curve=="d":
    fclips = (2.0,2.8)
  """

  tz = sz.delta*len(fs[0])/2
  zt = zerofloat(nl)
  ti = sz.indexOfNearest(tz)
  for i in range(nl):
    zt[i] = sz.getValue(int(ti - st[i][ti]))
    #zt[i] = ti - st[i][ti]
  x,y = getXYLocation("d",curve)
    

  """
  seis = readImage()
  nx = len(seis)
  ny = len(seis[0])
  nzz = len(seis[0][0])
  dz = 0.002
  dy = 0.025
  dx = 0.025
  sx = Sampling(nx,dx,0.0)
  sy = Sampling(ny,dx,0.0)
  szz = Sampling(nzz,dz,0.0)
  """
  ny = 50
  nx = 20
  dy = 10.0/ny
  dx = 5.0/nx
  sx = Sampling(nx,dx,0.0)
  sy = Sampling(ny,dy,0.0)

  #grd = SplinesGridder2(zt,y,x)
  #grd = DiscreteSibsonGridder2(zt,x,y)
  grd = SibsonGridder2(zt,x,y)
  zt = grd.grid(sy,sx)

  sp = SimplePlot()
  sp.setSize(700,380)
  sp.addColorBar("Depth (km)")
  pv = sp.addPixels(sy,sx,zt)
  pv.setColorModel(cjet)
  pv.setClips(0.87,1.00)
  ptv = sp.addPoints(x,y)
  ptv.setLineStyle(PointsView.Line.NONE)
  ptv.setMarkColor(Color.BLACK)
  ptv.setMarkStyle(PointsView.Mark.FILLED_CIRCLE)
  ptv.setMarkSize(12)
  cv = sp.addContours(sy,sx,zt)
  cv.setColorModel(ColorMap.GRAY)
  cv.setClips(0.87,1.00)
  #cv.setContours()
  """
  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  sp.setSize(650,550)
  sp.setVLabel("Depth (km)")
  sp.setHLabel("Log index")
  sp.addColorBar("Velocity (km/s)")
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(sz,Sampling(nl),fs)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])
  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  sp.setSize(650,550)
  sp.setVLabel("Depth (km)")
  sp.setHLabel("Log index")
  sp.addColorBar("Relative Geologic Time")
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(sz,Sampling(nl),gs)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])
  """

  """
  sinc = SincInterp()
  fx,fy = sx.first,sy.first
  horizon = zerofloat(sy.count,sx.count)
  for ix in range(nx):
    for iy in range(ny):
      zi= zt[ix][iy]
      xi = fx+ix*dx
      yi= fy+iy*dy
      horizon[ix][iy] = sinc.interpolate(szz,sy,sx,seis,zi,yi,xi)
  SimplePlot.asPixels(horizon)
  """


def goWarping():
  #pairs = [(0,4),(4,9),(9,14),(14,17),(17,20)] # deepest 6 velocity logs
  #pairs = [(0,4)] #slides
  #pairs = [(0,4),(4,20),(9,14)] # paper
  #pairs = [(0,4),(4,9),(17,20)] 
  #pairs = [(4,0),(4,9),(4,14),(4,17),(4,20)] # log 4 is nearest to centroid
  #pairs = [(4,14)]
  pairs = [(1,2),(3,4),(4,7),(21,22),(66,88)] # log 4 is nearest to centroid
  sz,fs = resample(logs,curve)
  wlw.setPowError(0.1)
  #wlw.setPowError(2.00)
  wlw.setMaxShift(250)
  freplace = -2.0
  #freplace = 2.0
  vlabel = "Velocity (km/s)"
  if curve=="d":
    freplace = 1.0
    vlabel = "Density (g/cc)"
  if curve=="p":
    freplace = 0.0
    vlabel = "Porosity"
  if curve=="g":
    freplace = 30.0
    vlabel = "Gamma ray (API)"
  for pair in pairs:
    jf,jg = pair[0],pair[1]
    fi,gj = fs[jf],fs[jg]
    e = wlw.computeErrors(fi,gj)
    nl,nk = len(e[0]),len(e)
    d = wlw.accumulateErrors(e)
    kl = wlw.findWarping(d)
    fk,gk = wlw.applyWarping(kl,fi,gj)
    fi = wlw.replaceNulls(fi,freplace)
    gj = wlw.replaceNulls(gj,freplace)
    fk = wlw.replaceNulls(fk,freplace)
    gk = wlw.replaceNulls(gk,freplace)
    ii,ff = removeZeros(fi)
    jj,gg = removeZeros(gj)
    for ij in range(len(ff)):
      if ff[ij] == -2.0:
        ff[ij] = 3.0
    for ij in range(len(gg)):
      if gg[ij] == -2.0:
        gg[ij] = 3.0
    sff = Sampling(len(ff),sz.getDelta(),sz.getFirst() +ii*sz.getDelta())
    sgg = Sampling(len(gg),sz.getDelta(),sz.getFirst() +jj*sz.getDelta())
    title = "("+str(jf)+","+str(jg)+")"
    sk = Sampling(2*sz.count-1,0.5*sz.delta,sz.first)
    #pp = PlotPanel(2,1)
    #pp = PlotPanel(PlotPanel.Orientation.X1DOWN_X2RIGHT)
    #pp.setVLimits(0,2,6.5)
    #pp.setVLimits(1,2,6.5)
    #pp.setTitle(title)
    #pp.setVLabel("Relative geologic time")
    #pp.setVLabel("Depth (km)")
    #pp.setHLabel("Velocity (km/s)")
    #pp.setHLimits(3,4.5)
    #pp.setHLimits(2.5,5.09)
    #pp.setHLimits(2,6.4)
    #pp.setVLimits(0,1.9)
    #pp.setVLimits(0.892,1.142)
    #pp.setVLimits(1.005,1.025)
    #pp.setHLabel("Depth (km)")
    #pp.setVLabel(0,"Velocity (km/s)")
    #pp.setVLabel(1,"Velocity (km/s)")
    #pp.setVLimits(0,2,6.4)
    #pp.setVLimits(1,2,6.4)
    if True:
      sp = SimplePlot()
      sp.setSize(750,500)
      sp.setTitle(title)
      sp.setHLabel("Depth (km)")
      sp.setVLabel(vlabel)
      sp.setVLimits(2,2.8)
      #sp.setVLimits(2,6.5)
      pv = sp.addPoints(sz,fi)
      pv.setLineColor(Color.BLACK)
      pv = sp.addPoints(sz,gj)
      pv.setLineColor(Color.RED)

      """
      pv = pp.addPoints(0,0,sz,fi)
      pv.setLineColor(Color.BLACK)
      #pv = pp.addPoints(0,0,sz,gj)
      #pv.setLineColor(Color.RED)
      pv.setLineWidth(2.0)

      pv = pp.addPoints(0,0,sff,ff) ## to start plotting at first depth
      pv.setLineColor(Color.BLACK)
      #pv = pp.addPoints(0,0,sgg,gg)
      #pv.setLineColor(Color.RED)
      pv.setLineWidth(2.0)
      """
    if True:
      sp = SimplePlot()
      sp.setSize(750,500)
      sp.setTitle(title)
      sp.setHLabel("Depth (km)")
      sp.setVLabel(vlabel)
      sp.setVLimits(2,2.8)
      #sp.setVLimits(2,6.5)
      pv = sp.addPoints(sk,fk)
      pv.setLineColor(Color.BLACK)
      pv = sp.addPoints(sk,gk)
      pv.setLineColor(Color.RED)

      #pv = pp.addPoints(0,0,sk,fk)
      #pv.setLineColor(Color.BLACK)
      #pv = pp.addPoints(0,0,sk,gk)
      #pv.setLineColor(Color.RED)
      #pv.setLineWidth(2.0)

    #pp = PlotPanel(2,1,PlotPanel.Orientation.X1DOWN_X2RIGHT,PlotPanel.AxesPlacement.LEFT_BOTTOM)
    #pp = PlotPanel(1,2,PlotPanel.Orientation.X1DOWN_X2RIGHT)
    #pf = PlotFrame(pp)
    #pf.setSize(650,800) # for cwpPoster
    #pf.setSize(664,700) # for slides
    #pf.setSize(569,874) # for slides superzoom
    #pf.setSize(700,418) # for slides
    #pf.setSize(658,628)
    #pf.setVisible(True)
    #pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE)
    #pf.setFontSizeForSlide(9.5/11.0,15.0/19.0,16.0/9.0) #big
    #pf.setFontSizeForSlide(0.5,1.0,3.0/2.0) # superzoom cwpPoster
    #pf.setFontSizeForSlide(0.4,9.5/11.0,16.0/9.0) # superzoom slides
    #pf.setFontSizeForPrint(8.0,156.3)
    #pf.paintToPng(720.0,2.17,"warps"+str(c)+".png")
    #pf.paintToPng(720.0,2.17,"warps1.png")

def goErrorsIJ():
  #pairs = [(0,4),(4,9),(9,14),(14,17),(17,20)]
  #pairs = [(4,0),(4,9),(4,14),(4,17),(4,20)] # log 4 is nearest to centroid
  #pairs = [(9,15),(15,28),(9,28)]
  #pairs = [(9,14)]
  #pairs = [(0,9)]
  #pairs = [(14,17)]
  pairs = [(0,4)]
  #pairs = [(0,14)]
  sz,f = resample(logs,curve)
  #wlw.setPowError(2.0)
  #wlw.setPowError(1.0)
  #wlw.setPowError(0.5)
  wlw.setPowError(0.25)
  wlw.setMaxShift(250)
  #scale = 40
  #scale =6
  #scale = 2
  #scale = 1.25
  scale = 1.0
  for pair in pairs:
    ia,ib = pair[0],pair[1]
    e = wlw.computeErrorsIJ(f[ia],f[ib])
    ni,nj = len(e[0]),len(e)
    maxerr = max(e)
    #maxerr = -100000000
    norme = zerofloat(nj,ni)
    """
    for i in range(892,1142):
      for j in range(892,1142):
        if e[i][j] > maxerr:
          maxerr = e[i][j]
    for i in range(892,1142):
      for j in range(892,1142):
    """
    for i in range(ni):
      for j in range(nj):
        norme[i][j] = scale*e[i][j]/maxerr
    """
    ee = zerofloat(nj,ni)
    ee[1005][1005] = norme[1005][1005]
    #ee[1005][1006] = norme[1005][1006]
    #ee[1005][1007] = norme[1005][1007]
    #ee[1005][1008] = norme[1005][1008]
    #ee[1005][1009] = norme[1005][1009]
    """
    si = Sampling(ni,1,0)
    sj = Sampling(nj,1,0)
    title = "("+str(ia)+","+str(ib)+")"
    sp = SimplePlot()
    #sp.setSize(700,700)
    sp.setSize(910,700)
    #sp.setTitle(title)
    sp.setVLabel("Log 2 depth index j") ##### make sure to change log #
    sp.setHLabel("Log 1 depth index i") ##### make sure to change log #
    sp.setHFormat("%5f")
    #sp.setHLimits(1335,1350) # for print
    #sp.setVLimits(20,32) # for print
    #sp.setHLimits(1200,2100) #########
    #sp.setVLimits(-250,-75) #########
    #sp.setVLimits(-105,-95) #stencil
    #sp.setHLimits(2725,2740) #stencil
    sp.setVLimits(892,1142)
    sp.setHLimits(892,1142)
    #sp.setVLimits(1005,1025)
    #sp.setHLimits(1005,1025)
    sp.addColorBar("e[i,j]")
    #pv = sp.addPixels(sj,si,transpose(e))
    pv = sp.addPixels(sj,si,transpose(norme))
    #pv = sp.addPixels(sj,si,transpose(ee))
    #pv.setColorModel(cjet)
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    #pv.setPercentiles(0,80)
    pv.setClips(0,1)
    sp.setFontSizeForSlide(0.6,9.5/11.0,16.0/9.0)
    #sp.setFontSizeForPrint(8.0,222.0)
    #sp.paintToPng(720.0,3.08,"ijaezoom.png")
    #sp.paintToPng(720.0,3.08,"ijaepath200.png")

    d = wlw.accumulateErrorsIJ(norme)
    sp = SimplePlot()
    sp.setSize(910,700)
    #sp.setTitle(title)
    sp.setVLabel("Log 2 depth index j") ##### make sure to change log #
    sp.setHLabel("Log 1 depth index i") ##### make sure to change log #
    sp.setHFormat("%5f")
    sp.setVLimits(892,1142)
    sp.setHLimits(892,1142)
    sp.addColorBar("Accumulated e[i,j]")
    pv = sp.addPixels(si,sj,transpose(d))
    #pv.setColorModel(cjet)
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    #pv.setPercentiles(0,85)
    pv.setClips(10,110)
    sp.setFontSizeForSlide(0.6,9.5/11.0,16.0/9.0)
    sp.paintToPng(720.0,3.08,"aaezoom.png")
    #iw,jw = wlw.findWarping(d)
    #iw = wlw.toFloat(iw)
    #jw = wlw.toFloat(jw)
    #pv = sp.addPoints(iw,jw)
    #pv.setLineColor(Color.WHITE)

def goErrors():
  #pairs = [(0,4),(4,9),(9,14),(14,17),(17,20)]
  #pairs = [(4,0),(4,9),(4,14),(4,17),(4,20)] # log 4 is nearest to centroid
  #pairs = [(9,15),(15,28),(9,28)]
  #pairs = [(9,14)]
  #pairs = [(0,9)]
  #pairs = [(14,17)]
  #pairs = [(0,4)]
  #pairs = [(3,4),(4,7),(21,22),(66,88)] # log 4 is nearest to centroid
  pairs = [(50,81)] # log 4 is nearest to centroid
  sz,f = resample(logs,curve)
  #wlw.setPowError(0.15)
  wlw.setPowError(0.25)
  wlw.setMaxShift(250)
  for pair in pairs:
    ia,ib = pair[0],pair[1]
    e = wlw.computeErrors(f[ia],f[ib])
    wlw.interpolateOddErrors(e)
    nl,nk = len(e[0]),len(e)
    lmax = (nl-1)/2
    lmin = -lmax
    maxerr = max(e)
    #maxerr = -100000000
    norme = zerofloat(nl,nk)
    """
    for k in range(1900,2100):
      for l in range(-120,60):
        if e[k][l] > maxerr:
          maxerr = e[k][l]
          print maxerr
    for k in range(1900,2100):
      for l in range(-120,60):
    """
    for k in range(nk):
      for l in range(nl):
        norme[k][l] = e[k][l]/maxerr
    sl = Sampling(nl,1,lmin)
    sk = Sampling(nk,1,0)
    title = "("+str(ia)+","+str(ib)+")"
    sp = SimplePlot()
    sp.setSize(780,555) #zoom
    #sp.setSize(910,700) #big
    #sp.setSize(750,518)
    #sp.setTitle(title)
    sp.setHLabel("Depth index k")
    sp.setVLabel("Lag index l")
    sp.setHFormat("%5f")
    #sp.setHLimits(1335,1350) # for print
    #sp.setVLimits(20,32) # for print
    #sp.setHLimits(1200,2100) #########
    #sp.setVLimits(-250,-75) #########
    #sp.setVLimits(-105,-95) #stencil
    #sp.setHLimits(2725,2740) #stencil
    #sp.setVLimits(-250,250)
    #sp.setHLimits(1784,2284)
    #sp.setVLimits(-120,60)
    #sp.setHLimits(1900,2100)
    sp.addColorBar("e[k,l]")
    pv = sp.addPixels(sk,sl,transpose(norme))
    #pv = sp.addPixels(sk,sl,transpose(e))
    #pv.setColorModel(cjet)
    pv.setColorModel(ColorMap.GRAY)
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    pv.setPercentiles(0,100)
    #sp.setFontSizeForSlide(0.6,9.5/11.0,16.0/9.0)
    #sp.setFontSizeForPrint(8.0,222.0)
    #sp.paintToPng(720.0,3.08,"stencil.png")
    sp1 = SimplePlot()
    sp1.setSize(780,555)
    #sp1.setSize(910,700)
    #sp1.setSize(750,500)
    #sp1.setTitle(title)
    sp1.setHLabel("Depth index k")
    sp1.setVLabel("Lag index l")
    sp1.setHFormat("%5f")
    #sp1.setHLimits(1200,2100) ##########
    #sp1.setVLimits(-250,-75) ##########
    #sp1.setVLimits(-120,60)
    #sp1.setHLimits(1900,2100)
    #sp1.setVLimits(-250,250)
    #sp1.setHLimits(1784,2284)
    sp1.addColorBar("e[k,l]")
    pv = sp1.addPixels(sk,sl,transpose(norme))
    #pv = sp1.addPixels(sk,sl,transpose(e))
    #pv.setColorModel(cjet)
    pv.setColorModel(ColorMap.GRAY)
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    pv.setPercentiles(0,100)
    d = wlw.accumulateErrors(e)
    wlw.interpolateOddErrors(d)
    kw,lw = wlw.findWarping(d)
    kw = wlw.toFloat(kw)
    lw = wlw.toFloat(lw)
    pv1 = sp1.addPoints(kw,lw)
    pv1.setLineColor(Color.RED)
    pv1.setLineStyle(PointsView.Line.DASH)
    pv1.setLineWidth(4.0)
    #sp1.setFontSizeForSlide(0.6,9.5/11.0,16.0/9.0)
    #sp1.paintToPng(720.0,3.08,"klaepath.png")
    sp = SimplePlot()
    sp.setSize(750,500)
    sp.setTitle(title)
    sp.setHLabel("Depth index k")
    sp.setVLabel("Lag index l")
    sp.setHFormat("%5f")
    pv = sp.addPixels(sk,sl,transpose(d))
    pv.setColorModel(cjet)
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    pv.setPercentiles(0,90)
    kw,lw = wlw.findWarping(d)
    kw = wlw.toFloat(kw)
    lw = wlw.toFloat(lw)
    pv = sp.addPoints(kw,lw)
    pv.setLineColor(Color.WHITE)
    """

    #pp = PlotPanel(2,1,PlotPanel.Orientation.X1DOWN_X2RIGHT,PlotPanel.AxesPlacement.LEFT_BOTTOM)
    #pp = PlotPanel(1,2,PlotPanel.Orientation.X1DOWN_X2RIGHT)
    pp = PlotPanel(2,1)
    pp.setSize(750,500)
    pp.setVLabel(0,"Lag index l")
    pp.setVLabel(1,"Lag index l")
    pp.setHLabel("Depth index k")
    pp.setHFormat("%5f")
    pp.addColorBar("e[k,l]")
    pp.setHLimits(2550,2850) 
    pp.setVLimits(0,-130,-70) 
    pp.setVLimits(1,-130,-70) 
    pv = pp.addPixels(0,0,sk,sl,transpose(e))
    #pv.setColorModel(cjet)
    pv.setColorModel(ColorMap.GRAY)
    #pv.setClips(0.0,0.5)
    #pv.setClips(0,1)
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    pv.setPercentiles(0,100)
    pv = pp.addPixels(1,0,sk,sl,transpose(e))
    #pv.setColorModel(cjet)
    pv.setColorModel(ColorMap.GRAY)
    #pv.setClips(0.2,0.7)
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    pv.setPercentiles(0,100)
    pv1 = pp.addPoints(1,0,kw,lw)
    pv1.setLineColor(Color.WHITE)
    pf = PlotFrame(pp)
    pf.setVisible(True)
    pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE)
    #pf.setFontSizeForPrint(8.0,222.0)
    #pf.paintToPng(720.0,3.08,"ae.png")
    """

def goResample():
  nlog = len(logs)
  sz,f = resample(logs,curve)
  f = wlw.replaceNulls(f,-0.01)
  c = 0
  for j in range(len(f[0])):
    if f[0][j] != -0.01:
      c +=1
  for j in range(len(f[4])):
    if f[4][j] != -0.01:
      c +=1
  for j in range(len(f[9])):
    if f[9][j] != -0.01:
      c +=1
  for j in range(len(f[14])):
    if f[14][j] != -0.01:
      c +=1
  for j in range(len(f[17])):
    if f[17][j] != -0.01:
      c +=1
  for j in range(len(f[20])):
    if f[20][j] != -0.01:
      c +=1
  print c
  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  sp.setVLabel("Depth (km)")
  sp.setHLabel("Log index")
  sp.addColorBar() #("Velocity (km/s)")
  pv = sp.addPixels(sz,Sampling(nlog),f)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(ajet)
  if curve=="v":
    pv.setClips(2.0,6.0)
  elif curve=="d":
    pv.setClips(2.0,2.8)
  elif curve=="p":
    pv.setClips(0.0,0.5)
  elif curve=="g":
    pv.setClips(50,250)

def goSort():
  x,y = [],[]
  for index,log in enumerate(logs):
    x.append(log.x2[0])
    y.append(log.x3[0])
  seis = readImage()
  nx = len(seis)
  ny = len(seis[0])
  dy = 0.025
  dx = 0.025
  sx = Sampling(nx,dx,0.0)
  sy = Sampling(ny,dx,0.0)
  ss = zerofloat(ny,nx)
  for ix in range(nx):
    for iy in range(ny):
      ss[ix][iy] = seis[ix][iy][500]
  sp = SimplePlot()
  sp.addPixels(sy,sx,ss)
  sp.setSize(700,380) # for slide
  sp.setHLabel("Crossline (km)")
  sp.setVLabel("Inline (km)")
  #sp.setLimits(0.0,0.0,9.0,4.0)
  #pv = sp.addPoints(x,y)
  #pv.setMarkStyle(PointsView.Mark.FILLED_CIRCLE)
  #pv.setMarkSize(6)
  if curve=="g":
    x = [x[ 6],x[16],x[18],x[31],x[32],x[33],x[36],
        x[38],x[48],x[55],x[86]] # deepest 11 gamma logs
    y = [y[ 6],y[16],y[18],y[31],y[32],y[33],y[36],
        y[38],y[48],y[55],y[86]] # deepest 11 gamma logs
    pv = sp.addPoints(x,y)
    pv.setLineStyle(PointsView.Line.NONE)
    pv.setMarkStyle(PointsView.Mark.FILLED_CIRCLE)
    pv.setMarkSize(10)
    pv.setMarkColor(Color.RED)
  if curve=="p":
    x = [x[16],x[18],x[19],x[28],x[33],
          x[34],x[35],x[37],x[38],x[39],
          x[45],x[50],x[68]] # deepest 13 porosity logs
    y = [y[16],y[18],y[19],y[28],y[33],
          y[34],y[35],y[37],y[38],y[39],
          y[45],y[50],y[68]] # deepest 13 porosity logs
    pv = sp.addPoints(x,y)
    pv.setLineStyle(PointsView.Line.SOLID)
    pv.setMarkStyle(PointsView.Mark.FILLED_CIRCLE)
    pv.setMarkSize(10)
    pv.setMarkColor(Color.RED)
  if curve=="v":
    """
    x = [x[0],x[4],x[9],x[14],x[17],x[20]]
    y = [y[0],y[4],y[9],y[14],y[17],y[20]]
    pv = sp.addPoints(x,y)
    pv.setLineStyle(PointsView.Line.NONE)
    pv.setMarkStyle(PointsView.Mark.FILLED_CIRCLE)
    pv.setMarkSize(10)
    pv.setMarkColor(Color.RED)
    """
    x1 = [x[0],x[4]]
    y1 = [y[0],y[4]]
    pv = sp.addPoints(x1,y1)
    pv.setMarkStyle(PointsView.Mark.FILLED_CIRCLE)
    pv.setMarkColor(Color.RED)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    pv.setMarkSize(10)
    x1 = [x[0],x[9]]
    y1 = [y[0],y[9]]
    pv = sp.addPoints(x1,y1)
    pv.setMarkStyle(PointsView.Mark.FILLED_CIRCLE)
    pv.setMarkColor(Color.RED)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    pv.setMarkSize(10)
    x1 = [x[0],x[14]]
    y1 = [y[0],y[14]]
    pv = sp.addPoints(x1,y1)
    pv.setMarkStyle(PointsView.Mark.FILLED_CIRCLE)
    pv.setMarkColor(Color.RED)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    pv.setMarkSize(10)
    x1 = [x[0],x[17]]
    y1 = [y[0],y[17]]
    pv = sp.addPoints(x1,y1)
    pv.setMarkStyle(PointsView.Mark.FILLED_CIRCLE)
    pv.setMarkColor(Color.RED)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    pv.setMarkSize(10)
    x1 = [x[0],x[20]]
    y1 = [y[0],y[20]]
    pv = sp.addPoints(x1,y1)
    pv.setMarkStyle(PointsView.Mark.FILLED_CIRCLE)
    pv.setMarkColor(Color.RED)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    pv.setMarkSize(10)
    x1 = [x[4],x[9]]
    y1 = [y[4],y[9]]
    pv = sp.addPoints(x1,y1)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    x1 = [x[4],x[14]]
    y1 = [y[4],y[14]]
    pv = sp.addPoints(x1,y1)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    x1 = [x[4],x[17]]
    y1 = [y[4],y[17]]
    pv = sp.addPoints(x1,y1)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    x1 = [x[4],x[20]]
    y1 = [y[4],y[20]]
    pv = sp.addPoints(x1,y1)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    x1 = [x[9],x[14]]
    y1 = [y[9],y[14]]
    pv = sp.addPoints(x1,y1)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    x1 = [x[9],x[17]]
    y1 = [y[9],y[17]]
    pv = sp.addPoints(x1,y1)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    x1 = [x[9],x[20]]
    y1 = [y[9],y[20]]
    pv = sp.addPoints(x1,y1)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    x1 = [x[14],x[17]]
    y1 = [y[14],y[17]]
    pv = sp.addPoints(x1,y1)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    x1 = [x[14],x[20]]
    y1 = [y[14],y[20]]
    pv = sp.addPoints(x1,y1)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)
    x1 = [x[17],x[20]]
    y1 = [y[17],y[20]]
    pv = sp.addPoints(x1,y1)
    pv.setLineColor(Color.RED)
    pv.setLineWidth(2.0)

  sp.setFontSizeForSlide(1.0,1.0,3.0/2.0) # for CWPposter
  #sp.setFontSizeForSlide(9.5/11.0,1.0,16.0/9.0) # for slide
  #sp.setFontSizeForPrint(8.0,222.0)
  #sp.paintToPng(720.0,3.08,"sortedmesh.png")
  #sp.paintToPng(720.0,3.08,"allVLogs.png")

def goMesh():
  mesh = TriMesh()
  for i,log in enumerate(logs):
    node = TriMesh.Node(log.x2[0],log.x3[0])
    node.index = i
    mesh.addNode(node)
  sp = SimplePlot()
  sp.setSize(700,380)
  sp.setHLabel("Crossline (km)")
  sp.setVLabel("Inline (km)")
  sp.setLimits(0.0,0.0,9.0,4.0)
  tmv = TriMeshView(mesh)
  tmv.setLineColor(Color.BLACK)
  tmv.setMarkColor(Color.BLACK)
  tmv.setTriBoundsVisible(True)
  sp.add(tmv)
  #sp.setFontSizeForPrint(8.0,222.0)
  #sp.paintToPng(720.0,3.08,"mesh.png")

def goShiftTest():
  sz,fs = resample(logs,curve)
  f1 = fs[4]
  nt = len(f1)
  ft = 0
  while(ft<nt and f1[ft]==fnull):
    ft += 1
  lt = nt-1
  while(lt>=0 and f1[lt]==fnull):
    lt -= 1
  nt = 550 
  #nt = lt-ft+1
  fl = fillfloat(fnull,nt) 
  for i in range(ft,501):
  #for i in range(ft,lt+1):
    #fl[i-ft] = f1[i]
    fl[i-ft+50] = f1[i]
  f1=copy(fl)
  samp = Sampling(nt,sz.delta,0.0)
  sz = samp
    
  f2 = fillfloat(fnull,nt) 
  f3 = fillfloat(fnull,nt) 
  f4 = fillfloat(fnull,nt) 

  sh = 100
  sh2 = -40 
  for i in range(nt-sh):
    f3[i+sh] = f1[i] 
  for i in range(-sh2,nt):
    f4[i+sh2] = f1[i] 
  for i in range(nt-sh/2):
    f2[i+sh/2] = f1[i] 
  for i in range(nt-sh/2,nt):
    f2[i] = fnull

  fs = [f1,f3,f4]
  fs1 = [f1]
  fs2 = [f3]
  fs3 = [f4]
  wl = [fs1,fs2,fs3]
  fst = [f2,f2,f2]
  nk,nl = len(fs[0]),len(fs)
  wlw.setPowError(0.25)
  wlw.setMaxShift(250)
  #s = wlw.findShifts(fs)
  s = wlw.findShifts(weights, wl)
  gs = wlw.applyShifts(fs,s)
  s = mul(1000*sz.delta,s) # convert shifts to m
  freplace = 2.0
  fclips = (2.0,6.0)
  cblabel = "Velocity (km/s)"
  if curve=="d":
    freplace = 1.0
    fclips = (2.0,2.8)
    cblabel = "Density (g/cc)"
  if curve=="p":
    freplace = 0.0
    fclips = (0.0,0.45)
    cblabel = "Porosity"
  if curve=="g":
    freplace = 30.0
    fclips = (30.0,160.0)
    cblabel = "Gamma ray (API)"
  fs = wlw.replaceNulls(fs,freplace)
  gs = wlw.replaceNulls(gs,freplace)

  pp = PlotPanel(PlotPanel.Orientation.X1DOWN_X2RIGHT)
  r = rampfloat(0.0,1.0,nt)
  pv = pp.addPoints(r,s[1]) ## to start plotting at first depth
  pv.setLineColor(Color.RED)
  pv = pp.addPoints(r,s[0]) ## to start plotting at first depth
  pv.setLineColor(Color.BLACK)
  #pv = pp.addPoints(r,mm) ## to start plotting at first depth
  #pv.setLineColor(Color.PINK)
  pp.setHLimits(-80,80)
  pf = PlotFrame(pp)
  pf.setSize(500,900) # CWPposter
  pf.setVisible(True)
  pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE)

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,550)
  sp.setSize(500,900) # for slides
  sp.setVLabel("Depth (km)")
  sp.setHLabel("Log index")
  sp.addColorBar(cblabel)
  sp.plotPanel.setColorBarWidthMinimum(90)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),fs)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),fs)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,508) # zoom & werror
  sp.setSize(500,900) # for slides
  sp.setVLabel("Relative geologic time")
  sp.setHLabel("Log index")
  sp.setTitle("Computed alignment")
  sp.addColorBar(cblabel)
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),gs)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),gs)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,550)
  sp.setSize(500,900) # for slides
  sp.setVLabel("Relative geologic time")
  sp.setHLabel("Log index")
  sp.setTitle("True alignment")
  sp.addColorBar(cblabel)
  sp.plotPanel.setColorBarWidthMinimum(90)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),fs)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),fst)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,508) # zoom & werror
  sp.setSize(500,900) # for slides
  sp.setVLabel("Relative geologic time")
  sp.setHLabel("Log index")
  sp.addColorBar("shifts")
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),s)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),s)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)

def goShiftGapTest():
  sz,fs = resample(logs,curve)
  f1 = fs[4]
  nt = len(f1)
  ft = 0
  while(ft<nt and f1[ft]==-999.2500):
    ft += 1
  lt = nt-1
  while(lt>=0 and f1[lt]==-999.2500):
    lt -= 1
  nt = lt-ft+1
  fl = zerofloat(nt)
  for i in range(ft,lt+1):
    fl[i-ft] = f1[i]
  f1=copy(fl)
  samp = Sampling(nt,sz.delta,0.0)
  sz = samp
    
  f2 = copy(f1)
  f3 = zerofloat(nt)

  for i in range(400,600):
    f2[i] = -999.2500
  for i in range(nt-150):
    f3[i+150] = f2[i] 
  for i in range(nt-150,nt):
    f2[i] = -999.2500

  fs = [f1,f3]
  fs1 = [f1]
  fs2 = [f3]
  wl = [fs1,fs2]
  fst = [f1,f2]
  nk,nl = len(fs[0]),len(fs)
  wlw.setPowError(0.25)
  wlw.setMaxShift(250)
  #s = wlw.findShifts(fs)
  s = wlw.findShifts(weights, wl)
  gs = wlw.applyShifts(fs,s)
  s = mul(1000*sz.delta,s) # convert shifts to m
  freplace = 2.0
  fclips = (2.0,6.0)
  cblabel = "Velocity (km/s)"
  if curve=="d":
    freplace = 1.0
    fclips = (2.0,2.8)
    cblabel = "Density (g/cc)"
  if curve=="p":
    freplace = 0.0
    fclips = (0.0,0.45)
    cblabel = "Porosity"
  if curve=="g":
    freplace = 30.0
    fclips = (30.0,160.0)
    cblabel = "Gamma ray (API)"
  fs = wlw.replaceNulls(fs,freplace)
  gs = wlw.replaceNulls(gs,freplace)

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,550)
  sp.setSize(700,380) # for slides
  sp.setVLabel("Depth (km)")
  sp.setHLabel("Log index")
  sp.addColorBar(cblabel)
  sp.plotPanel.setColorBarWidthMinimum(90)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),fs)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),fs)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,508) # zoom & werror
  sp.setSize(700,380) # for slides
  sp.setVLabel("Relative geologic time")
  sp.setHLabel("Log index")
  sp.setTitle("Computed alignment")
  sp.addColorBar(cblabel)
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),gs)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),gs)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,550)
  sp.setSize(700,380) # for slides
  sp.setVLabel("Depth (km)")
  sp.setHLabel("Log index")
  sp.setTitle("True alignment")
  sp.addColorBar(cblabel)
  sp.plotPanel.setColorBarWidthMinimum(90)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),fs)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),fst)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,508) # zoom & werror
  sp.setSize(700,380) # for slides
  sp.setVLabel("Relative geologic time")
  sp.setHLabel("Log index")
  sp.addColorBar("shifts")
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),s)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),s)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)

def goUnconformityTest():
  sz,fs = resample(logs,curve)
  f1 = fs[4]
  nt = len(f1)
  ft = 0
  while(ft<nt and f1[ft]==-999.2500):
    ft += 1
  lt = nt-1
  while(lt>=0 and f1[lt]==-999.2500):
    lt -= 1
  nt = lt-ft+1
  fl = zerofloat(nt)
  for i in range(ft,lt+1):
    fl[i-ft] = f1[i]
  f1=copy(fl)
  samp = Sampling(nt,sz.delta,0.0)
  sz = samp
    
  f2 = copy(f1)
  f3 = zerofloat(nt)

  for i in range(400,600):
    f2[i] = -999.2500
  for i in range(400):
    f3[i+100] = f2[i] 
  for i in range(599,nt):
    f3[i-100] = f2[i] 
  #for i in range(nt-200,nt):
  #  f2[i] = -999.2500

  fs = [f1,f3]
  fs1 = [f1]
  fs2 = [f3]
  wl = [fs1,fs2]
  fst = [f1,f2]
  nk,nl = len(fs[0]),len(fs)
  wlw.setPowError(0.25)
  wlw.setMaxShift(250)
  #s = wlw.findShifts(fs)
  s = wlw.findShifts(weights, wl)
  gs = wlw.applyShifts(fs,s)
  s = mul(1000*sz.delta,s) # convert shifts to m
  freplace = 2.0
  fclips = (2.0,6.0)
  cblabel = "Velocity (km/s)"
  if curve=="d":
    freplace = 1.0
    fclips = (2.0,2.8)
    cblabel = "Density (g/cc)"
  if curve=="p":
    freplace = 0.0
    fclips = (0.0,0.45)
    cblabel = "Porosity"
  if curve=="g":
    freplace = 30.0
    fclips = (30.0,160.0)
    cblabel = "Gamma ray (API)"
  fs = wlw.replaceNulls(fs,freplace)
  gs = wlw.replaceNulls(gs,freplace)

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,550)
  sp.setSize(700,380) # for slides
  sp.setVLabel("Depth (km)")
  sp.setHLabel("Log index")
  sp.addColorBar(cblabel)
  sp.plotPanel.setColorBarWidthMinimum(90)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),fs)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),fs)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,508) # zoom & werror
  sp.setSize(700,380) # for slides
  sp.setVLabel("Relative geologic time")
  sp.setHLabel("Log index")
  sp.setTitle("Computed alignment")
  sp.addColorBar(cblabel)
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),gs)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),gs)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,550)
  sp.setSize(700,380) # for slides
  sp.setVLabel("Depth (km)")
  sp.setHLabel("Log index")
  sp.setTitle("True alignment")
  sp.addColorBar(cblabel)
  sp.plotPanel.setColorBarWidthMinimum(90)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),fs)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),fst)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,508) # zoom & werror
  sp.setSize(700,380) # for slides
  sp.setVLabel("Relative geologic time")
  sp.setHLabel("Log index")
  sp.addColorBar("shifts")
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),s)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),s)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)

def goCreateLog():
  el = 1000 # end sample of short log
  sz,fs = resample(logs,curve)
  f1 = fs[4]
  nt = len(f1)
  ft = 0
  while(ft<nt and f1[ft]==-999.2500):
    ft += 1
  lt = nt-1
  while(lt>=0 and f1[lt]==-999.2500):
    lt -= 1
  nt = lt-ft+1
  fl = zerofloat(nt)
  for i in range(ft,lt+1):
    fl[i-ft] = f1[i]
  f1=fl
  samp = Sampling(nt,sz.delta,0.0)
  sz = samp
    
  r1 = zerofloat(nt)
  r2 = zerofloat(nt)
  r3 = zerofloat(nt)
  r21 = zerofloat(nt)
  r31 = zerofloat(nt)
  r32 = zerofloat(nt)
  kr = zerofloat(nt)
  f2 = zerofloat(nt)
  f3 = zerofloat(nt)
  tk1 = zerofloat(nt)
  tk2 = zerofloat(nt)
  tk3 = zerofloat(nt)
  ff = zerofloat(nt,4)
  ff[0] = f1
  for t in range(nt):
    r1[t] = 0
    #r2[t] = 0.1*(nt-1-t)
    r2[t] = 0.1*t
    #r2[t] = 3*sqrt(t)
    r3[t] = 0
    #r3[t] = -0.1*t
  f2 = wlw.applyRGTShifts(f1,r2)
  f3 = wlw.applyRGTShifts(f1,r3)
  #f1 = wlw.applyRGTShifts(f1,r1)
  #for t in range(500,nt-70):
    #f2[t] = f2[t+70]
  #for t in range(el,el+200):
    #f3[t] = -999.2500
  for t in range(nt):
    r21[t] = -r2[t]#+r1[t]
    r31[t] = -r3[t]#+r1[t]
    r32[t] = r2[t]#-r3[t]
  for ik in range(nt):
    tk1[ik] = ik+r1[ik]
    tk2[ik] = ik+r2[ik]
    tk3[ik] = ik+r3[ik]
  tk = [tk1,tk2,tk3]
  """
  freplace = 2.0
  f1 = wlw.replaceNulls(f1,freplace)
  f2 = wlw.replaceNulls(f2,freplace)
  f3 = wlw.replaceNulls(f3,freplace)
  sp = SimplePlot()
  pv1 = sp.addPoints(r1)
  pv1 = sp.addPoints(r2)
  pv1 = sp.addPoints(r3)
  pv1 = sp.addPoints(f1)
  pv2 = sp.addPoints(f2)
  pv2.setLineColor(Color.RED)
  pv3 = sp.addPoints(f3)
  pv3.setLineColor(Color.BLUE)
  """

  #nt = 30
  #nt = 150
  nt = 1500

  ft1 = zerofloat(nt)
  ft2 = zerofloat(nt)
  ft3 = zerofloat(nt)
  """
  for i in range(2*nt,3*nt):
    ft1[i-2*nt] = f1[i]
    ft2[i-2*nt] = f2[i]
    ft3[i-2*nt] = f3[i]
  """

  for i in range(nt):
    ft1[i] = f1[i]
    ft2[i] = f2[i]
    ft3[i] = f3[i]
    #print("t1=",tk[0][i]," t2=",tk[1][i])

  #fs = [f1,f2]
  #fs = [ft1,ft2]
  fs = [ft1,ft2,ft3]
  #fs = [f1,f2,f3]
  rs = [r1,r2,r3]
  nk,nl = len(fs[0]),len(fs)
  wlw.setPowError(0.25)
  wlw.setMaxShift(250)
  s = wlw.findShifts(fs)
  
  nk = len(s[0])
  nl = len(s)
  sc = zerofloat(nk,nl)
  scale = 0.0;
  for k in range(1,nk):
    if (k%5==0):
      scale += 1.0
    sc[1][k] = scale

  #mi = zeroint(300)
  #mj = zeroint(300)
  #ramp(0,1,mi)

  #for k in range(300):
  #  mj[k] = floor(mi[k]*0.2+0.5)

  """
  scale = 0.0;
  for k in range(1,nk):
    if (k%5==0):
      scale += 1.0
    sc[1][k] = scale
    #sc[1] = mj[k] - mi[k]
  """

  diff = zerofloat(nk,nl)
  for l in range(nl):
    for k in range(nk):
      diff[l][k] = sc[l][k] - s[l][k]
  """
  for l in range(nl):
    print "LOG", l
    for k in range(1,nk):
      print diff[l][k]-diff[l][k-1]
  for l in range(nl):
    print "LOG", l
    for k in range(1,nk):
      if diff[l][k]!=0:
        print s[l][k]/diff[l][k]
  """

  #mm = zerofloat(nk)
  #for k in range(nk):
    #mm[k] = 0.165*k

  print "DIFF"
  #dump(diff)
  """
  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  sp.setSize(700,380) # for slides
  sp.addColorBar("shifts")
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(s)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  sp.setSize(700,380) # for slides
  sp.addColorBar("expected")
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(sc)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  sp.setSize(700,380) # for slides
  sp.addColorBar("diff")
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(diff)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  """

  pp = PlotPanel(PlotPanel.Orientation.X1DOWN_X2RIGHT)
  r = zerofloat(len(diff[0]))
  ramp(0,1,r)
  #pv = pp.addPoints(r,diff[1]) ## to start plotting at first depth
  #pv.setLineColor(Color.BLACK)
  #pv = pp.addPoints(r,sc[1]) ## to start plotting at first depth
  #pv.setLineColor(Color.BLUE)
  pv = pp.addPoints(r,s[1]) ## to start plotting at first depth
  pv.setLineColor(Color.RED)
  pv = pp.addPoints(r,s[0]) ## to start plotting at first depth
  pv.setLineColor(Color.BLACK)
  #pp.setVLimits(0,100)
  #pp.setHLimits(0,20)
  #pv = pp.addPoints(r,mm) ## to start plotting at first depth
  #pv.setLineColor(Color.PINK)
  pf = PlotFrame(pp)
  pf.setSize(664,700) # for slides
  pf.setVisible(True)
  pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE)
  """
  #pp = PlotPanel(PlotPanel.Orientation.X1DOWN_X2RIGHT)
  #r = zerofloat(len(diff[0]))
  #ramp(0,1,r)
  #pv = pp.addPoints(r,diff[0]) ## to start plotting at first depth
  #pv.setLineColor(Color.BLACK)
  #pv = pp.addPoints(r,sc[0]) ## to start plotting at first depth
  #pv.setLineColor(Color.BLUE)
  #pv = pp.addPoints(r,s[0]) ## to start plotting at first depth
  #pv.setLineColor(Color.RED)
  #pp.setVLimits(0,100)
  #pp.setHLimits(0,20)
  #pv = pp.addPoints(r,mm) ## to start plotting at first depth
  #pv.setLineColor(Color.PINK)
  pf = PlotFrame(pp)
  pf.setSize(664,700) # for slides
  pf.setVisible(True)
  pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE)
  """


  gs = wlw.applyShifts(fs,s)
  s = mul(1000*sz.delta,s) # convert shifts to m
  freplace = 2.0
  fclips = (2.0,6.0)
  cblabel = "Velocity (km/s)"
  if curve=="d":
    freplace = 1.0
    fclips = (2.0,2.8)
    cblabel = "Density (g/cc)"
  if curve=="p":
    freplace = 0.0
    fclips = (0.0,0.45)
    cblabel = "Porosity"
  if curve=="g":
    freplace = 30.0
    fclips = (30.0,160.0)
    cblabel = "Gamma ray (API)"
  fs = wlw.replaceNulls(fs,freplace)
  gs = wlw.replaceNulls(gs,freplace)
  #ff[1] = gs[0]
  #ff[2] = gs[1]
  #ff[3] = gs[2]

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,550)
  sp.setSize(700,380) # for slides
  sp.setVLabel("Depth (km)")
  sp.setHLabel("Log index")
  sp.addColorBar(cblabel)
  sp.plotPanel.setColorBarWidthMinimum(90)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),fs)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),fs)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])

  """
  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,550)
  sp.setSize(700,380) # for slides
  sp.setVLabel("Depth (km)")
  sp.setHLabel("Log index")
  sp.addColorBar("RGT")
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(sz,Sampling(nl,1,1),tk)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,550)
  sp.setSize(700,380) # for slides
  sp.setVLabel("Depth (km)")
  sp.setHLabel("Log index")
  sp.addColorBar("Actual shift")
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(sz,Sampling(nl,1,1),rs)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,508) # zoom & werror
  sp.setSize(700,380) # for slides
  sp.setVLabel("Relative geologic time")
  sp.setHLabel("Log index")
  sp.addColorBar(cblabel)
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(ff)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])
  """

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,508) # zoom & werror
  sp.setSize(700,380) # for slides
  sp.setVLabel("Relative geologic time")
  sp.setHLabel("Log index")
  sp.addColorBar(cblabel)
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),gs)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),gs)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  pv.setClips(fclips[0],fclips[1])

  sp = SimplePlot(SimplePlot.Origin.UPPER_LEFT)
  #sp.setSize(650,508) # zoom & werror
  sp.setSize(700,380) # for slides
  sp.setVLabel("Relative geologic time")
  sp.setHLabel("Log index")
  sp.addColorBar("shifts")
  sp.plotPanel.setColorBarWidthMinimum(90)
  pv = sp.addPixels(Sampling(nt,1,1),Sampling(nl,1,1),s)
  #pv = sp.addPixels(sz,Sampling(nl,1,1),s)
  pv.setInterpolation(PixelsView.Interpolation.NEAREST)
  pv.setColorModel(cjet)
  """
    
  pairs = [(0,1),(1,2),(0,2)]
  #f = [f1,f2,f3]
  f = [ft1,ft2,ft3]
  wlw.setPowError(0.25)
  wlw.setMaxShift(250)
  for pair in pairs:
    ia,ib = pair[0],pair[1]
    e = wlw.computeErrors(f[ia],f[ib])
    wlw.interpolateOddErrors(e)
    nl,nk = len(e[0]),len(e)
    lmax = (nl-1)/2
    lmin = -lmax
    sl = Sampling(nl,1,lmin)
    sk = Sampling(nk,1,0)
    title = "("+str(ia)+","+str(ib)+")"
    sp = SimplePlot()
    sp.setSize(750,518)
    sp.setTitle(title)
    sp.setHLabel("Depth index k")
    sp.setVLabel("Lag index l")
    sp.setHFormat("%5f")
    sp.addColorBar("e[k,l]")
    pv = sp.addPixels(sk,sl,transpose(e))
    #pv.setColorModel(cjet)
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    pv.setPercentiles(0,100)

    sp1 = SimplePlot()
    sp1.setSize(750,518)
    sp1.setTitle(title)
    sp1.setHLabel("Depth index k")
    sp1.setVLabel("Lag index l")
    sp1.setHFormat("%5f")
    sp1.addColorBar("e[k,l]")
    pv = sp1.addPixels(sk,sl,transpose(e))
    #pv.setColorModel(cjet)
    pv.setInterpolation(PixelsView.Interpolation.NEAREST)
    pv.setPercentiles(0,100)
    d = wlw.accumulateErrors(e)
    wlw.interpolateOddErrors(d)
    kw,lw = wlw.findWarping(d)
    kw = wlw.toFloat(kw)
    lw = wlw.toFloat(lw)
    for t in range(nt):
      kr[t] = 2*t
    pv1 = sp1.addPoints(kw,lw)
    pv1.setLineColor(Color.RED)
    #pv2 = sp1.addPoints(kr,r21)
    #pv2.setLineColor(Color.BLUE)
    #pv1.setLineStyle(PointsView.Line.DASH)
    pv1.setLineWidth(1.0)

  """


#############################################################################
# utilities

_tpDir = "/data/seis/tpd/"
_csmDir = _tpDir+"csm/"
_wellLogsDir = _csmDir+"welllogs/"
_seismicLogsDir = _csmDir+"seismicz/"
_pngDir = "/Users/lwheeler/Documents/01_School/01_Grad/04_Research/png/"
  
def getWells(set,curves):
  vlogs = False
  dlogs = False
  glogs = False
  plogs = False
  for c in curves:
    if (c=="v"):
      vlogs = True
    if (c=="d"):
      dlogs = True
    if (c=="g"):
      glogs = True
    if (c=="p"):
      plogs = True
      
  fileName = _wellLogsDir+"tpw"+set[0]+".dat"
  wdata = WellLog.Data.readBinary(fileName)
  wells = []
  wellt = wdata.getAll()
  for well in wellt:
    if (vlogs == False):
      well.v = None
    if (dlogs == False):
      well.d = None
    if (glogs == False):
      well.g = None
    if (plogs == False):
      well.p = None
    wells.append(well)
  wellNotNull = []
  for well in wells:
    if (well.v!=None or well.g!=None or well.d!=None or well.p!=None):
        wellNotNull.append(well)
  wellNotNull = sortLogs(wellNotNull) 
  return wellNotNull

""" # for choosing which curves
def getLogsMulti(set,types):
  fileName = _wellLogsDir+"tpw"+set[0]+".dat"
  wdata = WellLog.Data.readBinary(fileName)
  logsall = []
  for t in types:
    #print "log type=",t
    logs = []
    logt = wdata.getLogsWith(t)
    for log in logt:
      logs.append(log)
    logs = sortLogs(logs)
    logsall.append(logs)
  return logsall
"""

def getLogs(set,type):
  fileName = _wellLogsDir+"tpw"+set[0]+".dat"
  wdata = WellLog.Data.readBinary(fileName)
  logs = []
  logt = wdata.getLogsWith(type)
  for log in logt:
    logs.append(log)
  logs = sortLogs(logs)
  return logs

def sortLogs(logs):
  nlog = len(logs)
  xlog = zerodouble(nlog)
  ylog = zerodouble(nlog)
  for i,log in enumerate(logs):
    xlog[i] = log.x2[0]
    ylog[i] = log.x3[0]
  j = WellLogWarping.sortWells(xlog,ylog)
  logt = list(logs)
  for i,log in enumerate(logs):
    logt[i] = logs[j[i]]
  return logt

def resampleMulti(wells,curves):
  nc = len(curves)
  nw = len(wells)
  zs = zerofloat(0,nc,nw)
  fs = zerofloat(0,nc,nw)
  for i,well in enumerate(wells):
    for j,curve in enumerate(curves):
      zs[i][j] = well.z
      fs[i][j] = well.getCurve(curve)
      if (fs[i][j]==None):
        fs[i][j] = []
        zs[i][j] = []
  zs = mul(zs,0.0003048) # ft to km
  sz = wlw.getDepthSampling(zs,fs)
  nz,dz,fz,lz = sz.count,sz.delta,sz.first,sz.last
  #print "resample before: nz =",nz," dz =",dz," fz =",fz
  dz = 0.001 # 1 m
  nz = 1+int((lz-fz)/dz)
  sz = Sampling(nz,dz,fz)
  #print "resample  after: nz =",nz," dz =",dz," fz =",fz
  fs = wlw.resampleLogs(sz,zs,fs)
  """
  for i,well in enumerate(wells):
    well.n = nz
    for j,curve in enumerate(curves):
      if (curve=="v"):
        well.v = fs[i][j]
      if (curve=="d"):
        well.d = fs[i][j]
      if (curve=="g"):
        well.g = fs[i][j]
      if (curve=="p"):
        well.p = fs[i][j]
      well.z = zs[i][j] 
  return sz,wells
  """
  return sz,fs

""" # for choosing which curves
def resampleMulti(logs,curves):
  ntype = len(curves)
  nlog = 0
  for i in range(ntype):
    nlog += len(logs[i])
  zs = zerofloat(0,nlog)
  fs = zerofloat(0,nlog)
  k = 0
  for j,ty in enumerate(logs):
    for log in enumerate(ty):
      zs[k] = log.z
      fs[k] = log.getCurve(curves[j])
      k += 1
  zs = mul(zs,0.0003048) # ft to km
  sz = wlw.getDepthSampling(zs,fs)
  nz,dz,fz,lz = sz.count,sz.delta,sz.first,sz.last
  #print "resample before: nz =",nz," dz =",dz," fz =",fz
  dz = 0.001 # 1 m
  nz = 1+int((lz-fz)/dz)
  sz = Sampling(nz,dz,fz)
  #print "resample  after: nz =",nz," dz =",dz," fz =",fz
  fs = wlw.resampleLogs(sz,zs,fs)
  fx = []
  for i in range(ntype):
    n = len(logs[i])
    l = Logs(

  return sz,fs
"""

def resample(logs,curve):
  nlog = len(logs)
  zs = zerofloat(0,nlog)
  fs = zerofloat(0,nlog)
  for i,log in enumerate(logs):
    zs[i] = log.z
    fs[i] = log.getCurve(curve)
  zs = mul(zs,0.0003048) # ft to km
  sz = wlw.getDepthSampling(zs,fs)
  nz,dz,fz,lz = sz.count,sz.delta,sz.first,sz.last
  #print "resample before: nz =",nz," dz =",dz," fz =",fz
  dz = 0.001 # 1 m
  nz = 1+int((lz-fz)/dz)
  sz = Sampling(nz,dz,fz)
  #print "resample  after: nz =",nz," dz =",dz," fz =",fz
  fs = wlw.resampleLogs(sz,zs,fs)
  return sz,fs

def readLogSamples(set,type,smooth=0):
  """ 
  Reads log curves from the specified set that have the specified type.
  set: "s" for shallow, "d" for deep, or "a" for all
  type: "v" (velocity), "d" (density), "p" (porosity), or "g" (gamma)
  smooth: half-width of Gaussian smoothing filter
  Returns a tuple (f,x1,x2,x3) of lists of arrays of samples f(x1,x2,x3)
  """
  logs = getLogs(set,type)
  fl,x1l,x2l,x3l = [],[],[],[]
  for log in logs:
    if smooth: 
      log.smooth(smooth)
    samples = log.getSamples(type)
    if samples:
      f,x1,x2,x3 = samples
      fl.append(f)
      x1l.append(x1)
      x2l.append(x2)
      x3l.append(x3)
  return fl,x1l,x2l,x3l

def getXYLocation(set,type):
  logs = getLogs(set,type)
  nlog = len(logs)
  xlog = zerofloat(nlog)
  ylog = zerofloat(nlog)
  for i,log in enumerate(logs):
    xlog[i] = log.x2[0]
    ylog[i] = log.x3[0]
  return xlog,ylog

def getWellIntersections(set,type,x1):
  fileName = _wellLogsDir+"tpw"+set[0]+".dat"
  wdata = WellLog.Data.readBinary(fileName)
  x2,x3 = wdata.getIntersections(type,x1)
  return x2,x3

def fgood(f):
  n = len(f)
  for i in range(n):
    if f[i]!=-999.2500:
      return i
def lgood(f):
  n = len(f)
  for i in range(n):
    if f[n-1-i]!=-999.2500:
      return n-1-i

def normalizeByMedian(type,curves,wl):
  nl = len(wl)
  nk = len(wl[0][0])
  med = zerofloat(nl)
  for i,c in enumerate(curves):
    if (c==type):
      for j in range(nl):
        nn = 0
        for k in range(nk):
          if (wl[j][i][k]!=-999.2500):
            nn += 1
        mf = MedianFinder(nn)
        temp = zerofloat(nn)
        nn = 0
        for k in range(nk):
          if (wl[j][i][k]!=-999.2500):
            temp[nn] = wl[j][i][k]
            nn += 1
        med[j] = mf.findMedian(temp)
  avm = sum(med)/nl
  for i,c in enumerate(curves):
    if (c==type):
      for j in range(nl):
        sc = avm/med[j]
        for k in range(nk):
          if (wl[j][i][k] != -999.2500):
            wl[j][i][k] *= sc

def readImage():
  fileName = _seismicLogsDir+"tpsz.dat"
  n1,n2,n3 = 2762,357,161
  x = zerofloat(n1,n2,n3)
  ais = ArrayInputStream(fileName,ByteOrder.BIG_ENDIAN)
  ais.readFloats(x)
  ais.close()
  return x

def removeZeros(f):
  n = len(f)
  i = 0
  while f[i] == -2.0:
    i += 1
  fs = zerofloat(n)
  c = 0
  for j in range(i,n):
    fs[c] = f[j]
    if (f[j] == -2.0 and j+2 >= n) or (f[j] == -2.0 and f[j+1] == -2.0
        and f[j+2] == -2.0):
      break
    c += 1
  #ft = zerofloat(c)
  ft = copy(c,fs)
  return i,ft

def writeFile(va):
  nz = len(va[0])
  nl = len(va)
  ofile = open('vlogs.txt','r+')
  for z in range(nz):
    ofile.write(str(z)+'\t'+str(va[0][z])+'\t'+str(va[1][z])+'\t'+
                str(va[2][z])+'\t'+str(va[3][z])+'\t'+str(va[4][z])+'\t'+
                str(va[5][z])+'\n')
  ofile.close()



#############################################################################
# graphics

cjet = ColorMap.JET
alpha = fillfloat(1.0,256); alpha[0] = 0.0
ajet = ColorMap.setAlpha(cjet,alpha)

#############################################################################
# Run the function main on the Swing thread
import sys
from javax.swing import *
class RunMain(Runnable):
  def run(self):
    main(sys.argv)
SwingUtilities.invokeLater(RunMain())
