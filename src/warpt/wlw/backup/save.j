/****************************************************************************
Copyright (c) 2014, Colorado School of Mines and others. All rights reserved.
This program and accompanying materials are made available under the terms of
the Common Public License - v1.0, which accompanies this distribution, and is
available at http://www.eclipse.org/legal/cpl-v10.html
****************************************************************************/
package warpt;

/*
TODO: in preconditioner M, subtract horizontal average of shifts s
*/

import java.util.Random;
import java.awt.Color;

import edu.mines.jtk.dsp.RecursiveExponentialFilter;
import edu.mines.jtk.dsp.Sampling;
import edu.mines.jtk.dsp.Histogram;
import edu.mines.jtk.interp.CubicInterpolator;
import edu.mines.jtk.util.MedianFinder;
import static edu.mines.jtk.util.ArrayMath.*;
import edu.mines.jtk.mosaic.SimplePlot;
import edu.mines.jtk.mosaic.PlotPanel;
import edu.mines.jtk.mosaic.PointsView;
import edu.mines.jtk.mosaic.PlotFrame;
import edu.mines.jtk.mosaic.PixelsView;
import edu.mines.jtk.dsp.Sampling;
import edu.mines.jtk.awt.ColorMap;


import dnp.CgSolver;
import dnp.InverseInterpolator;
import dnp.Vec;
import dnp.VecArrayFloat2;

/**
 * Dynamic warping for alignment of well logs. 
 * <p>
 * This application of dynamic warping differs from others in that it must
 * account for missing log values, and the fact that values in different logs
 * are measured at different depths.
 * <p>
 * The alignment of two log sequences f[i] and g[j] is represented by a
 * sequence of index pairs (i,j). This representation is the same as that
 * proposed by Sakoe and Chiba (1978) in their description of what is now
 * known as dynamic time warping (DTW). However, unlike Sakoe and Chiba, we
 * need not assume that the first and last samples of the sequence f[i] are
 * aligned with the first and last samples of the sequence g[j]. Indeed,
 * that assumption is rarely valid for well log sequences.
 * <p>
 * As for DTW, the first step is to compute alignment errors for all (i,j),
 * subject to the constraint that |j-i|&le;lmax. The difference l = j-i is
 * called lag (or shift), and one can use specified constraints on geologic
 * dip and distances between wells to compute the maximum lag lmax.
 * <p>
 * As noted above, conventional DTW assumes that lag l is zero for the first
 * and last samples of the optimal path. To permit the optimal path to begin
 * and end with non-zero lag, alignment errors are computed in a rotated
 * coordinate system: e[k,l] = pow(abs(f[i]-g[j]),epow), where k = j+i and l =
 * j-i. Here, k = imin+jmin,...,imax+jmax, and l = -lmax,...,lmax. (The
 * zero-based array index for any lag l is simply l+lmax.) When accumulating
 * alignment errors, we begin at kmin = imin+jmin and end at kmax = imax+jmax.
 * <p>
 * Half of the samples in the array of alignment errors e[k,l] are unused,
 * because i = (k-l)/2 and j = (k+l)/2 are integers for only even values of
 * k+l. For display purposes only, errors e[k,l] for which k+l is an odd
 * number may be computed by linear interpolation of the other errors.
 * <p>
 * Alignment errors e[k,l] for two log sequences f[i] and g[j] are computed
 * only for a range of k = i+j for which at least one of the two logs has a
 * non-null value. Within this range, where either f[i] or g[j] is null, the
 * null values are replaced by a non-null value randomly selected from the
 * sequence. This replacement does not actually alter the log sequences, as it
 * occurs only during the computation of alignment errors. Outside of this
 * range, alignment errors are set to a null error. When accumulating
 * alignment errors, any null errors are ignored. Accumulation of alignment
 * errors begins and ends with the first and last indices k for which
 * alignment errors are not null.
 *
 * @author Dave Hale, Colorado School of Mines
 * @version 2014.01.02
 */
public class WellLogWarpingTest {

  /**
   * Sets the maximum shift (lag).
   * @param lmax the maximum lag.
   */
  public void setMaxShift(int lmax) {
    _lmax = lmax;
  }

  /**
   * Sets the exponent (the power) used to compute alignment errors.
   * @param epow the exponent.
   */
  public void setPowError(double epow) {
    _epow = (float)epow;
  }

  /**
   * Sets the alignment error that represents no computed error. 
   * @param enull the null error.
   */
  public void setNullError(float enull) {
    _enull = enull;
  }

  /**
   * Sets the log value that represents no measured value.
   * The default null value is -999.2500.
   * @param vnull the null value.
   */
  public void setNullValue(float vnull) {
    _vnull = vnull;
  }

  /**
   * Returns an array of alignment errors e[k,l] for two sequences.
   * @param f array of values f[i] in 1st log sequence.
   * @param g array of values g[j] in 2nd log sequence.
   * @return array of alignment errors e[k,l].
   */
  public float[][] computeErrors(float[] f, float[] g) {
    int ni = f.length;
    int nj = g.length;
    int lmax = min(max(ni,nj)-1,_lmax);
    int lmin = -lmax;
    int nl = 1+lmax-lmin;
    int nk = ni+nj-1;
    float[][] e = fillfloat(_enull,nl,nk);
    int[] igood = findGood(f);
    int[] jgood = findGood(g);
    int imin = min(igood);
    int imax = max(igood);
    int jmin = min(jgood);
    int jmax = max(jgood);
    int kmin = imin+jmin;
    int kmax = imax+jmax;
    //trace("computeErrors: kmin="+kmin+" kmax="+kmax);
    Random random = new Random(314159);
    for (int k=kmin; k<=kmax; ++k) {
      for (int l=lmin,ll=l-lmin; l<=lmax; ++l,++ll) {
        if ((k+l)%2==0) {
          int i = (k-l)/2;
          int j = (k+l)/2;
          float fi = value(random,igood,f,i);
          float gj = value(random,jgood,g,j);
          e[k][ll] = error(fi,gj);
        }
      }
    }
    return e;
  }
  public float[][] computeErrors(int n, float[] f, float[] g) {
    int ni = f.length;
    int nj = g.length;
    int lmax = min(max(ni,nj)-1,_lmax);
    int lmin = -lmax;
    int nl = 1+lmax-lmin;
    int nk = ni+nj-1;
    float[][] e = fillfloat(_enull,nl,nk);
    int[] igood = findGood(f);
    int[] jgood = findGood(g);
    int imin = min(igood);
    int imax = max(igood);
    int jmin = min(jgood);
    int jmax = max(jgood);
    int kmin = imin+jmin;
    int kmax = imax+jmax;
    //trace("computeErrors: kmin="+kmin+" kmax="+kmax);
    Random random = new Random(314159+n);
    for (int k=kmin; k<=kmax; ++k) {
      for (int l=lmin,ll=l-lmin; l<=lmax; ++l,++ll) {
        if ((k+l)%2==0) {
          int i = (k-l)/2;
          int j = (k+l)/2;
          float fi = value(random,igood,f,i);
          float gj = value(random,jgood,g,j);
          e[k][ll] = error(fi,gj);
        }
      }
    }
    return e;
  }
  //public float[][] computeErrors(int p, float[][] wli, float[][] wlj) {
  public float[][] computeErrors(int p, float[] m, float[][] wi, float[][] wj) {
  //public float[][] computeErrors(float[] m, float[][] wi, float[][] wj) {
    //float[][] wi = copy(wli);
    //float[][] wj = copy(wlj);
    /*
    String cb = "";
    for (int i=0; i<wj.length; ++i) {
      if (i==0) cb = "v before"; 
      if (i==1) cb = "p before"; 
      if (i==2) cb = "d before"; 
      histogram(cb,wi[i]);
    }
    */
    //normalize(wi);
    //normalize(wj);
    /*
    for (int i=0; i<wj.length; ++i) {
      stats(wj[i]);
    }
    for (int i=0; i<wj.length; ++i) {
      if (i==0) cb = "v after"; 
      if (i==1) cb = "p after"; 
      if (i==2) cb = "d after"; 
      histogram(cb,wi[i]);
    }
    */
    int nc = wi.length;
    int ni = wi[0].length;
    int nj = wj[0].length;
    int lmax = min(max(ni,nj)-1,_lmax);
    int lmin = -lmax;
    int nl = 1+lmax-lmin;
    int nk = ni+nj-1;
    float[][] e = fillfloat(_enull,nl,nk);
    int ismin = ni; 
    int ismax = -1; 
    int jsmin = nj;
    int jsmax = -1; 
    int ksmin = nk;
    int ksmax = -1;
    for (int c=0; c<nc; ++c) {
      float[] f = wi[c];
      float[] g = wj[c];
      int[] igood = findGood(f);
      int[] jgood = findGood(g);
      if (igood.length>0 && jgood.length>0) {
        int imin = min(igood);
        int imax = max(igood);
        int jmin = min(jgood);
        int jmax = max(jgood);
        int kmin = imin+jmin;
        int kmax = imax+jmax;
        if (kmin<ksmin) ksmin = kmin;
        if (kmax>ksmax) ksmax = kmax;
      }
      /*
      for (int k=0; k<igood.length; ++k) {
        if (igood[k]<ismin && jgood.length>0) ismin = igood[k];
        if (igood[k]>ismax && jgood.length>0) ismax = igood[k];
      }
      for (int k=0; k<jgood.length; ++k) {
        if (jgood[k]<jsmin && igood.length>0) jsmin = jgood[k];
        if (jgood[k]>jsmax && igood.length>0) jsmax = jgood[k];
      }
      */
    }
    for (int c=0; c<nc; ++c) {
      float[] f = wi[c];
      float[] g = wj[c];
      int[] igood = findGood(f);
      int[] jgood = findGood(g);
      if (igood.length>0 && jgood.length>0) {
        int imin = min(igood);
        int imax = max(igood);
        int jmin = min(jgood);
        int jmax = max(jgood);
        int kmin = imin+jmin;
        int kmax = imax+jmax;
        //trace("computeErrors: kmin="+kmin+" kmax="+kmax);
        Random random = new Random(314159+p);
        if (kmin==ksmin) kmin = 0;
        if (kmax==ksmax) kmax = nk-1;
        for (int k=kmin; k<=kmax; ++k) {
          for (int l=lmin,ll=l-lmin; l<=lmax; ++l,++ll) {
            if ((k+l)%2==0) {
              int i = (k-l)/2;
              int j = (k+l)/2;
              float fi = value(random,igood,f,i)*m[c];
              float gj = value(random,jgood,g,j)*m[c];
                e[k][ll] += error(fi,gj);
            }
          }
        }
      }
    } 
    if (min(e)==_enull && max(e)==_enull) e = null;
    return e;
  }

  /**
   * Returns an array of alignment errors e[i,j] for two sequences.
   * @param f array of values f[i] in 1st log sequence.
   * @param g array of values g[j] in 2nd log sequence.
   * @return array of alignment errors e[i,j].
   */
  public float[][] computeErrorsIJ(float[] f, float[] g) {
    int ni = f.length;
    int nj = g.length;
    float[][] e = fillfloat(_enull,nj,ni);
    int[] igood = findGood(f);
    int[] jgood = findGood(g);
    int imin = min(igood);
    int imax = max(igood);
    int jmin = min(jgood);
    int jmax = max(jgood);
    //trace("computeErrors: kmin="+kmin+" kmax="+kmax);
    Random random = new Random(314159);
    for (int i=imin; i<=imax; ++i) {
      for (int j=jmin; j<=jmax; ++j) {
        float fi = value(random,igood,f,i);
        float gj = value(random,jgood,g,j);
        e[i][j] = error(fi,gj);
      }
    }
    return e;
  }

  /**
   * Returns accumulated errors d[k,l].
   * Any null errors in e[k,l] will be null in d[k,l].
   * @param e array of alignment errors e[k,l].
   * @return array of accumulated errors d[k,l].
   */
  public float[][] accumulateErrors(float[][] e) {
    int nk = e.length;
    int nl = e[0].length;
    int lmax = (nl-1)/2;
    int lmin = -lmax;
    float[][] d = fillfloat(_enull,nl,nk);

    // Range of k for which to accumulate errors.
    int kmin = kminNotNull(e);
    int kmax = kmaxNotNull(e);
    //trace("accumulateErrors: kmin="+kmin+" kmax="+kmax);

    // Special case: k = kmin.
    int k=kmin,km1,km2;
    for (int l=lmin,ll=l-lmin; l<=lmax; ++l,++ll) {
      if ((k+l)%2==0)
        d[k][ll] = e[k][ll];
    }

    // Special case: k = kmin+1.
    k = kmin+1; km1 = k-1;
    for (int l=lmin,ll=l-lmin,lm=ll-1,lp=ll+1; l<=lmax; ++l,++lm,++ll,++lp) {
      if ((k+l)%2==0) {
        float da = lm>=0?d[km1][lm]:FLT_MAX;
        float dc = lp<nl?d[km1][lp]:FLT_MAX;
        d[k][ll] = min(da,dc)+e[k][ll];
      }
    }

    // General case: k = kmin+2 to kmax.
    for (k=kmin+2,km1=k-1,km2=k-2; k<=kmax; ++k,++km1,++km2) {
      for (int l=lmin,ll=l-lmin,lm=ll-1,lp=ll+1; l<=lmax; ++l,++lm,++ll,++lp) {
        if ((k+l)%2==0) {
          float da = lm>=0?d[km1][lm]:FLT_MAX;
          float db =       d[km2][ll];
          float dc = lp<nl?d[km1][lp]:FLT_MAX;
          float dm = dmin(da,db,dc);
          d[k][ll] = dm+e[k][ll];
        }
      }
    }
    return d;
  }

  /**
   * Returns accumulated errors d[i,j].
   * Any null errors in e[i,j] will be null in d[i,j].
   * @param e array of alignment errors e[i,j].
   * @return array of accumulated errors d[i,j].
   */
  public float[][] accumulateErrorsIJ(float[][] e) {
    int ni = e.length;
    int nj = e[0].length;
    float[][] d = fillfloat(_enull,nj,ni);

    // Range of k for which to accumulate errors.
    int imin = iminNotNull(e);
    int imax = imaxNotNull(e);
    int jmin = iminNotNull(e);
    int jmax = imaxNotNull(e);
    //System.out.println("accumulateErrors: imin="+imin+" imax="+imax);
    //System.out.println("accumulateErrors: jmin="+jmin+" jmax="+jmax);
    //trace("accumulateErrors: imin="+imin+" imax="+imax);
    //trace("accumulateErrors: jmin="+jmin+" jmax="+jmax);

    // Special case: i = imin.
    int i=imin,im1;
    for (int jj=jmin; jj<=jmax; ++jj) {
      d[i][jj] = e[i][jj];
    }

    // Special case: j = jmin.
    int j=jmin,jm;
    for (int ii=imin; ii<=imax; ++ii) {
      d[ii][j] = e[ii][j];
    }


    // General case: i = imin+1 to imax.
    for (i=imin+1,im1=i-1; i<=imax; ++i,++im1) {
      for (j=jmin,jm=j-1; j<=jmax; ++j,++jm) {
        float da = d[i][jm];
        float db = d[im1][jm];
        float dc = d[im1][j];
        float dm = dmin(da,db,dc);
        d[i][j] = dm+e[i][j];
      }
    }
    return d;
  }

  /**
   * Returns the optimal warping path as pairs of sample indices (k,l).
   * The pairs are returned as an array of two arrays, one array for the
   * indices k and the other array for the corresponding indices l.
   * @param d array of accumulated errors.
   * @return array[2][] containing indices (k,l). The array[0] will
   *  contain the indices k, and the array[1] will contain the indices l. The
   *  lengths of these two arrays will equal the number of pairs on the
   *  warping path; this number is unknown before the optimal path has been
   *  found.
   */
  public int[][] findWarping(float[][] d) {
    int nk = d.length;
    int nl = d[0].length;
    int lmax = (nl-1)/2;
    int lmin = -lmax;

    // Range of k for which to find the optimal warping path.
    int kmin = kminNotNull(d);
    int kmax = kmaxNotNull(d);
    //trace("findWarping: kmin="+kmin+" kmax="+kmax);

    // Initially empty arrays for (k,l) pairs.
    int nw = 0;
    int[] kw = new int[nk];
    int[] lw = new int[nk];

    // Find lag l with minimum accumulated error at k = kmax.
    int kp = kmax;
    int lp = -1;
    float dp = FLT_MAX;
    for (int l=lmin,ll=0; l<=lmax; ++l,++ll) {
      if ((kp+l)%2==0) {
        if (d[kp][ll]<dp) {
          lp = l;
          dp = d[kp][ll];
        }
      }
    }

    // Add the corresponding pair (k,l) to the path.
    kw[0] = kp;
    lw[0] = lp;
    nw += 1;

    // While the path is not yet complete, backtrack.
    while (kp>kmin) {
      int ll = lp-lmin;
      float da = lp>lmin  ?d[kp-1][ll-1]:FLT_MAX;
      float db = kp>kmin+1?d[kp-2][ll  ]:FLT_MAX;
      float dc = lp<lmax  ?d[kp-1][ll+1]:FLT_MAX;
      float dm = dmin(da,db,dc);
      if (dm==db) {
        kp -= 2;
      } else if (dm==da) {
        kp -= 1;
        lp -= 1;
      } else {
        kp -= 1;
        lp += 1;
      }
      kw[nw] = kp;
      lw[nw] = lp;
      nw += 1;
    }

    // Remove any wasted space from the arrays of indices, while reordering
    // the indices (k,l) so that k are increasing, not decreasing.
    int[] kt = new int[nw];
    int[] lt = new int[nw];
    for (int mw=0; mw<nw; ++mw) {
      kt[mw] = kw[nw-1-mw];
      lt[mw] = lw[nw-1-mw];
    }
    return new int[][]{kt,lt};
  }

  /**
   * Returns an optimal warping path converted from (k,l) to (i,j).
   * Omits any indices (i,j) for which either f[i] is null or g[j] is null.
   * @param kl array[2][] containing indices (k,l). The array[0] contains
   *  the indices k, and the array[1] contains the indices l.
   * @param f array of values f[i] in 1st log sequence.
   * @param g array of values g[j] in 2nd log sequence.
   * @return array[2][] containing indices (i,j). The array[0] contains
   *  the indices i, and the array[1] contains the indices j.
   */
  public int[][] convertWarping(int[][] kl, float[] f, float[] g) {
    int ni = f.length;
    int nj = g.length;
    int[] ks = kl[0];
    int[] ls = kl[1];
    int nkl = ks.length;

    // Initially empty arrays for index pairs (i,j).
    int nij = 0;
    int[] is = new int[nkl];
    int[] js = new int[nkl];

    // Collect index pairs (i,j) for all non-null values.
    for (int ikl=0; ikl<nkl; ++ikl) {
      int k = ks[ikl];
      int l = ls[ikl];
      int i = (k-l)/2;
      int j = (k+l)/2;
      if (0<=i && i<ni && 0<=j && j<nj && f[i]!=_vnull && g[j]!=_vnull) {
        is[nij] = i;
        js[nij] = j;
        ++nij;
      }
    }

    // Return trimmed arrays of index pairs (i,j).
    is = copy(nij,is);
    js = copy(nij,js);
    return new int[][]{is,js};
  }
  public int[][] convertWarping(int[][] kl, float[][] f, float[][] g) {
    int nc = f.length;
    int ni = f[0].length;
    int nj = g[0].length;
    int[] ks = kl[0];
    int[] ls = kl[1];
    int nkl = ks.length;

    // Initially empty arrays for index pairs (i,j).
    int nij = 0;
    int[] is = new int[nkl];
    int[] js = new int[nkl];

    // Collect index pairs (i,j) for all non-null values.
    for (int ikl=0; ikl<nkl; ++ikl) {
      boolean nls = true;
      int k = ks[ikl];
      int l = ls[ikl];
      int i = (k-l)/2;
      int j = (k+l)/2;
      for (int c=0; c<nc; ++c) {
        if (0<=i && i<ni && 0<=j && j<nj && f[c][i]!=_vnull && g[c][j]!=_vnull) 
          nls = false;
      }
      if (0<=i && i<ni && 0<=j && j<nj && !nls) {
        is[nij] = i;
        js[nij] = j;
        ++nij;
      }
    }

    // Return trimmed arrays of index pairs (i,j).
    is = copy(nij,is);
    js = copy(nij,js);
    return new int[][]{is,js};
  }
  public float[] convertWeights(float[] zl, float[] wkl, float[][] f, float[][] g) {
    int nkl = zl.length;
    int nc = f.length;
    int ni = f[0].length;
    int nj = g[0].length;
    int[] ks = new int[nkl];
    int[] ls = new int[nkl];
    ramp(0,1,ks);
    for (int l=0; l<nkl; ++l) {
      ls[l] = (int)(zl[l] + 0.5f);
    }

    // Initially empty arrays for index pairs (i,j).
    int nij = 0;
    float[] ws = new float[nkl];

    // Collect index pairs (i,j) for all non-null values.
    for (int ikl=0; ikl<nkl; ++ikl) {
      int k = ks[ikl];
      int l = ls[ikl];
      float w = wkl[ikl];
      int i = (k-l)/2;
      int j = (k+l)/2;
      if (0<=i && i<ni && 0<=j && j<nj) {
        ws[nij] = w;
        ++nij;
      }
    }

    // Return trimmed arrays of index pairs (i,j).
    ws = copy(nij,ws);
    return ws;
  }
  public int[][] convertWarping(float[] zl, float[][] f, float[][] g) {
    int nkl = zl.length;
    int nc = f.length;
    int ni = f[0].length;
    int nj = g[0].length;
    int[] ks = new int[nkl];
    int[] ls = new int[nkl];
    ramp(0,1,ks);
    for (int l=0; l<nkl; ++l) {
      ls[l] = (int)(zl[l] + 0.5f);
    }

    // Initially empty arrays for index pairs (i,j).
    int nij = 0;
    int[] is = new int[nkl];
    int[] js = new int[nkl];

    // Collect index pairs (i,j) for all non-null values.
    for (int ikl=0; ikl<nkl; ++ikl) {
      int k = ks[ikl];
      int l = ls[ikl];
      int i = (k-l)/2;
      int j = (k+l)/2;
      if (0<=i && i<ni && 0<=j && j<nj) {
        is[nij] = i;
        js[nij] = j;
        ++nij;
      }
    }

    // Return trimmed arrays of index pairs (i,j).
    is = copy(nij,is);
    js = copy(nij,js);
    return new int[][]{is,js};
  }

  /**
   * Apply warping to specified sequences f[i] and g[j].
   * The returned sequences f and g will both be indexed by k = i+j.
   * and will include null values for any missing values.
   * @param kl array[2][] containing indices (k,l). The array[0] contains
   *  the indices k, and the array[1] contains the indices l.
   * @param f array of values f[i] in 1st log sequence.
   * @param g array of values g[j] in 2nd log sequence.
   * @return array[2][] containing warped sequences f[k] and g[k].
   */
  public float[][] applyWarping(int[][] kl, float[] f, float[] g) {
    int[] ks = kl[0];
    int[] ls = kl[1];
    int nkl = ks.length;
    int ni = f.length;
    int nj = g.length;
    int nk = ni+nj-1;
    float[] fk = fillfloat(_vnull,nk);
    float[] gk = fillfloat(_vnull,nk);
    for (int ikl=0; ikl<nkl; ++ikl) {
      int k = ks[ikl];
      int l = ls[ikl];
      int i = (k-l)/2;
      int j = (k+l)/2;
      //fk[k] = (0<=i && i<ni && f[i]!=_vnull)?f[i]:_vnull;
      //gk[k] = (0<=j && j<nj && g[j]!=_vnull)?g[j]:_vnull;
      if (0<=i && i<ni && f[i]!=_vnull && 
          0<=j && j<nj && g[j]!=_vnull) {
        fk[k] = f[i];
        gk[k] = g[j];
      }
      if (ikl<nkl-1 && ks[ikl+1]==k+2) {
        fk[k+1] = fk[k];
        gk[k+1] = gk[k];
      }
    }
    return new float[][]{fk,gk};
  }

  /**
   * Interpolates alignment (or accumulated) errors for odd k+l.
   * Does not modify errors e[k,l] for which k+l is even.
   * <p>
   * Errors for odd k+l are never used. This interpolation is useful only for
   * displays of errors.
   * @param e array of errors e[k,l].
   */
  public void interpolateOddErrors(float[][] e) {
    int nk = e.length;
    int nl = e[0].length;
    int lmax = (nl-1)/2;
    int lmin = -lmax;
    for (int k=0; k<nk; ++k) {
      for (int l=lmin; l<=lmax; ++l) {
        if ((k+l)%2!=0) {
          int km = k-1; if (km<   0) km += 2;
          int kp = k+1; if (kp>= nk) kp -= 2;
          int lm = l-1; if (lm<lmin) lm += 2;
          int lp = l+1; if (lp>lmax) lp -= 2;
          float ekm = e[km][l-lmin];
          float ekp = e[kp][l-lmin];
          float elm = e[k][lm-lmin];
          float elp = e[k][lp-lmin];
          if (ekm==_enull || ekp==_enull || elm==_enull || elp==_enull) {
            e[k][l-lmin] = _enull;
          } else {
            e[k][l-lmin] = 0.25f*(ekm+ekp+elm+elp);
          }
        }
      }
    }
  }
  public float[] interpolateLs(int nz, int[][] kl) {
    int[] ks = kl[0];
    int[] ls = kl[1];
    int nkl = ks.length;
    float[] zl = new float[nz];

    int ik = 0;
    if (ks[0]==0) zl[ik++] = (float)ls[0];
    if (ks[0]==1) { zl[ik++] = (float)ls[0]; zl[ik++] = (float)ls[0];}

    for (int k=1; k<nkl; ++k) {
      if (ls[k]-ls[k-1]==0) {
        zl[ik++] = (float)ls[k];
        zl[ik++] = (float)ls[k];
      } else {
        zl[ik++] = (float)ls[k];
      }
    }

    return zl;
  }
  public float[][] computeWarping(int nq, float[] wi, float[] wj) {
    int ni = wi.length;
    int nj = wj.length;
    int nks = ni+nj-1;
    float[][] wps = zerofloat(nks,nq);
    for (int q=0; q<nq; ++q) {
      float[][] e = computeErrors(q,wi,wj);
      float[][] d = accumulateErrors(e);
      int[][] kl = findWarping(d);
      wps[q] = interpolateLs(nks,kl);
    }
    float[] zl = zerofloat(nks);
    int[] l = new int[nks];
    for (int q=0; q<nq; ++q) {
      for (int k=0; k<nks; ++k) {
        zl[k] += wps[q][k]/nq;
      }
    }
    /*
    float[] zk = rampfloat(0.0f,1.0f,nks);
    float[][] e = computeErrors(0,iqr,wi,wj);
    float[][] d = accumulateErrors(e);
    interpolateOddErrors(e);
    interpolateOddErrors(d);
    int nl = e[0].length;
    int lmax = (nl-1)/2; 
    int lmin = -lmax;
    Sampling sl = new Sampling(nl,1,lmin);
    Sampling sk = new Sampling(nks,1,0);
    SimplePlot sp = new SimplePlot();
    PixelsView pv = sp.addPixels(sk,sl,transpose(e));
    pv.setInterpolation(PixelsView.Interpolation.NEAREST);
    for (int q=0; q<nq; ++q) {
      PointsView ptv = sp.addPoints(zk,wps[q]);
      ptv.setLineColor(Color.RED);
      ptv.setLineWidth(2.0f);
    }
    PointsView ptv = sp.addPoints(zk,zl);
    ptv.setLineColor(Color.BLUE);
    ptv.setLineStyle(PointsView.Line.DASH);
    ptv.setLineWidth(2.0f);
    */
    /*
    sp = new SimplePlot();
    pv = sp.addPixels(sk,sl,transpose(d));
    pv.setColorModel(ColorMap.JET);
    pv.setInterpolation(PixelsView.Interpolation.NEAREST);
    ptv = sp.addPoints(zk,zl);
    ptv.setLineColor(Color.WHITE);
    ptv.setLineStyle(PointsView.Line.DASH);
    ptv.setLineWidth(2.0f);
    */



    float[] wkl = zerofloat(nks);
    for (int q=0; q<nq; ++q) {
      for (int k=0; k<nks; ++k) {
        wkl[k] += ((wps[q][k]-zl[k])*(wps[q][k]-zl[k]))/nq;
      }
    }
    wkl = sqrt(wkl);
    for (int k=0; k<nks; ++k) {
      wkl[k] = 1.0f/(1.0f+wkl[k]);
    }
    return new float[][]{zl,wkl};
  }
  public float[][] computeWarping(int nq, float[] iqr, float[][] wi, float[][] wj) {
    int ni = wi[0].length;
    int nj = wj[0].length;
    int nks = ni+nj-1;
    float[][] wps = zerofloat(nks,nq);
    for (int q=0; q<nq; ++q) {
      //float[][] e = computeErrors(q,wi,wj);
      float[][] e = computeErrors(q,iqr,wi,wj);
      float[][] d = accumulateErrors(e);
      int[][] kl = findWarping(d);
      wps[q] = interpolateLs(nks,kl);
    }
    float[] zl = zerofloat(nks);
    int[] l = new int[nks];
    for (int q=0; q<nq; ++q) {
      for (int k=0; k<nks; ++k) {
        zl[k] += wps[q][k]/nq;
      }
    }
    /*
    float[] zk = rampfloat(0.0f,1.0f,nks);
    float[][] e = computeErrors(0,iqr,wi,wj);
    float[][] d = accumulateErrors(e);
    interpolateOddErrors(e);
    interpolateOddErrors(d);
    int nl = e[0].length;
    int lmax = (nl-1)/2; 
    int lmin = -lmax;
    Sampling sl = new Sampling(nl,1,lmin);
    Sampling sk = new Sampling(nks,1,0);
    SimplePlot sp = new SimplePlot();
    PixelsView pv = sp.addPixels(sk,sl,transpose(e));
    pv.setInterpolation(PixelsView.Interpolation.NEAREST);
    for (int q=0; q<nq; ++q) {
      PointsView ptv = sp.addPoints(zk,wps[q]);
      ptv.setLineColor(Color.RED);
      ptv.setLineWidth(2.0f);
    }
    PointsView ptv = sp.addPoints(zk,zl);
    ptv.setLineColor(Color.BLUE);
    ptv.setLineStyle(PointsView.Line.DASH);
    ptv.setLineWidth(2.0f);
    */
    /*
    sp = new SimplePlot();
    pv = sp.addPixels(sk,sl,transpose(d));
    pv.setColorModel(ColorMap.JET);
    pv.setInterpolation(PixelsView.Interpolation.NEAREST);
    ptv = sp.addPoints(zk,zl);
    ptv.setLineColor(Color.WHITE);
    ptv.setLineStyle(PointsView.Line.DASH);
    ptv.setLineWidth(2.0f);
    */



    float[] wkl = zerofloat(nks);
    for (int q=0; q<nq; ++q) {
      for (int k=0; k<nks; ++k) {
        wkl[k] += ((wps[q][k]-zl[k])*(wps[q][k]-zl[k]))/nq;
      }
    }
    wkl = sqrt(wkl);
    for (int k=0; k<nks; ++k) {
      wkl[k] = 1.0f/(1.0f+wkl[k]);
    }
    return new float[][]{zl,wkl};
  }

  /**
   * Returns shifts for each specified log. Logs are assumed to have been
   * resampled so that every log has the same depth sampling. The returned
   * shifts are in units of samples, but may have non-zero fractional parts.
   * @param fs array[nl][nz] of log values, nz values for each of nl logs.
   * @return array[nl][nz] of shifts.
   */
  public float[][] findShifts(float[] wm, float[][][] wl) {
    float[][][] wells = copy(wl);
    int nl = wells.length;
    int nm = wells[0].length;
    int nk = wells[0][0].length;
 
    boolean[][] nls = new boolean[nl][nk];
    float[][] nnls = new float[nl][nk];
    for (int l=0; l<nl; ++l)
      for (int k=0; k<nk; ++k)
        nls[l][k] = true;
    Pairs[] pt = new Pairs[nl*nm*(nl*nm-1)/2];
    int np = 0;
    int nlp = 0;
    for (int il=0; il<nl; ++il) {
      for (int jl=il+1; jl<nl; ++jl) {
        for (int im=0; im<nm; ++im) {
          float[] fi = wl[il][im];
          float[] gj = wl[jl][im];
          if (wm[im]>0 && wellNotNull(fi) && wellNotNull(gj)) {
            float[][] e = computeErrors(fi,gj);
            float[][] d = accumulateErrors(e);
            int[][] kl = findWarping(d);
            int[][] ij = convertWarping(kl,fi,gj);
            int[] is = ij[0];
            int[] js = ij[1];
            int n = is.length;
            float tae = 0;
            for (int kz=0; kz<n; ++kz) {
              nls[il][is[kz]] = false;
              nls[jl][js[kz]] = false;
              nnls[il][is[kz]] += 1.0f;
              nnls[jl][js[kz]] += 1.0f;
              tae += error(fi[is[kz]],gj[js[kz]]);
            }
            //if (tae>0) {
              float ws = n/tae; 
              pt[nlp++] = new Pairs(il,jl,is,js,ws,im);
              np += n;
            //}
          }
        }
      }
    }
    Pairs[] ps = new Pairs[nlp];
    float[] wsum = new float[nm];
    for (int ip=0; ip<nlp; ++ip) {
      ps[ip] = pt[ip];
      int im = ps[ip].m;
      float ws = ps[ip].ws;
      wsum[im] += ws;
    }
    for (int ip=0; ip<nlp; ++ip) {
      int im = ps[ip].m;
      float ws = ps[ip].ws;
      ws /= wsum[im];
      ws *= wm[im];
      //ps[ip].ws = 1.0f;
      ps[ip].ws = ws;
    }
 
 
   
   
 
/*
   //nk = 900;
   nk = 1500;
   //nk = 300;
   nl = 2;
   Pairs[] ps1 = new Pairs[1];
   int[] is = new int[nk];
   int[] js = new int[nk];
   ramp(0,1,is);
   for (int k=0; k<nk; ++k) {
     //js[k] = (int)(is[k] + (nk-is[k])*0.1f +0.5f);
     js[k] = (int)(is[k] + is[k]*0.1f +0.5f);
   } 
   int[] ks = new int[nk];
   int prev = 1;
   int c = 0;
   for (int k=1, tp=1; k<nk; ++k, ++tp) {
     ks[k] = js[prev];
     if (js[tp]-js[tp-1]>1) {
       if (c==0) {
         ++c;
         ks[k] = (js[tp]+js[tp-1])/2;
         if (k<nk-1) {
           ks[++k] = (js[tp]+js[tp-1])/2;
         }
       } else {
         if (k<nk-1) {
           ks[++k] = (js[tp]+js[tp-1])/2;
         }
         if (k<nk-1) {
           ks[++k] = (js[tp]+js[tp-1])/2;
         }
       }
       prev = tp-1;
     }
     ++prev;
   } 
   js = ks;
   int lj = js[nk-1];
   float[] ws = fillfloat(1.0f,nk);
   ps1[0] = new Pairs(0,1,is,js,ws);
   ps = ps1;
   nls = new boolean[nl][nk];
   for (int k=0; k<nk; ++k) {
     nls[0][k] = false;
     nls[1][k] = false;
     if (k>lj) {
       nls[1][k] = true;
     }
   }
 
 
*/
 
 
 


   /*

   // Find the median of all alignment errors.
   float[] wp = new float[np];
   np = 0;
   for (Pairs p:ps) {
     float[] ws = p.ws;
     int nw = ws.length;
     for (int iw=0; iw<nw; ++iw) {
       wp[np++] = ws[iw];
     }
   }
   MedianFinder mf = new MedianFinder(np);
   float wmed = mf.findMedian(wp);
   trace("np="+np+" wmed="+wmed);
   wp = null;

   // Use the median to compute weights from alignment errors. Each pair
   // (i,j) corresponds to two linear equations with two shifts. The weights
   // are used below in a least-squares solution of many such equations.
   // Pairs (i,j) with smaller alignment errors get more weight.
   // NOTE: in current experiments, constant weights seem to work best!
   for (Pairs p:ps) {
     float[] ws = p.ws;
     int nw = ws.length;
     float wscl = -0.02f/wmed;
     for (int iw=0; iw<nw; ++iw) {
       //ws[iw] = exp(wscl*ws[iw]);
       //ws[iw] = max(1.0f-wscl*ws[iw],0.0f);
       ws[iw] = 1.0f;
     }
   }
   */

   // Use CG to solve least-squares equations for shifts s.
   float sigma = 10.0f;
   //float small = 0.001f;
   float small = 1.0e-6f;
   int niter = 5;
   //int niter = 1000;
   int csmall = 1;
   //int csmall = nl*(nl-1)/4;
   double[][] r = new double[nl][nk]; // for right-hand side
   float[][]  s = new float[nl][nk]; // for the shifts
   double[][] q = new double[nl][nk]; // for the shifts
   float[][] tz = new float[nl][nk]; 
   for (int il=0; il<nl; ++il) 
     tz[il] = rampfloat(0.0f,1.0f,nk); // initialize t = z
   int[][] tc = zeroint(nk,nl); // counts of t(z)'s
   makeRhs(tz,tc,ps,r);

/*
   float[][] rf = new float[nl][nk]; // for right-hand side
   for (int il=0; il<nl; ++il) 
     for (int ik=0; ik<nk; ++ik) 
       rf[il][ik] = (float)(r[il][ik]);
   PlotPanel pp = new PlotPanel();
   float[] d = rampfloat(0.0f,1.0f,nk);
   PointsView pv = pp.addPoints(d,rf[0]);
   for (int i=1; i<nl; ++i) {
     pv = pp.addPoints(d,rf[i]);
   }
   pp.setHLabel("rhs");
   PlotFrame pf = new PlotFrame(pp);
   pf.setVisible(true);
   pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
*/

   subtractMeanOverLogs(r);

/*
   for (int il=0; il<nl; ++il) 
     for (int ik=0; ik<nk; ++ik) 
       rf[il][ik] = (float)(r[il][ik]);
   pp = new PlotPanel();
   pv = pp.addPoints(d,rf[0]);
   for (int i=1; i<nl; ++i) {
     pv = pp.addPoints(d,rf[i]);
   }
   pp.setHLabel("smol");
   pf = new PlotFrame(pp);
   pf.setVisible(true);
   pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);

*/
   accumulateReverse(r);

/*
   for (int il=0; il<nl; ++il) 
     for (int ik=0; ik<nk; ++ik) 
       rf[il][ik] = (float)(r[il][ik]);
   pp = new PlotPanel();
   pv = pp.addPoints(d,rf[0]);
   for (int i=1; i<nl; ++i) {
     pv = pp.addPoints(d,rf[i]);
   }
   pp.setHLabel("accum");
   pf = new PlotFrame(pp);
   pf.setVisible(true);
   pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
*/

   smoothGapsTranspose(csmall,tc,r);
/*
   for (int il=0; il<nl; ++il) 
     for (int ik=0; ik<nk; ++ik) 
       rf[il][ik] = (float)(r[il][ik]);
   pp = new PlotPanel();
   pv = pp.addPoints(d,rf[0]);
   for (int i=1; i<nl; ++i) {
     pv = pp.addPoints(d,rf[i]);
   }
   pp.setHLabel("smooth");
   pf = new PlotFrame(pp);
   pf.setVisible(true);
   pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
*/
   A a = new A(csmall,tz,tc,ps);
   Ml m = new Ml(sigma,nk,nl,nls,tc);
   
   
   CgSolver cs = new CgSolver(small,niter);
   VecArrayDouble2 vr = new VecArrayDouble2(r);
   VecArrayDouble2 vs = new VecArrayDouble2(q);
   float diff = FLT_MAX;
   float diffold = -FLT_MAX;
   float[][] sold = new float[nl][nk]; 
   float thresh = 0.5f;
   //float thresh = 1.0f;
   //int maxit = 1;
   int maxit = 40;
   int it = 0;
   //float thresh = 0.3f;
   
   //while (diff>thresh && it<maxit) {
   while (abs(diffold-diff)>thresh && it<maxit) {
     copy(s,sold);
     if (it>0) {
       makeRhs(tz,tc,ps,r);
       subtractMeanOverLogs(r);
       accumulateReverse(r);
       smoothGapsTranspose(csmall,tc,r);
       niter = 2*it+5;
       niter = niter>100 ? 100 : niter;
       cs = new CgSolver(small,niter);
       //m = new Ml(sigma,nk,nl,nls,tc);
     }
     cs.solve(a,vr,vs); // gives r(t)
     //cs.solve(a,m,vr,vs); // gives r(t)
     //m.test(s);

     double [][] sd = copy(q);
     smoothGaps(csmall,tc,sd);
     accumulateForward(sd);
     subtractMeanOverLogs(sd);


     for (int il=0; il<nl; ++il) 
       for (int ik=0; ik<nk; ++ik) 
         s[il][ik] = (float)(sd[il][ik]);

     clipShifts(s);
     //interpolateShifts(csmall,tc,s);
     float[][] rs = copy(s);
     invertShiftsR(rs);
     float bf = rms(ps,rs);
     //errorHist("before "+it,ps,s);
     float[] ss = zerofloat(nk);
     for (int il=0; il<nl; ++il) {
       for (int ik=0; ik<nk; ++ik) {
         ss[ik] += s[il][ik];
       }
     }
     for (int ik=0; ik<nk; ++ik) {
       //if (0.01<ss[ik] || ss[ik]<-0.01) System.out.println("ik="+ik+" sum="+ss[ik]);
     }

     for (int il=0; il<nl; ++il) { 
       for (int ik=0; ik<nk; ++ik) 
         tz[il][ik] = ik-s[il][ik]; // gives z(t)
     }

     for (int il=0; il<nl; ++il) 
       cleanShiftsRS(s[il]);

     /*
     PlotPanel pp = new PlotPanel();
     float[] d = rampfloat(0.0f,1.0f,nk);
     PointsView pv = pp.addPoints(d,tz[0]);
     for (int i=1; i<nl; ++i) {
       pv = pp.addPoints(d,tz[i]);
     }
     pp.setVLabel("z(t)");
     PlotFrame pf = new PlotFrame(pp);
     pf.setVisible(true);
     pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
     */

     invertZorT(tz); // gives t(z)
     //m.subtractMeanOverLogs(s);

     /*
     pp = new PlotPanel();
     pv = pp.addPoints(d,tz[0]);
     for (int i=1; i<nl; ++i) {
       pv = pp.addPoints(d,tz[i]);
     }
     pp.setVLabel("t(z)");
     pf = new PlotFrame(pp);
     pf.setVisible(true);
     pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
     */

     rs = copy(s);
     invertShiftsR(rs);
     float af = rms(ps,rs);
     //errorHist("after "+it,ps,rs);
     System.out.println("RMS error before="+bf+" after="+af+" diff="+(af-bf));

/*
     interpolateShifts(csmall,tc,s);

     for (int il=0; il<nl; ++il) {
       q[il][0] = (double)(s[il][0]);
       for (int ik=1; ik<nk; ++ik) {
         q[il][ik] = (double)(s[il][ik]-s[il][ik-1]);
       }
     }
*/
/*
     PlotPanel pp = new PlotPanel();
     float[] d = rampfloat(0.0f,1.0f,nk);
     PointsView pv = pp.addPoints(d,s[0]);
     for (int il=1; il<nl; ++il) 
       pv = pp.addPoints(d,s[il]);
     PlotFrame pf = new PlotFrame(pp);
     pf.setVisible(true);
     pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
*/

     float avd = 0;
     int cct = 0;
     for (int il=0; il<nl; ++il) {
       for (int ik=0; ik<nk; ++ik) {
         if (nnls[il][ik]>0) {
           avd += abs(s[il][ik] - sold[il][ik]);
           ++cct;
         }
       }
     }
     diffold = diff;
     diff = avd/cct;
     System.out.println("diff="+diff);
     ++it;
   }
   //interpolateShifts(csmall,tc,s);

   return s;
 }

  /**
   * Applies the specified shifts to the specified logs.
   * @param f array[nl][nz] of log values.
   * @param s array[nl][nz] of shifts.
   * @return array[nl][nz] of shifted log values.
   */
  public float[][] applyShifts(float[][] f, float[][] s) {
    int nk = f[0].length;
    int nl = f.length;
    float[][] g = fillfloat(_vnull,nk,nl);

    // For all logs, ...
    for (int il=0; il<nl; ++il) {

      // For all depths, ...
      for (int ik=0; ik<nk; ++ik) {

        // Depth (in samples) at which to interpolate log.
        //float zk = tts[ik]-s[il][ik];
        float zk = ik-s[il][ik];

        // Nearest-neighbor interpolation.
        int jk = (int)(zk+0.5f);
        if (0<=jk && jk<nk && f[il][jk]!=_vnull) {
          g[il][ik] = f[il][jk];
        }
      }
    }
    return g;
  }
  /**
   * Applies the specified shifts to the specified logs.
   * @param f array[nl][nz] of log values.
   * @param s array[nl][nz] of shifts.
   * @return array[nl][nz] of shifted log values.
   */
  public float[] applyRGTShifts(float[] f, float[] s) {
    int nk = f.length;
    float[] g = fillfloat(_vnull,nk);

    // For all RGTs, ...
    for (int ik=0; ik<nk; ++ik) {

      // RGT (in samples) at which to interpolate log.
      float zk = ik-s[ik];

      // Nearest-neighbor interpolation.
      int jk = (int)(zk+0.5f);
      if (0<=jk && jk<nk && f[jk]!=_vnull) {
        g[ik] = f[jk];
      }
      /* 
      // Linear interpolation. Smears outliers!
      int jk = (int)zk;
      if (0<=jk && jk<nk && f[il][jk]!=_vnull) {
        if (jk<nk-1 && f[il][jk+1]!=_vnull) {
          float dk = zk-jk;
          g[il][ik] = (1.0f-dk)*f[il][jk]+dk*f[il][jk+1];
        } else {
          g[il][ik] = f[il][jk];
        }
      }
      */
    }
    return g;
  }

  /**
   * Sorts well indices to approximately minimize distances between wells.
   * Specifically, this method approximately minimizes the total distance
   * traveled from well to well in a sequential iteration over all well
   * locations, in which each well is visited only once. Because exactly 
   * minimizing this total distance would require a costly solution to the
   * traveling-salesman problem, this method instead uses a simple greedy
   * solution.
   * <p>
   * This method is useful primarily in 2D displays of logs. Logs displayed as
   * adjacent pixels or curves are likely to appear more correlated than they
   * would be for an arbitrary ordering of wells.
   * @param x array of x coordinates of well locations.
   * @param y array of y coordinates of well locations.
   * @return the sorted array of well indices.
   */
  public static int[] sortWells(double[] x, double[] y) {
    int nw = x.length;
    Random r = new Random(314159);
    double dsmin = DBL_MAX; // the minimized distance
    int[] ksmin = null;
    for (int mw=0; mw<nw; ++mw) { // for all possible first-well indices
      boolean[] bs = new boolean[nw]; // flags for visited wells
      int[] ks = new int[nw]; // indices of visited wells
      int kw = mw; // index of the first well
      double xk = x[kw]; // x-coordinate
      double yk = y[kw]; // y-coordinate
      double ds = 0.0f; // distance sum
      int iw = 0;
      ks[iw] = kw; // first index in the list
      bs[kw] = true; // have now visited well with index kw
      for (iw=1; iw<nw; ++iw) { // for all other wells, ...
        int jmin = -1;
        double dmin = DBL_MAX;
        for (int jw=0; jw<nw; ++jw) { // find nearest not yet visited
          if (!bs[jw]) { // if not yet visited, ...
            double xj = x[jw];
            double yj = y[jw];
            double dx = xk-xj;
            double dy = yk-yj;
            double dj = dx*dx+dy*dy; // distance-squared
            if (dj<dmin) { // if nearest so far, ...
              dmin = dj;
              jmin = jw;
            }
          }
        }
        kw = jmin; // visit the nearest well
        xk = x[kw];
        yk = y[kw];
        ds += dmin;
        ks[iw] = kw;
        bs[kw] = true; // mark this well as visited
      }
      //trace("sortWells: ds="+ds);
      if (ds<dsmin) { // if this path has less distance, remember it
        dsmin = ds;
        ksmin = ks;
      }
    }
    //trace("sortWells: dsmin="+dsmin);
    return ksmin;
  }

  /**
   * Gets a uniform sampling of depth for specified depths and logs.
   * Considers only depths for which log values are non-null. The returned
   * sampling will include the shallowest and the deepest depths logged.
   * @param z array of arrays of depths; one array for each log.
   * @param f array of arrays of log values; one array for each log.
   * @return the uniform sampling.
   */
  public Sampling getDepthSampling(float[][] z, float[][] f) {
    int nl = z.length;

    // Total number of depths specified.
    int nlz = 0;
    for (int il=0; il<nl; ++il)
      nlz += z[il].length;

    // Array for depth increments, and counter for number of increments.
    float[] dz = new float[nlz];
    int ndz = 0;

    // Find min and max depths, while storing depth increments.
    // Consider only log samples with non-null values.
    float zmin =  FLT_MAX;
    float zmax = -FLT_MAX;
    for (int il=0; il<nl; ++il) {
      int nz = z[il].length;
      float zi = z[il][0];
      float fi = f[il][0];
      for (int iz=0; iz<nz; ++iz) {
        float zim1 = zi;
        float fim1 = fi;
        zi = z[il][iz];
        fi = f[il][iz];
        if (fi!=_vnull && zi<zmin)
          zmin = zi;
        if (fi!=_vnull && zi>zmax)
          zmax = zi;
        if (iz>0 && fi!=_vnull && fim1!=_vnull)
          dz[ndz++] = zi-zim1;
      }
    }

    // Depth interval is median of all depth increments.
    dz = copy(ndz,dz);
    MedianFinder mf = new MedianFinder(ndz);
    float zdel = mf.findMedian(dz);

    // Uniform sampling.
    int nz = 1+(int)ceil((zmax-zmin)/zdel);
    return new Sampling(nz,zdel,zmin);
  }

  public Sampling getDepthSampling(float[][][] z, float[][][] f) {
    int nw = z.length;
    int nl = z[0].length;

    // Total number of depths specified.
    int nlz = 0;

    for (int iw=0; iw<nw; ++iw)
      for (int il=0; il<nl; ++il)
      nlz += z[iw][il].length;

    // Array for depth increments, and counter for number of increments.
    float[] dz = new float[nlz];
    int ndz = 0;

    // Find min and max depths, while storing depth increments.
    // Consider only log samples with non-null values.
    float zmin =  FLT_MAX;
    float zmax = -FLT_MAX;
    for (int iw=0; iw<nw; ++iw) {
      for (int il=0; il<nl; ++il) {
        int nz = z[iw][il].length;
        if (nz!=0) {
          float zi = z[iw][il][0];
          float fi = f[iw][il][0];
          for (int iz=0; iz<nz; ++iz) {
            float zim1 = zi;
            float fim1 = fi;
            zi = z[iw][il][iz];
            fi = f[iw][il][iz];
            if (fi!=_vnull && zi<zmin)
              zmin = zi;
            if (fi!=_vnull && zi>zmax)
              zmax = zi;
            if (iz>0 && fi!=_vnull && fim1!=_vnull)
              dz[ndz++] = zi-zim1;
          }
        }
      }
    }

    // Depth interval is median of all depth increments.
    dz = copy(ndz,dz);
    MedianFinder mf = new MedianFinder(ndz);
    float zdel = mf.findMedian(dz);

    // Uniform sampling.
    int nz = 1+(int)ceil((zmax-zmin)/zdel);
    return new Sampling(nz,zdel,zmin);
  }

  /**
   * Resamples a log with specified depths and values.
   * The desired depth sampling for the output array of values can be
   * different from (e.g., coarser than) that implied by the input array of
   * depths.
   * @param s the desired uniform sampling of depths.
   * @param z array of depths for which values are provided.
   * @param f array of values; some values may be null.
   * @return array of values for uniformly sampled depths.
   */
  public float[] resampleLog(Sampling s, float[] z, float[] f) {
    int nz = s.getCount();
    float zmin = (float)s.getFirst();
    float zmax = (float)s.getLast();
    int n = z.length;
    float[] g = new float[nz];
    float[] c = new float[nz];
    if (n!=0) {
      for (int i=0; i<n; ++i) {
        float zi = z[i];
        float fi = f[i];
        if (zmin<=zi && zi<=zmax && fi!=_vnull) {
          int iz = s.indexOfNearest(zi);
          g[iz] += fi;
          c[iz] += 1.0f;
        }
      }
      for (int iz=0; iz<nz; ++iz) {
        if (c[iz]>0.0f) {
          g[iz] /= c[iz];
        } else {
          g[iz] = _vnull;
        }
      }
    } else {
      g = fillfloat(_vnull,nz);
    }
    return g;
  }

  /**
   * Resamples multiple logs with specified depths and values.
   * This method simply calls the method 
   * {@link #resampleLog(Sampling,float[],float[])}
   * for all specified arrays of depths and values.
   * @param s the desired uniform sampling of depths.
   * @param z array of depths for which values are provided.
   * @param f array of values; some values may be null.
   * @return array of values for uniformly sampled depths.
   */
  public float[][] resampleLogs(Sampling s, float[][] z, float[][] f) {
    int n = z.length;
    float[][] g = new float[n][];
    for (int i=0; i<n; ++i)
      g[i] = resampleLog(s,z[i],f[i]);
    return g;
  }
  public float[][][] resampleLogs(Sampling s, float[][][] z, float[][][] f) {
    int n = z.length;
    float[][][] g = new float[n][][];
    for (int i=0; i<n; ++i)
      g[i] = resampleLogs(s,z[i],f[i]);
    return g;
  }
  public void replaceNullsS(float[] f, float freplace, float[] s) {
    int n = f.length;
    for (int i=0; i<n; ++i) {
      if (f[i]==_vnull) {
        s[i] = freplace;
      } 
    }
  }
  public void replaceNullsS(float[][] f, float freplace, float[][] s) {
    int n = f.length;
    float[][] g = new float[n][];
    for (int i=0; i<n; ++i)
      replaceNullsS(f[i],freplace,s[i]);
  }

  /**
   * Replaces any null values found in a log with a specified value.
   * Typically used only for displays.
   * @param f array of log values.
   * @param freplace value used to replace any null values.
   * @return array of logs values with null values replaced.
   */
  public float[] replaceNulls(float[] f, float freplace) {
    int n = f.length;
    float[] g = new float[n];
    for (int i=0; i<n; ++i) {
      if (f[i]!=_vnull) {
        g[i] = f[i];
      } else {
        g[i] = freplace;
      }
    }
    return g;
  }
  /**
   * Replaces any null values found in multiple logs with a specified value.
   * Typically used only for displays.
   * @param f array of log values.
   * @param freplace value used to replace any null values.
   * @return array of logs values with null values replaced.
   */
  public float[][] replaceNulls(float[][] f, float freplace) {
    int n = f.length;
    float[][] g = new float[n][];
    for (int i=0; i<n; ++i)
      g[i] = replaceNulls(f[i],freplace);
    return g;
  }

  public float[] toFloat(int[] i) {
    int n = i.length;
    float[] f = new float[n];
    for (int j=0; j<n; ++j)
      f[j] = (float)i[j];
    return f;
  }

  ///////////////////////////////////////////////////////////////////////////
  // private
 
  private int _lmax = Integer.MAX_VALUE;
  private float _epow = 1.0f;
  private float _enull = -FLT_MIN;
  private float _vnull = -999.2500f;
  private static final float SUM_SCL = 0.001f;

  /**
   * Arrays of pairs of depth sample indices (is,js) with weights ws. These
   * arrays were computed by warping a pair of logs with indices (ilog,jlog).
   */
  private static class Pairs {
    Pairs(int ilog, int jlog, int[] is, int[] js, float ws, int m) {
    //Pairs(int ilog, int jlog, int[] is, int[] js, float[] ws) {
      this.ilog = ilog;
      this.jlog = jlog;
      this.is = is;
      this.js = js;
      this.ws = ws;
    }
    int ilog,jlog,m;
    int[] is,js;
    float ws;
  }

  /**
   * Conjugate-gradient operator A and preconditioner M.
   * The preconditioner smooths along depth, while subtracting
   * the mean and linear trend.
   */
  private static class A implements CgSolver.A {
    A(int csmall, float[][] tz, int[][] tc, Pairs[] ps) {
      _ps = ps;
      _tz = tz;
      _tc = tc;
      _csmall = csmall;
    }
    public void apply(Vec vx, Vec vy) {
      double[][] x = ((VecArrayDouble2)vx).getArray();
      double[][] y = ((VecArrayDouble2)vy).getArray();
      copy(x,y);
      smoothGaps(_csmall,_tc,y);
      /*
   int nl = x.length;
   int nk = x[0].length;
   float[][] rf = new float[nl][nk]; // for right-hand side
   for (int il=0; il<nl; ++il) 
     for (int ik=0; ik<nk; ++ik) 
       rf[il][ik] = (float)(y[il][ik]);
   PlotPanel pp = new PlotPanel();
   float[] d = rampfloat(0.0f,1.0f,nk);
   PointsView pv = pp.addPoints(d,rf[0]);
   for (int i=1; i<nl; ++i) {
     pv = pp.addPoints(d,rf[i]);
   }
   pp.setHLabel("smooth1");
   PlotFrame pf = new PlotFrame(pp);
   pf.setVisible(true);
   pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
      */
      accumulateForward(y);
      /*
   for (int il=0; il<nl; ++il) 
     for (int ik=0; ik<nk; ++ik) 
       rf[il][ik] = (float)(y[il][ik]);
   pp = new PlotPanel();
   pv = pp.addPoints(d,rf[0]);
   for (int i=1; i<nl; ++i) {
     pv = pp.addPoints(d,rf[i]);
   }
   pp.setHLabel("accumF");
   pf = new PlotFrame(pp);
   pf.setVisible(true);
   pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
      */
      subtractMeanOverLogs(y);
      /*
   for (int il=0; il<nl; ++il) 
     for (int ik=0; ik<nk; ++ik) 
       rf[il][ik] = (float)(y[il][ik]);
   pp = new PlotPanel();
   pv = pp.addPoints(d,rf[0]);
   for (int i=1; i<nl; ++i) {
     pv = pp.addPoints(d,rf[i]);
   }
   pp.setHLabel("smol1");
   pf = new PlotFrame(pp);
   pf.setVisible(true);
   pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
      */
      applyLhs(_tz,_ps,copy(y),y);
      /*
   for (int il=0; il<nl; ++il) 
     for (int ik=0; ik<nk; ++ik) 
       rf[il][ik] = (float)(y[il][ik]);
   pp = new PlotPanel();
   pv = pp.addPoints(d,rf[0]);
   for (int i=1; i<nl; ++i) {
     pv = pp.addPoints(d,rf[i]);
   }
   pp.setHLabel("applyLhs");
   pf = new PlotFrame(pp);
   pf.setVisible(true);
   pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
      */
      subtractMeanOverLogs(y);
      /*
   for (int il=0; il<nl; ++il) 
     for (int ik=0; ik<nk; ++ik) 
       rf[il][ik] = (float)(y[il][ik]);
   pp = new PlotPanel();
   pv = pp.addPoints(d,rf[0]);
   for (int i=1; i<nl; ++i) {
     pv = pp.addPoints(d,rf[i]);
   }
   pp.setHLabel("smol2");
   pf = new PlotFrame(pp);
   pf.setVisible(true);
   pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
      */
      accumulateReverse(y);
      /*
   for (int il=0; il<nl; ++il) 
     for (int ik=0; ik<nk; ++ik) 
       rf[il][ik] = (float)(y[il][ik]);
   pp = new PlotPanel();
   pv = pp.addPoints(d,rf[0]);
   for (int i=1; i<nl; ++i) {
     pv = pp.addPoints(d,rf[i]);
   }
   pp.setHLabel("accumR");
   pf = new PlotFrame(pp);
   pf.setVisible(true);
   pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
      */
      smoothGapsTranspose(_csmall,_tc,y);
      /*
   for (int il=0; il<nl; ++il) 
     for (int ik=0; ik<nk; ++ik) 
       rf[il][ik] = (float)(y[il][ik]);
   pp = new PlotPanel();
   pv = pp.addPoints(d,rf[0]);
   for (int i=1; i<nl; ++i) {
     pv = pp.addPoints(d,rf[i]);
   }
   pp.setHLabel("smooth2");
   pf = new PlotFrame(pp);
   pf.setVisible(true);
   pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
      */
      testNND(y[0].length,y.length,_csmall);
    }
    private void testNND(int nk, int nl, int csmall) {
      double[][] x  = sub(randdouble(nk,nl),0.5d);
      double[][] xt = copy(x);
      smoothGaps(csmall,_tc,x);
      accumulateForward(x);
      subtractMeanOverLogs(x);
      applyLhs(_tz,_ps,copy(x),x);
      subtractMeanOverLogs(x);
      accumulateReverse(x);
      smoothGapsTranspose(csmall,_tc,x);

      VecArrayDouble2 vx = new VecArrayDouble2(x);
      VecArrayDouble2 vxt = new VecArrayDouble2(xt);

      double[][] y  = sub(randdouble(nk,nl),0.5d);
      double[][] yt = copy(y);
      smoothGaps(csmall,_tc,y);
      accumulateForward(y);
      subtractMeanOverLogs(y);
      applyLhs(_tz,_ps,copy(y),y);
      subtractMeanOverLogs(y);
      accumulateReverse(y);
      smoothGapsTranspose(csmall,_tc,y);

      VecArrayDouble2 vy  = new VecArrayDouble2(y);
      VecArrayDouble2 vyt = new VecArrayDouble2(yt);

      double ytAx = vyt.dot(vx);
      double xtAy = vxt.dot(vy);
      double xtAx = vxt.dot(vx);
      double ytAy = vyt.dot(vy);
      //System.out.println("ytAx="+ytAx+" xtAy="+xtAy);
      //assert abs(ytAx-xtAy)<1.0e-8 : "A is asymmetric";
      assert (xtAx>=0 || ytAy>=0) : "A is negative";
    }
    private Pairs[] _ps;
    private float[][] _tz;
    private int[][] _tc;
    private int _csmall;
  }
  private static class Ml implements CgSolver.A {
    Ml(double sigma, int nk, int nl, boolean[][] nls,int[][] tc) {
      _ref = new RecursiveExponentialFilter(sigma);
      _ref.setEdges(RecursiveExponentialFilter.Edges.OUTPUT_ZERO_SLOPE);
      _s = new float[nk];
      _nls = nls;
      _tc = tc;
    }
    public void apply(Vec vx, Vec vy) {
      float[][] x = ((VecArrayFloat2)vx).getArray();
      float[][] y = ((VecArrayFloat2)vy).getArray();
      copy(x,y);
      subtractMeanOverLogs(y);
      _ref.apply1(y,y);
      subtractMeanOverLogs(y);
    }
    /*
    public void subtractMeanOverLogs(float[][] x) {
      int nk = x[0].length;
      int nl = x.length;
      float[] c = new float[nk];
      zero(_s);
      for (int il=0; il<nl; ++il) {
        for (int ik=0; ik<nk; ++ik) {
          if (_tc[il][ik]>0) {
            int zk = (int)(ik-x[il][ik]);
            if (0<zk && zk<nk && !_nls[il][zk]) {
              _s[ik] += x[il][ik];
              c[ik]  += 1f;
            }
          }
        }
      }
      for (int il=0; il<nl; ++il) {
        for (int ik=0; ik<nk; ++ik) {
          if (_tc[il][ik]>0) {
            int zk = (int)(ik-x[il][ik]);
            if (0<zk && zk<nk && !_nls[il][zk]) {
              x[il][ik] -= _s[ik]/c[ik];
            }
          }
        }
      }
    }
    */
    public void subtractMeanOverLogs(float[][] x) {
      int nk = x[0].length;
      int nl = x.length;
      zero(_s);
      for (int il=0; il<nl; ++il) {
        for (int ik=0; ik<nk; ++ik) {
          _s[ik] += x[il][ik];
        }
      }
      float c = 1.0f/nl;
      for (int il=0; il<nl; ++il) {
        for (int ik=0; ik<nk; ++ik) {
          x[il][ik] -= _s[ik]*c;
        }
      }
    }
    public void test(float[][] x) {
      int nk = x[0].length;
      int nl = x.length;
      zero(_s);
      for (int il=0; il<nl; ++il) {
        for (int ik=0; ik<nk; ++ik) {
          _s[ik] += x[il][ik];
        }
      }
      trace("M.test: sum="); dump(_s);
    }
    private RecursiveExponentialFilter _ref;
    float[] _s; // used to efficiently compute sum over logs
    boolean[][] _nls;
    int[][] _tc;
  }
  private static class M implements CgSolver.A {
    M(double sigma, int nk, int nl) {
      _ref = new RecursiveExponentialFilter(sigma);
      _ref.setEdges(RecursiveExponentialFilter.Edges.OUTPUT_ZERO_SLOPE);
      _e0 = new float[nk];
      _e1 = new float[nk];
      double s0 = 0.0;
      double s1 = 0.0;
      for (int ik=0; ik<nk; ++ik) {
        _e0[ik] = 1.0f;
        _e1[ik] = 2*ik-(nk-1);
        s0 += _e0[ik]*_e0[ik];
        s1 += _e1[ik]*_e1[ik];
      }
      s0 *= nl;
      s1 *= nl;
      s0 = 1.0f/(float)sqrt(s0);
      s1 = 1.0f/(float)sqrt(s1);
      for (int ik=0; ik<nk; ++ik) {
        _e0[ik] *= s0;
        _e1[ik] *= s1;
      }
    }
    public void apply(Vec vx, Vec vy) {
      float[][] x = ((VecArrayFloat2)vx).getArray();
      float[][] y = ((VecArrayFloat2)vy).getArray();
      copy(x,y);
      subtract01(y);
      _ref.apply1(y,y);
      subtract01(y);
    }
    public void test(float[][] x) {
      int nk = x[0].length;
      int nl = x.length;
      double d0 = 0.0;
      double d1 = 0.0;
      for (int il=0; il<nl; ++il) {
        for (int ik=0; ik<nk; ++ik) {
          d0 += _e0[ik]*x[il][ik];
          d1 += _e1[ik]*x[il][ik];
        }
      }
      trace("M.test: d0="+d0+" d1="+d1);
    }
    private void subtract01(float[][] x) {
      int nk = x[0].length;
      int nl = x.length;
      double d0 = 0.0;
      double d1 = 0.0;
      for (int il=0; il<nl; ++il) {
        for (int ik=0; ik<nk; ++ik) {
          d0 += _e0[ik]*x[il][ik];
          d1 += _e1[ik]*x[il][ik];
        }
      }
      for (int il=0; il<nl; ++il) {
        for (int ik=0; ik<nk; ++ik) {
          x[il][ik] -= d0*_e0[ik];
          x[il][ik] -= d1*_e1[ik];
        }
      }
    }
    private RecursiveExponentialFilter _ref;
    float[] _e0,_e1; // constant and linear basis sequences
  }

  private static void makeRhs(float[][] tz, int[][] tc, Pairs[] ps, double[][] y) {
    int nt = y[0].length; // number of depths
    int nl = y.length; // number of logs
    int np = ps.length; // number of log pairs
    zero(y); // zero y before accumulating below
    zero(tc);
    for (int ip=0; ip<np; ++ip) { // for all log pairs, ...
      Pairs p = ps[ip];
      int ilog = p.ilog;
      int jlog = p.jlog;
      double[] yi = y[ilog];
      double[] yj = y[jlog];
      float[] ti = tz[ilog];
      float[] tj = tz[jlog];
      int[] tci = tc[ilog];
      int[] tcj = tc[jlog];
      int[] is = p.is;
      int[] js = p.js;
      float ws = p.ws;
      int n = is.length;
      for (int k=0; k<n; ++k) { // for all index pairs (i,j), ...
        int ik = is[k];
        int jk = js[k];
        int it = (int)(ti[ik]+0.5f);
        int jt = (int)(tj[jk]+0.5f);
        if (0<=it && it<nt && 0<=jt && jt<nt) {
          ++tci[it];
          ++tcj[jt];
          double scl = (double)(ws*ws);
          double dif = jk-ik;
          dif *= scl;
          yi[it] += dif;
          yj[jt] -= dif;
        }
      }
    }
  }

  private static void applyLhs(
    float[][] tz, Pairs[] ps, double[][] x, double[][] y) 
  {
    int nt = x[0].length; // number of depths
    int nl = x.length; // number of logs
    int np = ps.length; // number of log pairs
    zero(y); // zero y before accumulating below
    for (int ip=0; ip<np; ++ip) { // for all log pairs, ...
      Pairs p = ps[ip];
      int ilog = p.ilog;
      int jlog = p.jlog;
      double[] xi = x[ilog];
      double[] xj = x[jlog];
      double[] yi = y[ilog];
      double[] yj = y[jlog];
      float[] ti = tz[ilog];
      float[] tj = tz[jlog];
      int[] is = p.is;
      int[] js = p.js;
      float ws = p.ws;
      int n = is.length;
      for (int k=0; k<n; ++k) { // for all index pairs (i,j), ...
        int ik = is[k];
        int jk = js[k];
        int it = (int)(ti[ik]+0.5f);
        int jt = (int)(tj[jk]+0.5f);
        if (0<=it && it<nt && 0<=jt && jt<nt) {
          double scl = (double)(ws*ws);
          double dif = xi[it]-xj[jt];
          dif *= scl;
          yi[it] += dif;
          yj[jt] -= dif;
        }
      }
    }
  }

  private static float dmin(float a, float b, float c) {
    float d = b;
    if (a<d) d = a;
    if (c<d) d = c;
    return d;
  }

  private float error(float f, float g) {
    float d = f-g;
    if (_epow==2.0f) {
      return d*d;
    } else if (_epow==1.0f) {
      return abs(d);
    } else {
      if (d<0.0f) d = -d;
      return pow(d,_epow);
    }
  }

  public int[] findGood(float[] f) {
    int n = f.length;
    int[] igood = new int[n];
    int ngood = 0;
    for (int i=0; i<n; ++i) {
      if (f[i]!=_vnull) {
        igood[ngood] = i;
        ++ngood;
      }
    }
    return copy(ngood,igood);
  }

  public float value(Random random, int[] igood, float[] f, int i) {
    int n = f.length;
    if (0<=i && i<n && f[i]!=_vnull) {
      return f[i];
    } else {
      int j = random.nextInt(igood.length);
      return f[igood[j]];
    }
  }

  private int kminNotNull(float[][] e) {
    int nk = e.length;
    int nl = e[0].length;
    for (int k=0; k<nk; ++k) {
      if (e[k][0]!=_enull || e[k][1]!=_enull)
        return k;
    }
    return nk;
  }

  private int kmaxNotNull(float[][] e) {
    int nk = e.length;
    int nl = e[0].length;
    for (int k=nk-1; k>=0; --k) {
      if (e[k][0]!=_enull || e[k][1]!=_enull)
        return k;
    }
    return -1;
  }

  private int iminNotNull(float[][] e) {
    int ni = e.length;
    int nj = e[0].length;
    for (int i=0; i<ni; ++i) {
      for (int j=0; j<nj; ++j) {
        if (e[i][j]!=_enull)
          return i;
      }
    }
    return ni;
  }

  private int imaxNotNull(float[][] e) {
    int ni = e.length;
    int nj = e[0].length;
    for (int i=ni-1; i>=0; --i) {
      for (int j=0; j<nj; ++j) {
        if (e[i][j]!=_enull)
          return i;
      }
    }
    return -1;
  }

  private int jminNotNull(float[][] e) {
    int ni = e.length;
    int nj = e[0].length;
    for (int j=0; j<nj; ++j) {
      for (int i=0; i<ni; ++i) {
        if (e[i][j]!=_enull)
          return j;
      }
    }
    return nj;
  }

  private int jmaxNotNull(float[][] e) {
    int ni = e.length;
    int nj = e[0].length;
    for (int j=nj-1; j>=0; --j) {
      for (int i=0; i<ni; ++i) {
        if (e[i][j]!=_enull)
          return j;
      }
    }
    return -1;
  }

  // Post-processing and inversion of computed shifts.
  private static void cleanShifts(float[] s) {
    int n1 = s.length;
    for (int i1=1; i1<n1; ++i1) {
      if (s[i1]<s[i1-1]-0.999f)
        s[i1] = s[i1-1]-0.999f;
    }
  }
  private static void cleanShiftsRS(float[] s) {
    int n1 = s.length;
    for (int i1=1; i1<n1; ++i1) {
      if (s[i1]>s[i1-1]+0.999f)
        s[i1] = s[i1-1]+0.999f;
    }
  }
  private static void cleanShiftsR(float[] tts,float[] r) {
    int n1 = r.length;
    for (int i1=1; i1<n1; ++i1) {
      if (r[i1]>tts[i1]-tts[i1-1]+r[i1-1]-0.001f)
        r[i1]=tts[i1]-tts[i1-1]+r[i1-1]-0.001f;
    }
  }
  private static void cleanZorT(float[] t) {
    int n1 = t.length;
    for (int i1=1; i1<n1; ++i1) {
      if (t[i1]<t[i1-1]+0.001f) 
        t[i1] = t[i1-1]+0.001f;
    }
  }
  private static float[] cleanZorT2(float[] t) {
    int n1 = t.length;
    float[] zs = zerofloat(n1);
    for (int i1=1; i1<n1; ++i1) {
      if (t[i1]<t[i1-1]+0.001f) {
        zs[i1] = t[i1]-(t[i1-1]+0.001f);
        t[i1] = t[i1-1]+0.001f;
      }
    }
    return zs;
  }
  public static void invertZorT(float[] zb) {
    int n = zb.length;
    float[] x = rampfloat(0.0f,1.0f,n);
    float[] tb = zerofloat(n);
    cleanZorT(zb);
    inverseInterpolate(x,zb,tb);
    copy(tb,zb);
  }
  private static void invertZorT(float[] u, float[] z, float[] t) {
    cleanZorT(t);
    inverseInterpolate(u,t,z);
    copy(z,t);
  }
  public static void invertZorT(float[][] t) {
    int n1 = t[0].length;
    int n2 = t.length;
    float[] u = rampfloat(0.0f,1.0f,n1);
    float[] z = zerofloat(n1);
    for (int i2=0; i2<n2; ++i2)
      invertZorT(u,z,t[i2]);
  }
  private static void invertShiftsR(float[] u, float[] t, float[] s) {
    cleanShiftsRS(s);
    int n1 = s.length;
    for (int i1=0; i1<n1; ++i1)
      s[i1] = u[i1] - s[i1];
    inverseInterpolate(u,s,t);
    for (int i1=0; i1<n1; ++i1) 
      s[i1] = t[i1]-u[i1];
  }
  public static void invertShiftsR(float[][] s) {
    int n1 = s[0].length;
    int n2 = s.length;
    float[] u = rampfloat(0.0f,1.0f,n1);
    float[] t = zerofloat(n1);
    for (int i2=0; i2<n2; ++i2)
      invertShiftsR(u,t,s[i2]);
  }
  private static void invertShifts(float[] u, float[] t, float[] s) {
    cleanShifts(s);
    int n1 = s.length;
    for (int i1=0; i1<n1; ++i1)
      s[i1] += u[i1];
    inverseInterpolate(u,s,t);
    for (int i1=0; i1<n1; ++i1) 
      s[i1] = u[i1]-t[i1];
  }
  public static void invertShifts(float[][] s) {
    int n1 = s[0].length;
    int n2 = s.length;
    float[] u = rampfloat(0.0f,1.0f,n1);
    float[] t = zerofloat(n1);
    for (int i2=0; i2<n2; ++i2)
      invertShifts(u,t,s[i2]);
  }
  public float[] iqr(float[][][] wells) {
    int nl = wells.length;
    int nc = wells[0].length;
    int nk = wells[0][0].length;
    float[] iqr = new float[nc];
    for (int c=0; c<nc; ++c) {
      float[] f = new float[nl*nk];
      int ik=0;
      for (int w=0; w<nl; ++w) {
        for (int k=0; k<nk; ++k) {
          if(wells[w][c][k]!=_vnull) {
            f[ik] = wells[w][c][k];
            ++ik;
          }
        }
      }
      float[] temp = copy(ik,f);
      int p25 = (int)(ceil(0.25f*ik)); 
      int p75 = (int)(ceil(0.75f*ik)); 
      quickPartialSort(p25,temp);
      float t25 = temp[p25];
      quickPartialSort(p75,temp);
      float t75 = temp[p75];
      iqr[c] = 1.0f/(t75-t25);
    }
    return iqr;
  }
  public static void stats(float[] wl) {
    int nk = wl.length;
    int nn = 0;
    for (int k=0; k<nk; ++k) {
      if (wl[k]!=-999.2500) {
        ++nn;
      }
    }
    if (nn>0) {
      float[] good = zerofloat(nn);
      nn = 0;
      for (int k=0; k<nk; ++k) {
        if (wl[k]!=-999.2500) {
          good[nn] = wl[k];
          ++nn;
        }
      }
      int p25 = (int)(ceil(0.25*nn));
      int p50 = (int)(ceil(0.50*nn));
      int p75 = (int)(ceil(0.75*nn));
      quickPartialSort(p25,good);
      float g25 = good[p25];
      quickPartialSort(p50,good);
      float med = good[p50];
      quickPartialSort(p75,good);
      float g75 = good[p75];
      float iqr = (g75-g25);
      float mean = sum(good)/nn;
      float[] diff = sub(good,mean);
      float[] sq = mul(diff,diff);
      float stdev = sqrt(sum(sq)/nn);
      System.out.println("mean="+mean+" stdev="+stdev);
      System.out.println(" med="+med+"  iqr="+iqr);
    } else {
      System.out.println("Null log");
    }
  }

  public static void histogram(String c, float[] wl) {
    int nk = wl.length;
    int nn = 0;
    for (int k=0; k<nk; ++k) {
      if (wl[k]!=-999.2500) {
        ++nn;
      }
    }
    if (nn>0) {
      float[] good = zerofloat(nn);
      nn = 0;
      for (int k=0; k<nk; ++k) {
        if (wl[k]!=-999.2500) {
          good[nn] = wl[k];
          ++nn;
        }
      }
      Histogram h = new Histogram(good);
      Sampling sb = h.getBinSampling();
      float[] d = h.getDensities();
      SimplePlot sp = new SimplePlot();
      sp.setHLabel(c);
      PointsView pv = sp.addPoints(sb,d);
    } else {
      System.out.println("Null log");
    }
  }

  private static void errorHist(String t,Pairs[] ps, float[][] s) {
    int np = ps.length;
    int nl = s.length;
    int nk = s[0].length;
    int nij = 0;
    float sum = 0;
    float[] et = new float[np*nl*nk];
    for (int ip=0; ip<np; ++ip) { // for all log pairs, ...
      Pairs p = ps[ip];
      int ilog = p.ilog;
      int jlog = p.jlog;
      int[] is = p.is;
      int[] js = p.js;
      int n = is.length;
      for (int k=0; k<n; ++k) { // for all index pairs (i,j), ...
        int ik = is[k];
        int jk = js[k];
        float dz = jk-ik;
        float ds = s[ilog][ik] - s[jlog][jk];
        et[nij] = (dz-ds);
        ++nij;
      }
    }
    float[] e = copy(nij,et);
    Histogram h = new Histogram(e);
    Sampling sb = h.getBinSampling();
    float[] d = h.getDensities();
    SimplePlot sp = new SimplePlot();
    sp.setHLabel(t);
    PointsView pv = sp.addPoints(sb,d);
    sp.setVLimits(-0.001f,0.09f);
    //sp.setHLimits(-40.0f,40.0f);
  }

  private static float rms(Pairs[] ps, float[][] s) {
    int np = ps.length;
    int nl = s.length;
    int nk = s[0].length;
    int nij = 0;
    float sum = 0;
    for (int ip=0; ip<np; ++ip) { // for all log pairs, ...
      Pairs p = ps[ip];
      int ilog = p.ilog;
      int jlog = p.jlog;
      int[] is = p.is;
      int[] js = p.js;
      int n = is.length;
      for (int k=0; k<n; ++k) { // for all index pairs (i,j), ...
        int ik = is[k];
        int jk = js[k];
        float dz = jk-ik;
        float ds = s[ilog][ik] - s[jlog][jk];
        sum += (dz-ds)*(dz-ds);
        ++nij;
      }
    }
    return sqrt(sum/nij);
  }
  private void clipShifts(float[][] s) {
    int nl = s.length;
    int nk = s[0].length;
    for (int l=0; l<nl; ++l) {
      for (int k=0; k<nk; ++k) {
        if (s[l][k]>_lmax) s[l][k] = _lmax;
        if (s[l][k]<-_lmax) s[l][k] = -_lmax;
      }
    }
  }
  
  private static void interpolate(float[] u, float[] x, float[] v, float[] y) {
    CubicInterpolator ci =
      new CubicInterpolator(CubicInterpolator.Method.LINEAR,u,x);
    ci.interpolate(v,y);
  }

  private static void inverseInterpolate(float[] u, float[] x, float[] y) {
    CubicInterpolator ci =
      new CubicInterpolator(CubicInterpolator.Method.LINEAR,x,u);
    ci.interpolate(u,y);
  }

  private static void interpolateShifts(boolean[][] nls, float[][] s) {
    int nk = s[0].length;
    int nl = s.length;
    int klo,khi,fk,lk;
    for (int l=0; l<nl; ++l) {
      int ki=0;
      while (ki<nk && nls[l][ki]) ki++;
      fk = ki;
      ki=nk-1;
      while (ki>=0 && nls[l][ki]) ki--;
      lk = ki;
      for (int k=0; k<fk; ++k) {
        s[l][k] = s[l][fk];
      }
      for (int k=fk; k<=lk; ++k) {
        if (nls[l][k]) {
          klo = khi = k;
          while (klo>fk && nls[l][klo]) klo -= 1;
          while (khi<lk && nls[l][khi]) khi += 1; 
          s[l][k] = ((khi-k)*(s[l][klo]) + (k-klo)*(s[l][khi]))/(khi-klo);
          //s[l][k] = ((khi-k)*(klo+s[l][klo]) + (k-klo)*(khi+s[l][khi]))/(khi-klo) - k;
        }
      }
      for (int k=lk+1; k<nk; ++k) {
        s[l][k] = s[l][lk];
      }
    }
  }

  private static void interpolateShifts(int csmall, int[][] c, float[][] s) {
    int nt = s[0].length;
    int nl = s.length;
    for (int il=0; il<nl; ++il) {
      int it=0;
      while (it<nt-1 && c[il][it]<csmall) ++it;
      for (int t=0; t<it; ++t)
        s[il][t] = s[il][it];
    }
  }

/*
  private static void interpolateShifts(int[][] tc, float[][] s) {
    int nk = s[0].length;
    int nl = s.length;
    float[] tempS = new float[nk];
    float[] tempX = new float[nk];
    float[] allZ = rampfloat(0.0f,1.0f,nk);
    int ntc;
    for (int il=0; il<nl; ++il) {
      zero(tempS);
      ntc = 0;
      for (int ik=0; ik<nk; ++ik) {
        if (tc[il][ik]>0) {
          tempS[ntc] = s[il][ik];
          tempX[ntc] = ik;
          ++ntc;
        }
      }
      float[] tmpS = new float[ntc+2]; 
      float[] tmpX = new float[ntc+2];
      tmpS[0]=tempS[0];
      tmpX[0]=tempX[0]-1;
      tmpS[ntc+1]=tempS[ntc-1];
      tmpX[ntc+1]=tempX[ntc-1]+1;
      for (int ik=1; ik<ntc+1; ++ik) {
        tmpS[ik]=tempS[ik-1];
        tmpX[ik]=tempX[ik-1];
      }
      interpolate(tmpX,tmpS,allZ,s[il]);
    }
  }
*/
  private boolean wellNotNull(float[] f) {
    int nk = f.length;
    for (int ik=0; ik<nk; ++ik) {
      if (f[ik]!=_vnull) return true;
    }
    return false;
  }
  private static void subtractMeanOverLogs(double[][] r) {
    int nt = r[0].length;
    int nl = r.length;
    double[] s = zerodouble(nt);
    for (int il=0; il<nl; ++il) 
      for (int it=0; it<nt; ++it) 
        s[it] += r[il][it];
    double c = 1.0d/nl;
    for (int il=0; il<nl; ++il) 
      for (int it=0; it<nt; ++it) 
        r[il][it] -= s[it]*c;
  }
  private static void accumulateForward(double[][] r) {
    int nt = r[0].length;
    int nl = r.length;
    for (int il=0; il<nl; ++il) 
      for (int it=1; it<nt; ++it)
        r[il][it] += r[il][it-1];
  }
  private static void accumulateReverse(double[][] r) {
    int nt = r[0].length;
    int nl = r.length;
    for (int il=0; il<nl; ++il)
      for (int it=nt-2; it>=0; --it)
        r[il][it] += r[il][it+1];
  }
  private static void smoothGaps(int csmall, int[][] c, double[][] q) {
    int nt = q[0].length;
    int nl = q.length;
    int tm, tp;
    for (int il=0; il<nl; ++il) {
      for (int it=0; it<nt; ++it) {
        if (c[il][it]<csmall) {
          tm = tp = it;
          while (tp<nt && c[il][tp]<csmall) ++tp;
          while (tm>=0 && c[il][tm]<csmall) --tm;
          if (tp>=nt) {
            for (int ti=tm+1; ti<nt; ++ti) 
              q[il][ti] *= 0;
            it = nt;
          } else if (tm<0) {
            for (int ti=0; ti<tp; ++ti) 
              q[il][ti] *= 0;
            it = tp;
          } else {
            double a = 0;
            for (it=tm+1; it<=tp; ++it) 
              a += q[il][it];
            a /= (tp-tm);
            for (it=tm+1; it<=tp; ++it) 
              q[il][it] = a;
            it = tp;
          }
        }
      }
      int it=0;
      while (it<nt-1 && c[il][it]<csmall) ++it;
      swap(0,it,q[il]);
    }
  }
  private static void smoothGapsTranspose(int csmall, int[][] c, double[][] q) {
    int nt = q[0].length;
    int nl = q.length;
    int tm, tp;
    for (int il=0; il<nl; ++il) {
      int it=0;
      while (it<nt-1 && c[il][it]<csmall) ++it;
      swap(0,it,q[il]);
      for (it=0; it<nt; ++it) {
        if (c[il][it]<csmall) {
          tm = tp = it;
          while (tp<nt && c[il][tp]<csmall) ++tp;
          while (tm>=0 && c[il][tm]<csmall) --tm;
          if (tp>=nt) {
            for (int ti=tm+1; ti<nt; ++ti)
              q[il][ti] *= 0;
            it = nt;
          } else if (tm<0) {
            for (int ti=0; ti<tp; ++ti)
              q[il][ti] *= 0;
            it = tp;
          } else {
            double a = 0;
            for (it=tm+1; it<=tp; ++it)
              a += q[il][it];
            a /= (tp-tm);
            for (it=tm+1; it<=tp; ++it)
              q[il][it] = a;
            it = tp;
          }
        }
      }
    }
  }
  private static void swap(int x, int y, double[] q) {
    double qx = q[x];
    q[x] = q[y];
    q[y] = qx;
  }

  private static void norm(double[][] r) {
    int nl = r.length;
    int nk = r[0].length;
    double norm = 0;
    for (int il=0; il<nl; ++il)
      for (int ik=0; ik<nk; ++ik)
        norm += r[il][ik]*r[il][ik];
    norm = sqrt(norm);
    System.out.println("norm="+norm);
  }
  public void testSymmetry(float[] fi, float[] gj) {
    int nk = fi.length;
    float[][] e = computeErrors(fi,gj);
    float[][] ef = copy(e);
    for (int k=0; k<e.length; ++k) {
      ef[k] = e[e.length-1-k]; 
    }
    float[][] d = accumulateErrors(e);
    int[][] kl = findWarping(d);
    float[][] klf = new float[2][kl[0].length];
    for (int k=0; k<kl[0].length; ++k) {
      klf[0][k] = (float)kl[0][k];
      klf[1][k] = (float)kl[1][k];
    }

    PlotPanel pp = new PlotPanel();
    PointsView pv = pp.addPoints(klf[0],klf[1]);

    d = accumulateErrors(ef);
    kl = findWarping(d);
    for (int k=0; k<kl[0].length; ++k) {
      klf[0][k] = (float)kl[0][k];
      klf[1][k] = (float)kl[1][k];
    }
    pv = pp.addPoints(klf[0],klf[1]);
    PlotFrame pf = new PlotFrame(pp);
    pf.setVisible(true);
    pf.setDefaultCloseOperation(PlotFrame.EXIT_ON_CLOSE);
  }
  private static void trace(String s) {
    System.out.println(s);
  }
}
