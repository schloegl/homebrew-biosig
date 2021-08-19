class Stimfit < Formula
  desc "Fast and simple program for viewing and analyzing electrophyiological data"
  homepage "https://stimfit.org"
  url "https://github.com/neurodroid/stimfit/archive/v0.15.8windows.tar.gz"
  version "0.16.0"
  sha256 "8a5330612245d3f442ed640b0df91028aa4798301bb6844eaf1cf9b463dfc466"
  license "GPL-3.0-or-later"

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "swig" => :build
  # depends_on "matplotlib" => :build
  # depends_on "schloegl/biosig/pyemf" => :build
  depends_on "biosig"
  depends_on "boost"
  depends_on "fftw"
  depends_on "hdf5"
  depends_on "libx11"
  depends_on "numpy"
  depends_on "python"
  depends_on "wxpython"
  depends_on "wxwidgets"

  patch :DATA

  def install
    # ENV.deparallelize
    system "./autogen.sh && autoconf && automake"

    system "./configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}",
                          "PYTHON_VERSION=3",
                          "--with-biosig",
                          "--with-pslope"

    system "make", "PYTHON_VERSION=3"
    system "make", "install"
    #bin.install "stimfit"
  end

  def uninstall
    rm "#{bin}/stimfit"
  end

  def caveats
    <<~EOS
      This recipe is work-in-progress. 
      Stimfit compiles, but the final installation step needs some fixing.
      Unless this is fixed, Stimfit might not be usable. 
    EOS
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test stimfit`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "#{bin}/stimfit"
  end
end

__END__

diff --git a/configure.ac b/configure.ac
index ae91b89f..117255f3 100644
--- a/configure.ac
+++ b/configure.ac
@@ -57,7 +57,7 @@ AC_ARG_ENABLE([python],
 
 AM_CONDITIONAL(BUILD_PYTHON, test "$enable_python" = "yes")
 if (test "$enable_python" = "yes") || (test "$enable_module" = "yes"); then
-    AC_PYTHON_DEVEL
+    AC_PYTHON_DEVEL()
     AC_PROG_SWIG(1.3.17)
     SWIG_ENABLE_CXX
     SWIG_PYTHON
@@ -67,14 +67,17 @@ if (test "$enable_python" = "yes") || (test "$enable_module" = "yes"); then
     LIBPYTHON_LDFLAGS=$PYTHON_LDFLAGS 
     LIBPYTHON_INCLUDES=$PYTHON_CPPFLAGS
     LIBNUMPY_INCLUDES=$PYTHON_NUMPY_INCLUDE
+    LIBWXPYTHON_INCLUDES=$PYTHON_WXPYTHON_INCLUDE
 else
     LIBPYTHON_LDFLAGS= 
     LIBPYTHON_INCLUDES= 
     LIBNUMPY_INCLUDES= 
+    LIBWXPYTHON_INCLUDES= 
 fi
 AC_SUBST(LIBPYTHON_LDFLAGS)
 AC_SUBST(LIBPYTHON_INCLUDES)
 AC_SUBST(LIBNUMPY_INCLUDES)
+AC_SUBST(LIBWXPYTHON_INCLUDES)
 
 AC_MSG_CHECKING(for kernel)
 case ${STFKERNEL} in 
@@ -136,24 +139,26 @@ if test "$with_pslope" = "yes" ; then
     CPPFLAGS="${CPPFLAGS} -DWITH_PSLOPE"
 fi
 
-AC_ARG_WITH([biosig], AS_HELP_STRING([--with-biosig],[build with libbiosig support - better tested than --with-biosig2]),[])
-AM_CONDITIONAL(WITH_BIOSIG, test "$with_biosig" = "yes")
-
-AC_ARG_WITH([biosig2], AS_HELP_STRING([--with-biosig2],[alternative to --with-biosig - eventually, this will provide better ABI compatibility when upgrading libbiosig; currently it's in a testing state; requires libbiosig2 v1.5.6 or higher]),[])
-AM_CONDITIONAL(WITH_BIOSIG2, test "$with_biosig2" = "yes")
+# by default build WITH_BIOSIG
+AC_ARG_WITH([biosig],
+	[AS_HELP_STRING([--without-biosig], [disable support for biosig])],
+	[],
+	[with_biosig=yes] )
+AM_CONDITIONAL(WITH_BIOSIG, test "x$with_biosig" = "xyes")
+AM_CONDITIONAL(WITH_BIOSIG2, test "x$with_biosig" = "xyes")
 
 AC_ARG_WITH([biosiglite], AS_HELP_STRING([--with-biosiglite], [use builtin biosig library]), [])
-AM_CONDITIONAL(WITH_BIOSIGLITE, test "$with_biosiglite" = "yes")
+AM_CONDITIONAL(WITH_BIOSIGLITE, test "x$with_biosiglite" = "xyes")
+AM_CONDITIONAL(WITH_BIOSIG, test "x$with_biosig" = "xyes")
 
-if test "$with_biosig2" = "yes" ; then
-    CPPFLAGS="${CPPFLAGS} -DWITH_BIOSIG2"
-    LIBBIOSIG_LDFLAGS="-lbiosig2 -lcholmod"
-elif test "$with_biosig" = "yes" ; then
-    CPPFLAGS="${CPPFLAGS} -DWITH_BIOSIG"
-    LIBBIOSIG_LDFLAGS="-lbiosig -lcholmod"
-elif test "$with_biosiglite" = "yes" ; then
-    CPPFLAGS="${CPPFLAGS} -DWITH_BIOSIG2 -DWITH_BIOSIGLITE"
+if test "x$with_biosiglite" = xyes ; then
+    CPPFLAGS="${CPPFLAGS} -DWITH_BIOSIG -DWITH_BIOSIGLITE"
     LIBBIOSIG_LDFLAGS="-lcholmod"
+elif test "x$with_biosig" != xno ; then
+    CPPFLAGS="${CPPFLAGS} -DWITH_BIOSIG"
+    LIBBIOSIG_LDFLAGS="-lbiosig"
+else
+    AC_MSG_ERROR([stimfit requries --with-biosig or --with-biosiglite])
 fi
 AC_SUBST(LIBBIOSIG_LDFLAGS)
 
@@ -168,6 +173,15 @@ AS_HELP_STRING([--with-lapack-lib=LAPACKLIB],[Provide full path to custom lapack
 ])
 
 # Checks for libraries.
+AC_CHECK_LIB([biosig], [sread], [with_biosig="yes"])
+AM_CONDITIONAL(WITH_BIOSIG, test "x$with_biosig" == "xyes")
+if test "x$with_biosiglite" != "xyes" ; then
+if test "x$with_biosig" == "xyes" ; then
+    CPPFLAGS="${CPPFLAGS} -DWITH_BIOSIG"
+    LIBBIOSIG_LDFLAGS="-lbiosig"
+fi
+fi
+
 AC_CHECK_LIB([fftw3], [fftw_malloc], HAVE_FFTW3="yes")
 if test "${HAVE_FFTW3}" != "yes" ; then
     AC_MSG_ERROR([Couldn't find fftw3.])
diff --git a/m4/acsite.m4 b/m4/acsite.m4
index f37ddd71..574c2360 100755
--- a/m4/acsite.m4
+++ b/m4/acsite.m4
@@ -46,7 +46,7 @@ to something else than an empty string.
         if test -n "$1"; then
                 AC_MSG_CHECKING([for a version of Python $1])
                 ac_supports_python_ver=`$PYTHON -c "import sys, string; \
-                        ver = string.split(sys.version)[[0]]; \
+                        ver = sys.version.split()[[0]]; \
                         sys.stdout.write(ver + '$1' + '\n')"`
                 if test "$ac_supports_python_ver" = "True"; then
                    AC_MSG_RESULT([yes])
@@ -196,6 +196,32 @@ $ac_numpy_result])
         AC_MSG_RESULT([$PYTHON_NUMPY_INCLUDE])
         AC_SUBST([PYTHON_NUMPY_INCLUDE])
 
+        #
+        # Check if you have wxPython, else fail
+        #
+        AC_MSG_CHECKING([for wxPython])
+        ac_wxpython_result=`$PYTHON -c "import wx" 2>&1`
+        if test -z "$ac_wxpython_result"; then
+                AC_MSG_RESULT([yes])
+        else
+                AC_MSG_RESULT([no])
+                AC_MSG_ERROR([cannot import Python module "wxpython".
+Please check your wxpython installation. The error was:
+$ac_wxpython_result])
+                PYTHON_VERSION=""
+        fi
+
+        #
+        # Check for wxpython headers
+        #
+        AC_MSG_CHECKING([for wxpython include path])
+        if test -z "$PYTHON_WXPYTHON_INCLUDE"; then
+                PYTHON_WXPYTHON_INCLUDE=-I`$PYTHON -c "import os, sys, wx; \
+                        sys.stdout.write(os.path.join(os.path.dirname(wx.__spec__.origin), 'include') + '\n');"`
+        fi
+        AC_MSG_RESULT([$PYTHON_WXPYTHON_INCLUDE])
+        AC_SUBST([PYTHON_WXPYTHON_INCLUDE])
+
         #
         # libraries which must be linked in when embedding
         #
diff --git a/manuscript/events.py b/manuscript/events.py
new file mode 100644
index 00000000..276740be
--- /dev/null
+++ b/manuscript/events.py
@@ -0,0 +1,626 @@
+from __future__ import print_function
+
+import sys
+import os
+
+import numpy as np
+np.random.seed(42)
+import matplotlib.pyplot as plt
+import matplotlib.gridspec as gridspec
+from matplotlib.patches import ConnectionPatch
+from scipy.optimize import leastsq
+
+import stfio
+import stfio_plot
+
+try:
+    import spectral
+except ImportError:
+    pass
+
+class Bardata(object):
+    def __init__(self, mean, err=None, data=None, title="", color='k'):
+        self.mean = mean
+        self.err = err
+        self.data = data
+        self.title = title
+        self.color = color
+
+def bargraph(datasets, ax, ylabel=None, labelpos=0, ylim=None, paired=False):
+
+    if paired:
+        assert(len(datasets)==2)
+        assert(datasets[0].data is not None and datasets[1].data is not None)
+        assert(len(datasets[0].data)==len(datasets[0].data))
+
+    ax.axis["right"].set_visible(False)
+    ax.axis["top"].set_visible(False)
+    ax.axis["bottom"].set_visible(False)
+
+    bar_width = 0.6
+    gap2 = 0.15         # gap between series
+    pos = 0
+    xys = []
+    for data in datasets:
+        pos += gap2
+        ax.bar(pos, data.mean, width=bar_width, color=data.color, edgecolor='k')
+        if data.data is not None:
+            ax.plot([pos+bar_width/2.0 for dat in data.data], 
+                    data.data, 'o', ms=15, mew=0, lw=1.0, alpha=0.5, mfc='grey', color='grey')#grey')
+            if paired:
+                xys.append([[pos+bar_width/2.0, dat] for dat in data.data])
+
+        if data.err is not None:
+            yerr_offset = data.err/2.0
+            if data.mean < 0:
+                sign=-1
+            else:
+                sign=1
+            erb = ax.errorbar(pos+bar_width/2.0, data.mean+sign*yerr_offset, yerr=sign*data.err/2.0, fmt=None, ecolor='k', capsize=6)
+            if data.err==0:
+                for erbs in erb[1]:
+                    erbs.set_visible(False)
+            erb[1][0].set_visible(False) # make lower error cap invisible
+
+        ax.text(pos+bar_width, labelpos, data.title, ha='right', va='top', rotation=20)
+
+        pos += bar_width+gap2
+
+    if paired:
+        for nxy in range(len(datasets[0].data)):
+            ax.plot([xys[0][nxy][0],xys[1][nxy][0]], [xys[0][nxy][1],xys[1][nxy][1]], '-k')#grey')
+
+    if ylabel is not None:
+        ax.set_ylabel(ylabel)
+    if ylim is not None:
+        ax.set_ylim(ylim)
+
+def leastsq_helper(p,y,lsfunc,x):
+    return y - lsfunc(p,x)
+
+def fexpbde(p, x):
+    offset, delay, tau1, amp, tau2 = p
+
+    if delay < 0:
+        return np.ones(x.shape) * 1e9
+    e1 = np.exp((delay-x)/tau1);
+    e2 = np.exp((delay-x)/tau2);
+    y = amp*e1 - amp*e2 + offset;
+    y[x<delay] = offset
+
+    return y
+
+def find_peaks(data, dt, threshold, min_interval=None):
+    """
+    Finds peaks in data that are above a threshold.
+
+    Arguments:
+    data --          1D NumPy array
+    dt --            Sampling interval
+    threshold --     Threshold for peak detection
+    min_interval --  Minimal interval between peaks
+
+    Returns:
+    Peak indices within data.
+    """
+    peak_start_i = np.where(np.diff((data > threshold)*1.0)==1)[0]
+    peak_end_i = np.where(np.diff(
+        (data[peak_start_i[0]:] > threshold)*1.0)==-1)[0] + peak_start_i[0]
+    peak_i = np.array([
+        np.argmax(data[peak_start_i[ni]:peak_end_i[ni]])+peak_start_i[ni]
+        for ni, psi in enumerate(peak_start_i[:len(peak_end_i)])])
+    if min_interval is not None:
+        while np.any(np.diff(peak_i)*dt <= min_interval):
+            peak_i = peak_i[np.diff(peak_i)*dt > min_interval]
+
+    return peak_i
+
+def correct_peaks(data, peak_i, i_before, i_after):
+    """
+    Finds and corrects misplaced peak indices.
+
+    Arguments:
+    data --          1D NumPy array
+    peak_i --        Peak indices
+    i_before --      Sampling points to be considered before the peak
+    i_before --      Sampling points to be considered after the peak
+
+    Returns:
+    Corrected peak indices within data.
+    """
+    new_peak_i = []
+    for pi in peak_i:
+        old_pi = pi
+        real_pi = np.argmax(data[pi-i_before:
+                                        pi+i_after])+pi-i_before
+        while real_pi != old_pi:
+            old_pi = real_pi
+            real_pi = np.argmax(data[real_pi-i_before:
+                                     real_pi+i_after])+real_pi-i_before
+
+        new_peak_i.append(real_pi)
+    # Remove duplicates
+    new_peak_i = np.array(list(set(new_peak_i)))
+
+    return new_peak_i
+
+def generate_events(t, mean_f):
+    dt = t[1]-t[0]
+    assert(np.sum(np.diff(t)-dt) < 1e-15)
+
+    prob_per_dt = mean_f * dt
+    event_prob = np.random.uniform(0, 1, (len(t)))
+    event_times_i = np.where(event_prob < prob_per_dt)[0]
+    assert(np.all(np.diff(event_times_i)))
+
+    return event_times_i * dt
+
+def ball_and_stick(h):
+    soma = h.Section()
+    soma.L = 20.0
+    soma.diam = 20.0
+    soma.nseg = 5
+
+    dend = h.Section()
+    dend.L = 500.0
+    dend.diam = 5.0
+    dend.nseg = 31
+
+    dend.connect(soma)
+
+    for sec in [soma, dend]:
+        sec.insert('pas')
+        sec.Ra = 150.0
+        for seg in sec:
+            seg.pas.e = -80.0
+            seg.pas.g = 1.0/25000.0
+
+    soma.push()
+
+    return soma, dend
+
+def add_noise(data, dt, mean_amp, snr=5.0):
+    sigma = mean_amp/snr
+    noise = np.random.normal(0, sigma, data.shape[0])
+    std_orig = noise.std()
+    noise = spectral.lowpass(spectral.Timeseries(noise, dt), 1.0)
+    std_new = noise.data.std()
+    noise.data *= std_orig/std_new
+    return data+noise.data
+
+def run(dt_nrn, tstop, mean_f):
+
+    module_dir = os.path.dirname(__file__)
+    if os.path.exists("%s/dat/events.h5" % module_dir):
+        rec = stfio.read("%s/dat/events.h5" % module_dir)
+        spiketimes = np.load("%s/dat/spiketimes.npy" % module_dir)
+        return rec, spiketimes
+
+    if os.path.exists("%s/dat/events_nonoise.npy" % module_dir):
+        mrec = np.load("%s/dat/events_nonoise.npy" % module_dir)
+        spiketimes = np.load("%s/dat/spiketimes.npy" % module_dir)
+    else:
+        from neuron import h
+        h.load_file('stdrun.hoc')
+
+        soma, dend = ball_and_stick(h)
+        h.tstop = tstop
+
+        trange = np.arange(0, tstop+dt_nrn, dt_nrn)
+        spiketimes = generate_events(trange, mean_f)
+        np.save("%s/dat/spiketimes.npy" % module_dir, spiketimes)
+
+        syn_AMPA, spiketimes_nrn, vecstim, netcon = [], [], [], []
+        for spike in spiketimes:
+            loc = 0.8 * np.random.normal(1.0, 0.03)
+            if loc < 0:
+                loc = 0
+            if loc > 1:
+                loc = 1
+            syn_AMPA.append(h.Exp2Syn(dend(loc), sec=dend))
+            spiketimes_nrn.append(h.Vector([spike]))
+            vecstim.append(h.VecStim())
+            netcon.append(h.NetCon(vecstim[-1], syn_AMPA[-1]))
+
+            syn_AMPA[-1].tau1 = 0.2 * np.random.normal(1.0, 0.3)
+            if syn_AMPA[-1].tau1 < 0.05:
+                syn_AMPA[-1].tau1 = 0.05
+            syn_AMPA[-1].tau2 = 2.5 * np.random.normal(1.0, 0.3)
+            if syn_AMPA[-1].tau2 < syn_AMPA[-1].tau1*1.5:
+                syn_AMPA[-1].tau2 = syn_AMPA[-1].tau1 * 1.5
+            syn_AMPA[-1].e = 0
+
+            vecstim[-1].play(spiketimes_nrn[-1])
+            netcon[-1].weight[0] = np.random.normal(1.0e-3, 1.0e-4)
+            if netcon[-1].weight[0] < 0:
+                netcon[-1].weight[0] = 0
+            netcon[-1].threshold = 0.0
+
+        vclamp = h.SEClamp(soma(0.5), sec=soma)
+        vclamp.dur1 = tstop
+        vclamp.amp1 = -80.0
+        vclamp.rs = 5.0
+        mrec = h.Vector()
+        mrec.record(vclamp._ref_i)
+
+        h.dt = dt_nrn # ms
+        h.steps_per_ms = 1.0/h.dt
+        h.v_init = -80.0
+        h.run()
+
+        mrec = np.array(mrec)
+        np.save("%s/dat/events_nonoise.npy" % module_dir, mrec)
+
+    plt.plot(np.arange(len(mrec), dtype=np.float) * dt_nrn, mrec)
+
+    peak_window_i = 20.0 / dt_nrn
+    amps_i = np.array([int(np.argmin(mrec[onset_i:onset_i+peak_window_i])+onset_i)
+                       for onset_i in spiketimes/dt_nrn], dtype=np.int)
+
+    plt.plot(amps_i * dt_nrn, mrec[amps_i], 'o')
+
+    mean_amp = np.abs(mrec[amps_i].mean())
+    print(mean_amp)
+    mrec = add_noise(mrec, dt_nrn, mean_amp)
+    plt.plot(np.arange(len(mrec), dtype=np.float) * dt_nrn, mrec)
+
+    seclist = [stfio.Section(mrec),]
+    chlist = [stfio.Channel(seclist),]
+    chlist[0].yunits = "pA"
+    rec = stfio.Recording(chlist)
+    rec.dt = dt_nrn
+    rec.xunits = "ms"
+    rec.write("%s/dat/events.h5" % module_dir)
+
+    return rec, spiketimes
+
+def template(pre_event=5.0, post_event=15.0, sd_factor=4.0, min_interval=5.0,
+             tau1_guess=0.5, tau2_guess=3.0):
+
+    module_dir = os.path.dirname(__file__)
+
+    if os.path.exists("%s/dat/template.npy" % module_dir):
+        return np.load("%s/dat/template.npy" % module_dir), \
+            np.load("%s/dat/template_epscs.npy" % module_dir), \
+            np.load("%s/dat/spiketimes.npy" % module_dir)
+
+    rec, spiketimes = run(0.01, 60000.0, 0.005)
+    
+    i_before = int(pre_event/rec.dt)
+    i_after = int(post_event/rec.dt)
+
+    # Find large peaks:
+    trace = -np.array(rec[0][0])
+    print(trace.mean(), trace.min(), trace.max())
+    rec_threshold = trace.mean() + trace.std()*sd_factor
+    peak_i = find_peaks(trace, rec.dt, rec_threshold, min_interval)
+
+    # Correct for wrongly placed peaks after min_interval check:
+    peak_i = correct_peaks(trace, peak_i, i_before, i_after)
+
+    print("    Aligning events... ", end="")
+    sys.stdout.flush()
+    # offset, delay, tau1, amp, tau2 = p
+
+    epscs = []
+    for pi in peak_i:
+        # Fit a function to each event to estimate its timing
+        epsc = trace[pi-i_before:pi+i_after]
+        t_epsc = np.arange(len(epsc)) * rec.dt
+        p0 = [0, pre_event, tau1_guess, np.max(epsc)*4.0, tau2_guess]
+        try:
+            plsq = leastsq(leastsq_helper, p0, 
+                           args = (epsc, fexpbde, t_epsc))
+        except RuntimeWarning:
+            pass
+        delay_i = int(plsq[0][1]/rec.dt+pi-i_before)
+        new_epsc = trace[delay_i-i_before:delay_i+i_after]
+        # Reject badly fitted events:
+        if np.argmax(new_epsc)*rec.dt > 0.8*pre_event:
+            epscs.append(new_epsc)
+
+    epscs = np.array(epscs)
+    print("done")
+
+    print("    Computing mean epsc ... ", end="")
+    sys.stdout.flush()
+    mean_epsc = np.mean(epscs, axis=0)
+    p0 = [0, pre_event, tau1_guess, np.max(mean_epsc)*4.0, tau2_guess]
+    plsq = leastsq(leastsq_helper, p0, 
+                   args = (mean_epsc, fexpbde, t_epsc))
+
+    sys.stdout.write(" done\n")
+
+    templ = fexpbde(plsq[0], t_epsc)[plsq[0][1]/rec.dt:]
+    np.save("%s/dat/template.npy" % module_dir, templ)
+    np.save("%s/dat/template_epscs.npy" % module_dir, epscs)
+
+    print("done")
+
+    return templ, epscs, spiketimes
+
+def figure():
+    sd_factor=5.0
+    # to yield a low total number of false positive and negative events:
+    deconv_th=4.0
+    matching_th=2.5
+    deconv_min_int=5.0
+    matching_min_int=5.0
+
+    module_dir = os.path.dirname(__file__)
+
+    import stf
+    if not stf.file_open("%s/dat/events.h5" % module_dir):
+        sys.stderr.write("Couldn't open %s/dat/events.h5; aborting now.\n" % 
+                         module_dir)
+        return
+    dt = stf.get_sampling_interval()
+    trace = stf.get_trace() * 1e3
+    plot_start_t = 55310.0
+    plot_end_t = 55640.0
+    plot_hi_start_t = 55489.0
+    plot_hi_end_t = 55511.0
+    plot_start_i = int(plot_start_t/dt)
+    plot_end_i = int(plot_end_t/dt)
+    plot_hi_start_i = int(plot_hi_start_t/dt)
+    plot_hi_end_i = int(plot_hi_end_t/dt)
+    plot_trace = trace[plot_start_i:plot_end_i]
+    plot_hi_trace = trace[plot_hi_start_i:plot_hi_end_i]
+    trange = np.arange(len(plot_trace)) * dt
+    trange_hi = np.arange(len(plot_hi_trace)) * dt
+    templ, templ_epscs, spiketimes = template(sd_factor=sd_factor)
+    plot_templ = templ * 1e3
+    templ_epscs *= 1e3
+    rec_threshold = trace.mean() - trace.std()*sd_factor
+    t_templ = np.arange(templ_epscs.shape[1]) * dt
+
+    # subtract baseline and normalize template:
+    templ -= templ[0]
+    if np.abs(templ.min()) > np.abs(templ.max()):
+        templ /= np.abs(templ.min())
+    else:
+        templ /= templ.max()
+    deconv_amps, deconv_onsets, deconv_crit, \
+        matching_amps, matching_onsets, matching_crit = \
+        events(-templ, deconv_th=deconv_th, matching_th=matching_th, 
+               deconv_min_int=deconv_min_int, matching_min_int=matching_min_int)
+
+    theoretical_ieis = np.diff(spiketimes)
+    theoretical_peaks_t = spiketimes # + np.argmax(templ)*dt
+    theoretical_peaks_t_plot = theoretical_peaks_t[
+        (theoretical_peaks_t > plot_start_i*dt) & 
+        (theoretical_peaks_t < plot_end_i*dt)] - plot_start_i*dt + 1.0
+    theoretical_peaks_t_plot_hi = theoretical_peaks_t[
+        (theoretical_peaks_t > plot_hi_start_i*dt) & 
+        (theoretical_peaks_t < plot_hi_end_i*dt)] - plot_hi_start_i*dt + 1.0
+
+    deconv_peaks_t = deconv_onsets# + np.argmax(templ)*dt
+    deconv_peaks_t_plot = deconv_peaks_t[
+        (deconv_peaks_t > plot_start_i*dt) & 
+        (deconv_peaks_t < plot_end_i*dt)] - plot_start_i*dt
+    deconv_peaks_t_plot_hi = deconv_peaks_t[
+        (deconv_peaks_t > plot_hi_start_i*dt) & 
+        (deconv_peaks_t < plot_hi_end_i*dt)] - plot_hi_start_i*dt
+    matching_peaks_t = matching_onsets# + np.argmax(templ)*dt
+    matching_peaks_t_plot = matching_peaks_t[
+        (matching_peaks_t > plot_start_i*dt) & 
+        (matching_peaks_t < plot_end_i*dt)] - plot_start_i*dt
+    matching_peaks_t_plot_hi = matching_peaks_t[
+        (matching_peaks_t > plot_hi_start_i*dt) & 
+        (matching_peaks_t < plot_hi_end_i*dt)] - plot_hi_start_i*dt
+
+    deconv_correct = np.zeros((deconv_peaks_t.shape[0]))
+    matching_correct = np.zeros((matching_peaks_t.shape[0]))
+    for theor in theoretical_peaks_t:
+        if (np.abs(deconv_peaks_t-theor)).min() < deconv_min_int:
+            deconv_correct[(np.abs(deconv_peaks_t-theor)).argmin()] = True
+        if (np.abs(matching_peaks_t-theor)).min() < matching_min_int:
+            matching_correct[(np.abs(matching_peaks_t-theor)).argmin()] = True
+
+    total_events = spiketimes.shape[0]
+    deconv_TP = deconv_correct.sum()/deconv_correct.shape[0]
+    deconv_FP = (deconv_correct.shape[0]-deconv_correct.sum())/deconv_correct.shape[0]
+    deconv_FN = (total_events - deconv_correct.sum())/total_events
+    sys.stdout.write("True positives deconv: %.2f\n" % (deconv_TP*100.0))
+    sys.stdout.write("False positives deconv: %.2f\n" % (deconv_FP*100.0))
+    sys.stdout.write("False negatives deconv: %.2f\n" % (deconv_FN*100.0))
+    matching_TP = matching_correct.sum()/matching_correct.shape[0]
+    matching_FP = (matching_correct.shape[0]-matching_correct.sum())/matching_correct.shape[0]
+    matching_FN = (total_events - matching_correct.sum())/total_events
+    sys.stdout.write("True positives matching: %.2f\n" % (matching_TP*100.0))
+    sys.stdout.write("False positives matching: %.2f\n" % (matching_FP*100.0))
+    sys.stdout.write("False negatives matching: %.2f\n" % (matching_FN*100.0))
+        
+    gs = gridspec.GridSpec(11, 13)
+    fig = plt.figure(figsize=(16,12))
+
+    ax = stfio_plot.StandardAxis(fig, gs[:5,:6], hasx=False, hasy=False)
+    ax.plot(trange, plot_trace, '-k', lw=2)
+    ax.plot(theoretical_peaks_t_plot, 
+            theoretical_peaks_t_plot**0*np.max(plot_trace), 
+            'v', ms=12, mew=2.0, mec='k', mfc='None')
+    ax.axhline(rec_threshold, ls='--', color='r', lw=2.0)
+    stfio_plot.plot_scalebars(ax, xunits="ms", yunits="pA")
+
+    ax_templ = stfio_plot.StandardAxis(fig, gs[:5,7:], hasx=False, hasy=False, sharey=ax)
+    for epsc in templ_epscs:
+        ax_templ.plot(t_templ, -epsc, '-', color='0.5', alpha=0.5)
+    ax_templ.plot(t_templ, -templ_epscs.mean(axis=0), '-k', lw=2)
+    ax_templ.plot(t_templ[-plot_templ.shape[0]:], -plot_templ, '-r', lw=4, alpha=0.5)
+    stfio_plot.plot_scalebars(ax_templ, xunits="ms", yunits="pA", sb_yoff=0.1)
+
+    ax_matching = stfio_plot.StandardAxis(fig, gs[5:7,:6], hasx=False, hasy=False, 
+                                          sharex=ax)
+    ax_matching.plot(trange, matching_crit[plot_start_i:plot_end_i], '-g')
+    stfio_plot.plot_scalebars(ax_matching, xunits="ms", yunits="SD", nox=True)
+    ax_matching.axhline(matching_th, ls='--', color='r', lw=2.0)
+    ax_matching.plot(theoretical_peaks_t_plot, 
+                     theoretical_peaks_t_plot**0*1.25*np.max(
+                         matching_crit[plot_start_i:plot_end_i]), 
+                     'v', ms=12, mew=2.0, mec='k', mfc='None')
+    ax_matching.plot(matching_peaks_t_plot, 
+                     matching_peaks_t_plot**0*np.max(
+                         matching_crit[plot_start_i:plot_end_i]), 
+                     'v', ms=12, mew=2.0, mec='g', mfc='None')
+    ax_matching.set_ylim(None, 1.37*np.max(
+        matching_crit[plot_start_i:plot_end_i]))
+    ax_matching.set_title(r"Template matching")
+
+    ax_deconv = stfio_plot.StandardAxis(fig, gs[7:9,:6], hasx=False, hasy=False, 
+                                          sharex=ax)
+    ax_deconv.plot(trange, deconv_crit[plot_start_i:plot_end_i], '-b')
+    stfio_plot.plot_scalebars(ax_deconv, xunits="ms", yunits="SD")
+    ax_deconv.axhline(deconv_th, ls='--', color='r', lw=2.0)
+    ax_deconv.plot(theoretical_peaks_t_plot, 
+                     theoretical_peaks_t_plot**0*1.2*np.max(
+                         deconv_crit[plot_start_i:plot_end_i]), 
+                     'v', ms=12, mew=2.0, mec='k', mfc='None')
+    ax_deconv.plot(deconv_peaks_t_plot, 
+                     deconv_peaks_t_plot**0*np.max(
+                         deconv_crit[plot_start_i:plot_end_i]), 
+                     'v', ms=12, mew=2.0, mec='b', mfc='None')
+    ax_deconv.set_ylim(None, 1.3*np.max(
+        deconv_crit[plot_start_i:plot_end_i]))
+    ax_deconv.set_title(r"Deconvolution")
+
+    ax_hi = stfio_plot.StandardAxis(fig, gs[9:11,2:5], hasx=False, hasy=False)
+    ax_hi.plot(trange_hi, plot_hi_trace, '-k', lw=2)
+    ax_hi.plot(theoretical_peaks_t_plot_hi, 
+               theoretical_peaks_t_plot_hi*0 + 30.0, 
+               'v', ms=12, mew=2.0, mec='k', mfc='None')
+    ax_hi.plot(matching_peaks_t_plot_hi, 
+               matching_peaks_t_plot_hi*0 + 20.0,
+               'v', ms=12, mew=2.0, mec='g', mfc='None')
+    ax_hi.plot(deconv_peaks_t_plot_hi, 
+               deconv_peaks_t_plot_hi*0 + 10.0, 
+               'v', ms=12, mew=2.0, mec='b', mfc='None')
+    stfio_plot.plot_scalebars(ax_hi, xunits="ms", yunits="pA")
+
+    xA = plot_hi_start_t - plot_start_t
+    yA = deconv_crit[plot_start_i:plot_end_i].min()
+    con = ConnectionPatch(xyA=(xA, yA), xyB=(0, 1.0),
+                          coordsA="data", coordsB="axes fraction", 
+                          axesA=ax_deconv, axesB=ax_hi,
+                          arrowstyle="-", linewidth=1, color="k")
+    ax_deconv.add_artist(con)
+    xA += (plot_hi_end_t - plot_hi_start_t) * 0.9
+    con = ConnectionPatch(xyA=(xA, yA), xyB=(0.9, 1.0),
+                          coordsA="data", coordsB="axes fraction", 
+                          axesA=ax_deconv, axesB=ax_hi,
+                          arrowstyle="-", linewidth=1, color="k")
+    ax_deconv.add_artist(con)
+
+    ax_bars_matching = stfio_plot.StandardAxis(fig, gs[5:10,7:9])
+    matching_bars_FP = Bardata(matching_FP*1e2, title="False positives", color='g')
+    matching_bars_FN = Bardata(matching_FN*1e2, title="False negatives", color='g')
+    bargraph([matching_bars_FP, matching_bars_FN], ax_bars_matching, 
+             ylabel=r'Rate ($\%$)')
+    ax_bars_matching.set_title(r"Template matching")
+
+    ax_bars_deconv = stfio_plot.StandardAxis(fig, gs[5:10,10:12], hasy=False, sharey=ax_bars_matching)
+    deconv_bars_FP = Bardata(deconv_FP*1e2, title="False positives", color='b')
+    deconv_bars_FN = Bardata(deconv_FN*1e2, title="False negatives", color='b')
+    bargraph([deconv_bars_FP, deconv_bars_FN], ax_bars_deconv, 
+             ylabel=r'Error rate $\%$')
+    ax_bars_deconv.set_title(r"Deconvolution")
+    
+    fig.text(0.09, 0.9, "A", size='x-large', weight='bold', ha='left', va='top')
+    fig.text(0.53, 0.9, "B", size='x-large', weight='bold', ha='left', va='top')
+    fig.text(0.09, 0.58, "C", size='x-large', weight='bold', ha='left', va='top')
+    fig.text(0.53, 0.58, "D", size='x-large', weight='bold', ha='left', va='top')
+
+    plt.savefig("%s/../../manuscript/figures/Fig5/Fig5.svg" % module_dir)
+    
+    fig = plt.figure()
+    ieis_ax = fig.add_subplot(111)
+    ieis_ax.hist([np.diff(deconv_onsets), np.diff(matching_onsets), 
+                  theoretical_ieis], 
+                 bins=len(theoretical_ieis)/1.0, 
+                 cumulative=True, normed=True, histtype='step')
+    ieis_ax.set_xlabel("Interevent intervals (ms)")
+    ieis_ax.set_ylabel("Cumulative probability")
+    ieis_ax.set_xlim(0,800.0)
+    ieis_ax.set_ylim(0,1.0)
+
+def events(template, deconv_th=4.5, matching_th=3.0, deconv_min_int=5.0,
+           matching_min_int=5.0):
+    """
+    Detects events using both deconvolution and template matching. Requires
+    an arbitrary template waveform as input. Thresholds and minimal intervals
+    between events can be adjusted for both algorithms. Plots cumulative 
+    distribution functions.
+    """
+
+    module_dir = os.path.dirname(__file__)
+
+    if os.path.exists("%s/dat/deconv_amps.npy" % module_dir):
+        return np.load("%s/dat/deconv_amps.npy" % module_dir), \
+            np.load("%s/dat/deconv_onsets.npy" % module_dir), \
+            np.load("%s/dat/deconv_crit.npy" % module_dir), \
+            np.load("%s/dat/matching_amps.npy" % module_dir), \
+            np.load("%s/dat/matching_onsets.npy" % module_dir), \
+            np.load("%s/dat/matching_crit.npy" % module_dir)
+
+    # Compute criteria
+    deconv_amps, deconv_onsets, deconv_crit = \
+        detect(template, "deconvolution", deconv_th, 
+               deconv_min_int)
+    matching_amps, matching_onsets, matching_crit = \
+        detect(template, "criterion", matching_th, 
+               matching_min_int)
+
+    fig = plt.figure()
+
+    amps_ax = fig.add_subplot(121)
+    amps_ax.hist([deconv_amps, matching_amps], bins=50, cumulative=True, 
+                 normed=True, histtype='step')
+    amps_ax.set_xlabel("Amplitudes (pA)")
+    amps_ax.set_ylabel("Cumulative probability")
+
+    ieis_ax = fig.add_subplot(122)
+    ieis_ax.hist([np.diff(deconv_onsets), np.diff(matching_onsets)], bins=50, 
+                 cumulative=True, normed=True, histtype='step')
+    ieis_ax.set_xlabel("Interevent intervals (ms)")
+    ieis_ax.set_ylabel("Cumulative probability")
+
+    np.save("%s/dat/deconv_amps.npy" % module_dir, deconv_amps)
+    np.save("%s/dat/deconv_onsets.npy" % module_dir, deconv_onsets)
+    np.save("%s/dat/deconv_crit.npy" % module_dir, deconv_crit)
+    np.save("%s/dat/matching_amps.npy" % module_dir, matching_amps)
+    np.save("%s/dat/matching_onsets.npy" % module_dir, matching_onsets)
+    np.save("%s/dat/matching_crit.npy" % module_dir, matching_crit)
+
+    return deconv_amps, deconv_onsets, deconv_crit, \
+        matching_amps, matching_onsets, matching_crit
+
+def detect(template, mode, th, min_int):
+    """
+    Detect events using the given template and the algorithm specified in
+    'mode' with a threshold 'th' and a minimal interval of 'min_int' between
+    events. Returns amplitudes and interevent intervals.
+    """
+    import stf
+
+    # Compute criterium
+    crit = stf.detect_events(template, mode=mode, norm=False, lowpass=0.1, 
+                             highpass=0.001)
+
+    dt = stf.get_sampling_interval()
+
+    # Find event onset times (corresponding to peaks in criteria)
+    onsets_i = stf.peak_detection(crit, th, int(min_int/dt))
+
+    trace = stf.get_trace()
+
+    # Use event onset times to find event amplitudes (negative for epscs)
+    peak_window_i = min_int / dt
+    amps_i = np.array([int(np.argmin(trace[onset_i:onset_i+peak_window_i])+onset_i)
+                       for onset_i in onsets_i], dtype=np.int)
+
+    amps = trace[amps_i]
+    onsets = onsets_i * dt
+
+    return amps, onsets, crit
+
+if __name__=="__main__":
+    figure()
diff --git a/setup.py b/setup.py
index 61ada2c7..6e4eee79 100644
--- a/setup.py
+++ b/setup.py
@@ -76,8 +76,8 @@ if 'linux' in sys.platform:
 
 
 if os.name == "nt":
-    biosig_define_macros = [('WITH_BIOSIG2', None)]
-    biosig_libraries = ['libbiosig2']
+    biosig_define_macros = [('WITH_BIOSIG', None)]
+    biosig_libraries = ['libbiosig']
     biosig_lite_sources = []
 else:
     biosig_define_macros = [('WITH_BIOSIG2', None), ('WITH_BIOSIGLITE', None), ('WITHOUT_NETWORK', None)]
diff --git a/src/libstfio/Makefile.am b/src/libstfio/Makefile.am
index 2855b49f..8bff71a3 100644
--- a/src/libstfio/Makefile.am
+++ b/src/libstfio/Makefile.am
@@ -27,10 +27,10 @@ libstfio_la_SOURCES =  ./channel.cpp ./section.cpp ./recording.cpp ./stfio.cpp \
 	./abf/axon/AxAbfFio32/msbincvt.cpp \
 	./abf/axon/Common/unix.cpp \
 	./abf/axon/AxAbfFio32/abferror.cpp \
-        ./abf/axon/AxAtfFio32/axatffio32.cpp \
-        ./abf/axon/AxAtfFio32/fileio2.cpp \
-        ./abf/axon2/ProtocolReaderABF2.cpp \
-        ./abf/axon2/SimpleStringCache.cpp \
+	./abf/axon/AxAtfFio32/axatffio32.cpp \
+	./abf/axon/AxAtfFio32/fileio2.cpp \
+	./abf/axon2/ProtocolReaderABF2.cpp \
+	./abf/axon2/SimpleStringCache.cpp \
 	./abf/axon2/abf2headr.cpp \
 	./atf/atflib.cpp \
 	./axg/axglib.cpp \
@@ -38,7 +38,7 @@ libstfio_la_SOURCES =  ./channel.cpp ./section.cpp ./recording.cpp ./stfio.cpp \
 	./axg/fileUtils.cpp \
 	./axg/stringUtils.cpp \
 	./axg/byteswap.cpp \
-        ./heka/hekalib.cpp \
+	./biosig/biosiglib.cpp \
 	./igor/igorlib.cpp \
 	./igor/CrossPlatformFileIO.c \
 	./igor/WriteWave.c \
@@ -46,16 +46,9 @@ libstfio_la_SOURCES =  ./channel.cpp ./section.cpp ./recording.cpp ./stfio.cpp \
 	./intan/intanlib.cpp \
 	./intan/streams.cpp
 
-if WITH_BIOSIG2
-libstfio_la_SOURCES += ./biosig/biosiglib.cpp
-else
-if WITH_BIOSIG
-libstfio_la_SOURCES += ./biosig/biosiglib.cpp
-else
-if WITH_BIOSIGLITE
-libstfio_la_SOURCES += ./biosig/biosiglib.cpp
-endif
-endif
+if !WITH_BIOSIG
+libstfio_la_SOURCES += \
+	./heka/hekalib.cpp
 endif
 
 libstfio_la_LDFLAGS =
diff --git a/src/libstfio/abf/axon/Common/ArrayPtr.hpp b/src/libstfio/abf/axon/Common/ArrayPtr.hpp
index 8584824a..65fecd9b 100755
--- a/src/libstfio/abf/axon/Common/ArrayPtr.hpp
+++ b/src/libstfio/abf/axon/Common/ArrayPtr.hpp
@@ -14,7 +14,11 @@
 
 #pragma once
 #include <stdlib.h> 
-#include <boost/shared_array.hpp>
+#if (__cplusplus < 201402L)
+#  include <boost/shared_array.hpp>
+#else
+#  include <memory>
+#endif
 
 #if defined(__UNIX__) || defined(__STF__)
 	#define max(a,b)   (((a) > (b)) ? (a) : (b))
@@ -29,7 +33,11 @@ template<class ITEM>
 class CArrayPtr
 {
 private:    // Private data.
+#if (__cplusplus <  201402L)
    boost::shared_array<ITEM> m_pArray;
+#else
+   std::shared_ptr<ITEM> m_pArray;
+#endif
 
 private:    // Prevent copy constructors and operator=().
    CArrayPtr(const CArrayPtr &);
diff --git a/src/libstfio/abf/axon/Common/FileReadCache.hpp b/src/libstfio/abf/axon/Common/FileReadCache.hpp
index 86b52ebc..8f3cdadc 100755
--- a/src/libstfio/abf/axon/Common/FileReadCache.hpp
+++ b/src/libstfio/abf/axon/Common/FileReadCache.hpp
@@ -13,7 +13,11 @@
 #define INC_FILEREADCACHE_HPP
 
 #include "./../Common/FileIO.hpp"
-#include <boost/shared_array.hpp>
+#if (__cplusplus < 201402L)
+#  include <boost/shared_array.hpp>
+#else
+#  include <memory>
+#endif
 //-----------------------------------------------------------------------------------------------
 // CFileReadCache class definition
 
@@ -27,7 +31,11 @@ private:
    UINT     m_uCacheSize;
    UINT     m_uCacheStart;
    UINT     m_uCacheCount;
+#if (__cplusplus <  201402L)
    boost::shared_array<BYTE>    m_pItemCache;
+#else
+   std::shared_ptr<BYTE>    m_pItemCache;
+#endif
 
 private:    // Unimplemented default member functions.
    // Declare but don't define copy constructors to prevent use of defaults.
diff --git a/src/libstfio/abf/axon2/ProtocolReaderABF2.hpp b/src/libstfio/abf/axon2/ProtocolReaderABF2.hpp
index 85205cb9..d44a22c8 100644
--- a/src/libstfio/abf/axon2/ProtocolReaderABF2.hpp
+++ b/src/libstfio/abf/axon2/ProtocolReaderABF2.hpp
@@ -16,6 +16,8 @@
 #include "../axon/AxAbfFio32/filedesc.hpp"
 #if (__cplusplus < 201103)
     #include <boost/shared_ptr.hpp>
+#else
+    #include <memory>
 #endif
 
 //===============================================================================================
diff --git a/src/libstfio/biosig/biosiglib.cpp b/src/libstfio/biosig/biosiglib.cpp
index 8092443b..bf125dae 100644
--- a/src/libstfio/biosig/biosiglib.cpp
+++ b/src/libstfio/biosig/biosiglib.cpp
@@ -18,27 +18,15 @@
 
 #include "../stfio.h"
 
-#if defined(WITH_BIOSIG2)
     #if defined(WITH_BIOSIGLITE)
         #include "../../libbiosiglite/biosig4c++/biosig2.h"
     #else
-        #include <biosig2.h>
+        #include <biosig.h>
     #endif
-    #if (BIOSIG_VERSION < 10506)
-        #error libbiosig2 v1.5.6 or later is required
+    #if (BIOSIG_VERSION < 10902)
+        #error libbiosig v1.9.2 or later is required
     #endif
-    #if (BIOSIG_VERSION > 10506)
-        #define DONOTUSE_DYNAMIC_ALLOCATION_FOR_CHANSPR
-    #endif
-#else
-    #include <biosig.h>
-    #if defined(_MSC_VER)
-        //#if (BIOSIG_VERSION < 10507)
-            #error libbiosig is not ABI compatible
-        //#endif
-    #endif
-    #error Loading SectionDescription from Biosig Event Table not yet supported when compiling WITH_BIOSIG, use WITH_BIOSIG2 instead.
-#endif
+    #define DONOTUSE_DYNAMIC_ALLOCATION_FOR_CHANSPR
 
 
   /* these are internal biosig functions, defined in biosig-dev.h which is not always available */
@@ -55,40 +43,23 @@ extern "C" uint32_t lcm(uint32_t A, uint32_t B);
 
 #include "./biosiglib.h"
 
-/* Redefine BIOSIG_VERSION for versions < 1 */
-#if (BIOSIG_VERSION_MAJOR < 1)
-#undef BIOSIG_VERSION
-#ifndef BIOSIG_PATCHLEVEL
-#define BIOSIG_PATCHLEVEL BIOSIG_VERSION_STEPPING
-#endif
-#define BIOSIG_VERSION (BIOSIG_VERSION_MAJOR * 10000 + BIOSIG_VERSION_MINOR * 100 + BIOSIG_PATCHLEVEL)
-#endif
-
 stfio::filetype stfio_file_type(HDRTYPE* hdr) {
-#ifdef __LIBBIOSIG2_H__
         switch (biosig_get_filetype(hdr)) {
-#else
-        switch (hdr->TYPE) {
-#endif
 
-#if (BIOSIG_VERSION > 10500)
         case ABF2:	return stfio::abf;
-#endif
         case ABF:	return stfio::abf;
         case ATF:	return stfio::atf;
         case CFS:	return stfio::cfs;
         case HEKA:	return stfio::heka;
         case HDF:	return stfio::hdf5;
-#if (BIOSIG_VERSION > 10403)
         case AXG:	return stfio::axg;
         case IBW:	return stfio::igor;
         case SMR:	return stfio::son;
-#endif
         default:	return stfio::none;
         }
 }
 
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
 bool stfio::check_biosig_version(int a, int b, int c) {
 	return (BIOSIG_VERSION >= 10000*a + 100*b + c);
 }
@@ -107,13 +78,6 @@ stfio::filetype stfio::importBiosigFile(const std::string &fName, Recording &Ret
     //  - and decides whether the data is imported through importBiosig (currently CFS, HEKA, ABF1, GDF, and others)
     //  - or handed back to other import*File functions (currently ABF2, AXG, HDF5)
     //
-    // There are two implementations, level-1 and level-2 interface of libbiosig.
-    //   level 1 is used when -DWITH_BIOSIG, -lbiosig
-    //   level 2 is used when -DWITH_BIOSIG2, -lbiosig2
-    //
-    //   level 1 is better tested, but it does not provide ABI compatibility between MinGW and VisualStudio
-    //   level 2 interface has been developed to provide ABI compatibility, but it is less tested
-    //      and the API might still undergo major changes.
     // =====================================================================================================================
 
 
@@ -132,17 +96,11 @@ stfio::filetype stfio::importBiosigFile(const std::string &fName, Recording &Ret
         return type;
     }
     enum FileFormat biosig_filetype=biosig_get_filetype(hdr);
-    if (biosig_filetype==ATF || biosig_filetype==ABF2 || biosig_filetype==HDF ) {
-        // ATF, ABF2 and HDF5 support should be handled by importATF, and importABF, and importHDF5 not importBiosig
-        ReturnData.resize(0);
-        destructHDR(hdr);
-        return type;
-    }
-
-    // earlier versions of biosig support only the file type identification, but did not properly read the files
-    if ( (BIOSIG_VERSION < 10603)
-      && (biosig_filetype==AXG)
-       ) {
+    if ( (biosig_filetype==ATF  && get_biosig_version() < 0x030001) \
+      || (biosig_filetype==ABF2 && get_biosig_version() < 0x030001) \
+      ||  biosig_filetype==HDF ) {
+        // ATF, ABF2 HDF5 support should be handled by importATF, and importABF, and importHDF5 not importBiosig
+        // with libbiosig v3.0.1 and later, ATF and ABF2 should be handled by Biosig
         ReturnData.resize(0);
         destructHDR(hdr);
         return type;
@@ -173,11 +131,7 @@ stfio::filetype stfio::importBiosigFile(const std::string &fName, Recording &Ret
         uint16_t typ;
         uint32_t dur;
         uint16_t chn;
-#if BIOSIG_VERSION < 10605
-        char *desc;
-#else
         const char *desc;
-#endif
         /*
         gdftype  timestamp;
         */
@@ -293,11 +247,9 @@ stfio::filetype stfio::importBiosigFile(const std::string &fName, Recording &Ret
 
     ReturnData.SetFileDescription(Desc);
 
-#if (BIOSIG_VERSION > 10509)
     tmpstr = biosig_get_application_specific_information(hdr);
     if (tmpstr != NULL) /* MSVC2008 can not properly handle std::string( (char*)NULL ) */
         ReturnData.SetGlobalSectionDescription(tmpstr);
-#endif
 
     ReturnData.SetXScale(1000.0/biosig_get_samplerate(hdr));
     ReturnData.SetXUnits("ms");
@@ -313,262 +265,7 @@ stfio::filetype stfio::importBiosigFile(const std::string &fName, Recording &Ret
     destructHDR(hdr);
 
 
-#else  // #ifndef __LIBBIOSIG2_H__
-
-
-    HDRTYPE* hdr =  sopen( fName.c_str(), "r", NULL );
-    if (hdr==NULL) {
-        ReturnData.resize(0);
-        return stfio::none;
-    }
-    type = stfio_file_type(hdr);
-
-#if !defined(BIOSIG_VERSION) || (BIOSIG_VERSION < 10501)
-    if (hdr->TYPE==ABF) {
-        /*
-           biosig v1.5.0 and earlier does not always return
-           with a proper error message for ABF files.
-           This causes problems with the ABF fallback mechanism
-        */
-#else
-    if ( hdr->TYPE==ABF2 ) {
-        // ABF2 support should be handled by importABF not importBiosig
-        ReturnData.resize(0);
-        destructHDR(hdr);
-        return type;
-    }
-    if (hdr->TYPE==ABF && hdr->AS.B4C_ERRNUM) {
-        /* this triggers the fall back mechanims w/o reporting an error message */
-#endif
-        ReturnData.resize(0);
-        destructHDR(hdr);	// free allocated memory
-        return type;
-    }
-
-#if defined(BIOSIG_VERSION) && (BIOSIG_VERSION > 10400)
-    if (hdr->AS.B4C_ERRNUM) {
-#else
-    if (B4C_ERRNUM) {
-#endif
-        ReturnData.resize(0);
-        destructHDR(hdr);	// free allocated memory
-        return type;
-    }
-    if ( hdr->TYPE==ATF || hdr->TYPE==HDF) {
-        // ATF, HDF5 support should be handled by importATF and importHDF5 not importBiosig
-        ReturnData.resize(0);
-        destructHDR(hdr);
-        return type;
-    }
-
-    // earlier versions of biosig support only the file type identification, but did not read AXG files
-#if defined(BIOSIG_VERSION) && (BIOSIG_VERSION > 10403)
-    if ( (BIOSIG_VERSION < 10600)
-         && (hdr->TYPE==AXG)
-       ) {
-        // biosig's AXG import crashes on Windows at this time
-        ReturnData.resize(0);
-        destructHDR(hdr);
-        return type;
-    }
-#endif
-    
-    // ensure the event table is in chronological order
-    sort_eventtable(hdr);
-
-    // allocate local memory for intermediate results;
-    const int strSize=100;
-    char str[strSize];
-
-    /*
-	count sections and generate list of indices indicating start and end of sweeps
-     */
-    size_t numberOfEvents = hdr->EVENT.N;
-    size_t LenIndexList = 256;
-    if (LenIndexList > numberOfEvents) LenIndexList = numberOfEvents + 2;
-    size_t *SegIndexList = (size_t*)malloc(LenIndexList*sizeof(size_t));
-    uint32_t nsections = 0;
-    SegIndexList[nsections] = 0;
-    size_t MaxSectionLength = 0;
-    for (size_t k=0; k <= numberOfEvents; k++) {
-        if (LenIndexList <= nsections+2) {
-            // allocate more memory as needed
-		    LenIndexList *=2;
-		    SegIndexList = (size_t*)realloc(SegIndexList, LenIndexList*sizeof(size_t));
-	    }
-        /*
-            count number of sections and stores it in nsections;
-            EVENT.TYP==0x7ffe indicate number of breaks between sweeps
-	        SegIndexList includes index to first sample and index to last sample,
-	        thus, the effective length of SegIndexList is the number of 0x7ffe plus two.
-	    */
-        if (0)                              ;
-        else if (k >= hdr->EVENT.N)         SegIndexList[++nsections] = hdr->NRec*hdr->SPR;
-        else if (hdr->EVENT.TYP[k]==0x7ffe) SegIndexList[++nsections] = hdr->EVENT.POS[k];
-        else                                continue;
-
-        size_t SPS = SegIndexList[nsections]-SegIndexList[nsections-1];	// length of segment, samples per segment
-	    if (MaxSectionLength < SPS) MaxSectionLength = SPS;
-    }
-
-    int numberOfChannels = 0;
-    for (int k=0; k < hdr->NS; k++)
-        if (hdr->CHANNEL[k].OnOff==1)
-            numberOfChannels++;
-
-    /*************************************************************************
-        rescale data to mV and pA
-     *************************************************************************/    
-    for (int ch=0; ch < hdr->NS; ++ch) {
-        CHANNEL_TYPE *hc = hdr->CHANNEL+ch;
-        if (hc->OnOff != 1) continue;
-        double scale = PhysDimScale(hc->PhysDimCode); 
-        switch (hc->PhysDimCode & 0xffe0) {
-        case 4256:  // Volt
-                hc->PhysDimCode = 4274; // = PhysDimCode("mV");
-                scale *=1e3;   // V->mV
-                hc->PhysMax *= scale;         
-                hc->PhysMin *= scale;         
-                hc->Cal *= scale;         
-                hc->Off *= scale;         
-                break; 
-        case 4160:  // Ampere
-                hc->PhysDimCode = 4181; // = PhysDimCode("pA");
-                scale *=1e12;   // A->pA
-                hc->PhysMax *= scale;         
-                hc->PhysMin *= scale;         
-                hc->Cal *= scale;         
-                hc->Off *= scale;         
-                break; 
-        }     
-    }
-
-    /*************************************************************************
-        read bulk data 
-     *************************************************************************/    
-    hdr->FLAG.ROW_BASED_CHANNELS = 0;
-    /* size_t blks = */ sread(NULL, 0, hdr->NRec, hdr);
-    biosig_data_type *data = hdr->data.block;
-    size_t SPR = hdr->NRec*hdr->SPR;
-
-#ifdef _STFDEBUG
-    std::cout << "Number of events: " << numberOfEvents << std::endl;
-    /*int res = */ hdr2ascii(hdr, stdout, 4);
-#endif
-
-    int NS = 0;   // number of non-empty channels
-    for (size_t nc=0; nc < hdr->NS; ++nc) {
-
-        if (hdr->CHANNEL[nc].OnOff == 0) continue;
-
-        Channel TempChannel(nsections);
-        TempChannel.SetChannelName(hdr->CHANNEL[nc].Label);
-#if defined(BIOSIG_VERSION) && (BIOSIG_VERSION > 10301)
-        TempChannel.SetYUnits(PhysDim3(hdr->CHANNEL[nc].PhysDimCode));
-#else
-        PhysDim(hdr->CHANNEL[nc].PhysDimCode,str);
-        TempChannel.SetYUnits(str);
-#endif
-
-        for (size_t ns=1; ns<=nsections; ns++) {
-	        size_t SPS = SegIndexList[ns]-SegIndexList[ns-1];	// length of segment, samples per segment
-
-		int progbar = 100.0*(1.0*ns/nsections + NS)/numberOfChannels;
-		std::ostringstream progStr;
-		progStr << "Reading channel #" << NS + 1 << " of " << numberOfChannels
-			<< ", Section #" << ns << " of " << nsections;
-		progDlg.Update(progbar, progStr.str());
-
-		/* unused //
-		char sweepname[20];
-		sprintf(sweepname,"sweep %i",(int)ns);		
-		*/
-		Section TempSection(
-                                SPS, // TODO: hdr->nsamplingpoints[nc][ns]
-                                "" // TODO: hdr->sectionname[nc][ns]
-            	);
-
-		std::copy(&(data[NS*SPR + SegIndexList[ns-1]]),
-			  &(data[NS*SPR + SegIndexList[ns]]),
-			  TempSection.get_w().begin() );
-
-        try {
-            TempChannel.InsertSection(TempSection, ns-1);
-        }
-        catch (...) {
-			ReturnData.resize(0);
-			destructHDR(hdr);
-			return type;
-		}
-	}        
-    try {
-        if ((int)ReturnData.size() < numberOfChannels) {
-            ReturnData.resize(numberOfChannels);
-        }
-        ReturnData.InsertChannel(TempChannel, NS++);
-    }
-    catch (...) {
-		ReturnData.resize(0);
-		destructHDR(hdr);
-		return type;
-        }
-    }
-
-    free(SegIndexList); 	
-
-    ReturnData.SetComment ( hdr->ID.Recording );
-
-    sprintf(str,"v%i.%i.%i (compiled on %s %s)",BIOSIG_VERSION_MAJOR,BIOSIG_VERSION_MINOR,BIOSIG_PATCHLEVEL,__DATE__,__TIME__);
-    std::string Desc = std::string("importBiosig with libbiosig ")+std::string(str);
-
-    if (hdr->ID.Technician)
-            Desc += std::string ("\nTechnician:\t") + std::string (hdr->ID.Technician);
-    Desc += std::string( "\nCreated with: ");
-    if (hdr->ID.Manufacturer.Name)
-        Desc += std::string( hdr->ID.Manufacturer.Name );
-    if (hdr->ID.Manufacturer.Model)
-        Desc += std::string( hdr->ID.Manufacturer.Model );
-    if (hdr->ID.Manufacturer.Version)
-        Desc += std::string( hdr->ID.Manufacturer.Version );
-    if (hdr->ID.Manufacturer.SerialNumber)
-        Desc += std::string( hdr->ID.Manufacturer.SerialNumber );
-
-    Desc += std::string ("\nUser specified Annotations:\n");
-    for (size_t k=0; k < numberOfEvents; k++) {
-        if (hdr->EVENT.TYP[k] < 256) {
-            sprintf(str,"%f s\t",hdr->EVENT.POS[k]/hdr->EVENT.SampleRate);
-            Desc += std::string( str );
-            if (hdr->EVENT.CodeDesc != NULL)
-                Desc += std::string( hdr->EVENT.CodeDesc[hdr->EVENT.TYP[k]] );
-            Desc += "\n";
-        }
-    }
-    ReturnData.SetFileDescription(Desc);
-    // hdr->AS.bci2000 is an alias to hdr->AS.fpulse, which available only in libbiosig v1.6.0 or later
-
-    if (hdr->AS.bci2000) ReturnData.SetGlobalSectionDescription(std::string(hdr->AS.bci2000));
-
-    ReturnData.SetXScale(1000.0/hdr->SampleRate);
-    ReturnData.SetXUnits("ms");
-    ReturnData.SetScaling("biosig scaling factor");
-
-    /*************************************************************************
-        Date and time conversion
-     *************************************************************************/
-    struct tm T;
-#if (BIOSIG_VERSION_MAJOR > 0)
-    gdf_time2tm_time_r(hdr->T0, &T);
-#else
-    struct tm* Tp;
-    Tp = gdf_time2tm_time(hdr->T0);
-    T = *Tp;
-#endif
-
-    ReturnData.SetDateTime(T);
-
-    destructHDR(hdr);
-
-#endif
+#endif	//ifdef __LIBBIOSIG2_H__
     return stfio::biosig;
 }
 
@@ -577,9 +274,6 @@ stfio::filetype stfio::importBiosigFile(const std::string &fName, Recording &Ret
     //
     // Save file with libbiosig into GDF format
     //
-    // There basically two implementations, one with libbiosig before v1.6.0 and
-    // and one for libbiosig v1.6.0 and later
-    //
     // =====================================================================================================================
 
 bool stfio::exportBiosigFile(const std::string& fName, const Recording& Data, stfio::ProgressInfo& progDlg) {
@@ -612,11 +306,7 @@ bool stfio::exportBiosigFile(const std::string& fName, const Recording& Data, st
     double fs = 1.0/(PhysDimScale(pdc) * Data.GetXScale());
     biosig_set_samplerate(hdr, fs);
 
-#if (BIOSIG_VERSION < 10700)
-    biosig_set_flags(hdr, 0, 0, 0);
-#else
     biosig_reset_flag(hdr, BIOSIG_FLAG_COMPRESSION | BIOSIG_FLAG_UCAL | BIOSIG_FLAG_OVERFLOWDETECTION | BIOSIG_FLAG_ROW_BASED_CHANNELS );
-#endif
 
     size_t k, m, numberOfEvents=0;
     size_t NRec=0;	// corresponds to hdr->NRec
@@ -812,230 +502,7 @@ bool stfio::exportBiosigFile(const std::string& fName, const Recording& Data, st
     destructHDR(hdr);
     free(rawdata);
 
-
-#else   // #ifndef __LIBBIOSIG2_H__
-
-
-    HDRTYPE* hdr = constructHDR(Data.size(), 0);
-    assert(hdr->NS == Data.size());
-
-	/* Initialize all header parameters */
-    hdr->TYPE = GDF;
-#if (BIOSIG_VERSION >= 10508)
-    /* transition in biosig to rename HDR->VERSION to HDR->Version
-       to avoid name space conflict with macro VERSION
-     */
-    hdr->Version = 3.0;   // select latest supported version of GDF format
-#else
-    hdr->VERSION = 3.0;   // select latest supported version of GDF format
-#endif
-
-    struct tm t = Data.GetDateTime();
-
-    hdr->T0 = tm_time2gdf_time(&t);
-
-    const char *xunits = Data.GetXUnits().c_str();
-#if (BIOSIG_VERSION_MAJOR > 0)
-    uint16_t pdc = PhysDimCode(xunits);
-#else
-    uint16_t pdc = PhysDimCode((char*)xunits);
-#endif
-    if ((pdc & 0xffe0) == PhysDimCode("s")) {
-        fprintf(stderr,"Stimfit exportBiosigFile: xunits [%s] has not proper units, assume [ms]\n",Data.GetXUnits().c_str());
-        pdc = PhysDimCode("ms");
-    }
-    hdr->SampleRate = 1.0/(PhysDimScale(pdc) * Data.GetXScale());
-    hdr->SPR  = 1;
-
-    hdr->FLAG.UCAL = 0;
-    hdr->FLAG.OVERFLOWDETECTION = 0;
-
-    hdr->FILE.COMPRESSION = 0;
-
-	/* Initialize all channel parameters */
-    size_t k, m;
-    for (k = 0; k < hdr->NS; ++k) {
-        CHANNEL_TYPE *hc = hdr->CHANNEL+k;
-
-        hc->PhysMin = -1e9;
-        hc->PhysMax =  1e9;
-        hc->DigMin  = -1e9;
-        hc->DigMax  =  1e9;
-        hc->Cal     =  1.0;
-        hc->Off     =  0.0;
-
-        /* Channel descriptions. */
-        strncpy(hc->Label, Data[k].GetChannelName().c_str(), MAX_LENGTH_LABEL);
-#if (BIOSIG_VERSION_MAJOR > 0)
-        hc->PhysDimCode = PhysDimCode(Data[k].GetYUnits().c_str());
-#else
-        hc->PhysDimCode = PhysDimCode((char*)Data[k].GetYUnits().c_str());
 #endif
-        hc->OnOff      = 1;
-        hc->LeadIdCode = 0;
-
-        hc->TOffset  = 0.0;
-        hc->Notch    = NAN;
-        hc->LowPass  = NAN;
-        hc->HighPass = NAN;
-        hc->Impedance= NAN;
-
-        hc->SPR    = hdr->SPR;
-        hc->GDFTYP = 17; 	// double
-
-        // each segment gets one marker, roughly
-        hdr->EVENT.N += Data[k].size();
-
-        size_t m,len = 0;
-        for (len=0, m = 0; m < Data[k].size(); ++m) {
-            unsigned div = lround(Data[k][m].GetXScale()/Data.GetXScale());
-            hc->SPR = lcm(hc->SPR,div);  // sampling interval of m-th segment in k-th channel
-            len += div*Data[k][m].size();
-        }
-        hdr->SPR = lcm(hdr->SPR, hc->SPR);
-
-        if (k==0) {
-            hdr->NRec = len;
-        }
-        else if ((size_t)hdr->NRec != len) {
-            destructHDR(hdr);
-            throw std::runtime_error("File can't be exported:\n"
-                "No data or traces have different sizes" );
-
-            return false;
-        }
-    }
-
-    hdr->AS.bpb = 0;
-    for (k = 0; k < hdr->NS; ++k) {
-        CHANNEL_TYPE *hc = hdr->CHANNEL+k;
-        hc->SPR = hdr->SPR / hc->SPR;
-        hc->bi  = hdr->AS.bpb;
-        hdr->AS.bpb += hc->SPR * 8; /* its always double */
-    }
-
-	/***
-	    build Event table for storing segment information
-	 ***/
-	size_t N = hdr->EVENT.N * 2;    // about two events per segment
-	hdr->EVENT.POS = (uint32_t*)realloc(hdr->EVENT.POS, N * sizeof(*hdr->EVENT.POS));
-	hdr->EVENT.DUR = (uint32_t*)realloc(hdr->EVENT.DUR, N * sizeof(*hdr->EVENT.DUR));
-	hdr->EVENT.TYP = (uint16_t*)realloc(hdr->EVENT.TYP, N * sizeof(*hdr->EVENT.TYP));
-	hdr->EVENT.CHN = (uint16_t*)realloc(hdr->EVENT.CHN, N * sizeof(*hdr->EVENT.CHN));
-#if (BIOSIG_VERSION >= 10500)
-	hdr->EVENT.TimeStamp = (gdf_time*)realloc(hdr->EVENT.TimeStamp, N * sizeof(gdf_time));
-#endif
-
-    /* check whether all segments have same size */
-    {
-        char flag = (hdr->NS>0);
-        size_t m, POS, pos;
-        for (k=0; k < hdr->NS; ++k) {
-            pos = Data[k].size();
-            if (k==0)
-                POS = pos;
-            else
-                flag &= (POS == pos);
-        }
-        for (m=0; flag && (m < Data[(size_t)0].size()); ++m) {
-            for (k=0; k < hdr->NS; ++k) {
-                pos = Data[k][m].size() * lround(Data[k][m].GetXScale()/Data.GetXScale());
-                if (k==0)
-                    POS = pos;
-                else
-                    flag &= (POS == pos);
-            }
-        }
-        if (!flag) {
-            destructHDR(hdr);
-            throw std::runtime_error(
-                    "File can't be exported:\n"
-                    "Traces have different sizes or no channels found"
-            );
-            return false;
-        }
-    }
-
-        N=0;
-        k=0;
-        size_t pos = 0;
-        for (m=0; m < (Data[k].size()); ++m) {
-            if (pos > 0) {
-                // start of new segment after break
-                hdr->EVENT.POS[N] = pos;
-                hdr->EVENT.TYP[N] = 0x7ffe;
-                hdr->EVENT.CHN[N] = 0;
-                hdr->EVENT.DUR[N] = 0;
-                N++;
-            }
-#if 0
-            // event description
-            hdr->EVENT.POS[N] = pos;
-            FreeTextEvent(hdr, N, "myevent");
-            //FreeTextEvent(hdr, N, Data[k][m].GetSectionDescription().c_str()); // TODO
-            hdr->EVENT.CHN[N] = k;
-            hdr->EVENT.DUR[N] = 0;
-            N++;
-#endif
-            pos += Data[k][m].size() * lround(Data[k][m].GetXScale()/Data.GetXScale());
-        }
-
-        hdr->EVENT.N = N;
-        hdr->EVENT.SampleRate = hdr->SampleRate;
-
-        sort_eventtable(hdr);
-
-	/* convert data into GDF rawdata from  */
-	hdr->AS.rawdata = (uint8_t*)realloc(hdr->AS.rawdata, hdr->AS.bpb*hdr->NRec);
-	for (k=0; k < hdr->NS; ++k) {
-        CHANNEL_TYPE *hc = hdr->CHANNEL+k;
-
-        size_t m,n,len=0;
-        for (m=0; m < Data[k].size(); ++m) {
-            size_t div = lround(Data[k][m].GetXScale()/Data.GetXScale());
-            size_t div2 = hdr->SPR/div;
-
-            // fprintf(stdout,"k,m,div,div2: %i,%i,%i,%i\n",(int)k,(int)m,(int)div,(int)div2);  //
-            for (n=0; n < Data[k][m].size(); ++n) {
-                uint64_t val;
-                double d = Data[k][m][n];
-#if !defined(__MINGW32__) && !defined(_MSC_VER) && !defined(__APPLE__)
-                val = htole64(*(uint64_t*)&d);
-#else
-                val = *(uint64_t*)&d;
-#endif
-                size_t p, spr = (len + n*div) / hdr->SPR;
-                for (p=0; p < div2; p++)
-                   *(uint64_t*)(hdr->AS.rawdata + hc->bi + hdr->AS.bpb * spr + p*8) = val;
-            }
-            len += div*Data[k][m].size();
-        }
-    }
-
-    /******************************
-        write to file
-    *******************************/
-    std::string errorMsg("Exception while calling std::exportBiosigFile():\n");
-
-    hdr = sopen( fName.c_str(), "w", hdr );
-#if (BIOSIG_VERSION > 10400)
-    if (serror2(hdr)) {
-        errorMsg += hdr->AS.B4C_ERRMSG;
-#else
-    if (serror()) {
-	    errorMsg += B4C_ERRMSG;
-#endif
-        destructHDR(hdr);
-        throw std::runtime_error(errorMsg.c_str());
-        return false;
-    }
-
-    ifwrite(hdr->AS.rawdata, hdr->AS.bpb, hdr->NRec, hdr);
-
-    sclose(hdr);
-    destructHDR(hdr);
-#endif
-
     return true;
 }
 
diff --git a/src/libstfio/biosig/biosiglib.h b/src/libstfio/biosig/biosiglib.h
index e4d6077a..7cf3108a 100644
--- a/src/libstfio/biosig/biosiglib.h
+++ b/src/libstfio/biosig/biosiglib.h
@@ -39,7 +39,7 @@
 
 namespace stfio {
 
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
 //! return version of libbiosig e.g. 10403 correspond to version 1.4.3
 StfioDll bool check_biosig_version(int a, int b, int c);
 #endif
diff --git a/src/libstfio/heka/hekalib.cpp b/src/libstfio/heka/hekalib.cpp
index a715fe25..180f4140 100644
--- a/src/libstfio/heka/hekalib.cpp
+++ b/src/libstfio/heka/hekalib.cpp
@@ -408,8 +408,8 @@ void printHeader(const BundleHeader& header) {
 
 void ByteSwap(unsigned char * b, int n)
 {
-    register int i = 0;
-    register int j = n-1;
+    int i = 0;
+    int j = n-1;
     while (i<j)
     {
         std::swap(b[i], b[j]);
diff --git a/src/libstfio/stfio.cpp b/src/libstfio/stfio.cpp
index 6482dbae..8ac35d8e 100644
--- a/src/libstfio/stfio.cpp
+++ b/src/libstfio/stfio.cpp
@@ -34,21 +34,13 @@
 #include "./atf/atflib.h"
 #include "./axg/axglib.h"
 #include "./igor/igorlib.h"
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if (defined(WITH_BIOSIG))
   #include "./biosig/biosiglib.h"
+#else
+  #include "./heka/hekalib.h"
 #endif
 #include "./cfs/cfslib.h"
 #include "./intan/intanlib.h"
-#ifndef TEST_MINIMAL
-  #include "./heka/hekalib.h"
-#else
-  #if (!defined(WITH_BIOSIG) && !defined(WITH_BIOSIG2))
-    #error -DTEST_MINIMAL requires -DWITH_BIOSIG or -DWITH_BIOSIG2
-  #endif
-#endif
-#if 0
-#include "./son/sonlib.h"
-#endif
 
 #ifdef _MSC_VER
     StfioDll long int lround(double x) {
@@ -97,12 +89,8 @@ stfio::findType(const std::string& ext) {
     else if (ext=="*.smr") return stfio::son;
     else if (ext=="*.tdms") return stfio::tdms;
     else if (ext=="*.clp") return stfio::intan;
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
-#  if (BIOSIG_VERSION < 10800)
-    else if (ext=="*.dat;*.cfs;*.gdf;*.ibw") return stfio::biosig;
-#  else
+#if defined(WITH_BIOSIG)
     else if (ext=="*.dat;*.cfs;*.gdf;*.ibw;*.wcp") return stfio::biosig;
-#  endif
     else if (ext=="*.*")   return stfio::biosig;
 #endif
     else return stfio::none;
@@ -133,7 +121,7 @@ stfio::findExtension(stfio::filetype ftype) {
          return ".tdms";
      case stfio::intan:
          return ".clp";
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
      case stfio::biosig:
          return ".gdf";
 #endif
@@ -151,25 +139,9 @@ bool stfio::importFile(
 ) {
     try {
 
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
        // make use of automated file type identification
 
-#ifndef WITHOUT_ABF
-        if (!check_biosig_version(1,6,3)) {
-            try {
-                // workaround for older versions of libbiosig
-                stfio::importABFFile(fName, ReturnData, progDlg);
-                return true;
-            }
-            catch (...) {
-#ifndef NDEBUG
-                fprintf(stdout,"%s (line %i): importABF attempted\n",__FILE__,__LINE__);
-#endif
-            };
-       }
-#endif // WITHOUT_ABF
-
-       // if this point is reached, import ABF was not applied or not successful
         try {
             stfio::filetype type1 = stfio::importBiosigFile(fName, ReturnData, progDlg);
             switch (type1) {
@@ -192,7 +164,6 @@ bool stfio::importFile(
             stfio::importHDF5File(fName, ReturnData, progDlg);
             break;
         }
-#ifndef WITHOUT_ABF
         case stfio::abf: {
             stfio::importABFFile(fName, ReturnData, progDlg);
             break;
@@ -201,69 +172,22 @@ bool stfio::importFile(
             stfio::importATFFile(fName, ReturnData, progDlg);
             break;
         }
-#endif
-#ifndef WITHOUT_AXG
         case stfio::axg: {
             stfio::importAXGFile(fName, ReturnData, progDlg);
             break;
         }
-#endif
         case stfio::intan: {
             stfio::importIntanFile(fName, ReturnData, progDlg);
             break;
         }
-
-#ifndef TEST_MINIMAL
         case stfio::cfs: {
-            {
             int res = stfio::importCFSFile(fName, ReturnData, progDlg);
-         /*
-            // disable old Heka import - its broken and will not be fixed, use biosig instead
-            if (res==-7) {
-                stfio::importHEKAFile(fName, ReturnData, progDlg);
-            }
-         */
-          break;
-            }
-        }
-        /*
-	// disable old Heka import - its broken and will not be fixed, use biosig instead
-        case stfio::heka: {
-            {
-                try {
-                    stfio::importHEKAFile(fName, ReturnData, progDlg);
-                } catch (const std::runtime_error& e) {
-                    stfio::importCFSFile(fName, ReturnData, progDlg);
-                }
-                break;
-            }
-        }
-        */
-#endif // TEST_MINIMAL
-
+            break;
+           }
         default:
             throw std::runtime_error("Unknown or unsupported file type");
 	}
 
-#if 0
-        case stfio::son: {
-            stfio::SON::importSONFile(fName,ReturnData);
-            break;
-        }
-        case stfio::ascii: {
-            stfio::importASCIIFile( fName, txtImport.hLines, txtImport.ncolumns,
-                    txtImport.firstIsTime, txtImport.toSection, ReturnData );
-            if (!txtImport.firstIsTime) {
-                ReturnData.SetXScale(1.0/txtImport.sr);
-            }
-            if (ReturnData.size()>0)
-                ReturnData[0].SetYUnits(txtImport.yUnits);
-            if (ReturnData.size()>1)
-                ReturnData[1].SetYUnits(txtImport.yUnitsCh2);
-            ReturnData.SetXUnits(txtImport.xUnits);
-            break;
-        }
-#endif
     }
     catch (...) {
         throw;
@@ -276,13 +200,11 @@ bool stfio::exportFile(const std::string& fName, stfio::filetype type, const Rec
 {
     try {
         switch (type) {
-#ifndef WITHOUT_ABF
         case stfio::atf: {
             stfio::exportATFFile(fName, Data);
             break;
         }
-#endif
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
         case stfio::biosig: {
             stfio::exportBiosigFile(fName, Data, progDlg);
             break;
diff --git a/src/libstfio/stfio.h b/src/libstfio/stfio.h
index 4b5aaa70..64bd2cf0 100644
--- a/src/libstfio/stfio.h
+++ b/src/libstfio/stfio.h
@@ -25,7 +25,12 @@
 #define _STFIO_H_
 
 #include <iostream>
-#include <boost/function.hpp>
+#if (__cplusplus < 201103)
+#  include <boost/function.hpp>
+#else
+#  include <algorithm>
+#  include <functional>
+#endif
 #include <vector>
 #include <deque>
 #include <map>
diff --git a/src/libstfnum/fit.cpp b/src/libstfnum/fit.cpp
index a2d4e119..0e89a96c 100755
--- a/src/libstfnum/fit.cpp
+++ b/src/libstfnum/fit.cpp
@@ -191,7 +191,7 @@ double stfnum::lmFit( const Vector_double& data, double dt,
             constrains_lm_ub[n_p] = DBL_MAX;
         }
         if ( can_scale ) {
-            if (fitFunc.pInfo[n_p].scale == stfnum::noscale) {
+            if (!fitFunc.pInfo[n_p].scale) {
                 can_scale = false;
             }
         }
diff --git a/src/libstfnum/funclib.cpp b/src/libstfnum/funclib.cpp
index 7757c2eb..d5a817df 100755
--- a/src/libstfnum/funclib.cpp
+++ b/src/libstfnum/funclib.cpp
@@ -159,11 +159,11 @@ void stfnum::fexp_init(const Vector_double& data, double base, double peak, doub
     Vector_double peeled( stfio::vec_scal_minus(data, floor));
     if (increasing) peeled = stfio::vec_scal_mul(peeled, -1.0);
     std::transform(peeled.begin(), peeled.end(), peeled.begin(),
-#if defined(_WINDOWS) && !defined(__MINGW32__)                      
+#if defined(_MSC_VER)
                    std::logl);
-#elif defined(__APPLE__)
+#elif defined(__clang__)
                    std::logl);
-#else
+#else	// defined(__GNUC__)  // all gcc-based compilers including mingw
                    log);
 #endif
 
diff --git a/src/libstfnum/stfnum.h b/src/libstfnum/stfnum.h
index 3ac112ba..9225cb65 100755
--- a/src/libstfnum/stfnum.h
+++ b/src/libstfnum/stfnum.h
@@ -33,7 +33,15 @@
 #include <vector>
 #include <complex>
 #include <deque>
-#include <boost/function.hpp>
+
+#if (__cplusplus < 201103)
+#  include <boost/function.hpp>
+#else
+#  include <algorithm>
+#  include <cassert>
+#  include <functional>
+#endif
+
 #ifdef _OPENMP
 #include <omp.h>
 #endif
@@ -42,8 +50,8 @@
 #ifdef _MSC_VER
 #define INFINITY (DBL_MAX+DBL_MAX)
 #ifndef NAN
-        static const unsigned long __nan[2] = {0xffffffff, 0x7fffffff};
-        #define NAN (*(const float *) __nan)
+        static const unsigned long __nan[2] = {0xffffffff, 0x7fffffff};
+        #define NAN (*(const float *) __nan)
 #endif
 #endif
 
@@ -61,6 +69,8 @@ namespace stfnum {
  *  that takes a double (the x-value) and a vector of parameters and returns 
  *  the function's result (the y-value).
  */
+#if (__cplusplus < 201103)
+
 typedef boost::function<double(double, const Vector_double&)> Func;
 
 //! The jacobian of a stfnum::Func.
@@ -69,6 +79,17 @@ typedef boost::function<Vector_double(double, const Vector_double&)> Jac;
 //! Scaling function for fit parameters
 typedef boost::function<double(double, double, double, double, double)> Scale;
 
+#else
+
+typedef std::function<double(double, const Vector_double&)> Func;
+
+//! The jacobian of a stfnum::Func.
+typedef std::function<Vector_double(double, const Vector_double&)> Jac;
+
+//! Scaling function for fit parameters
+typedef std::function<double(double, double, double, double, double)> Scale;
+
+#endif
 //! Dummy function, serves as a placeholder to initialize functions without a Jacobian.
 Vector_double nojac( double x, const Vector_double& p);
 
@@ -203,16 +224,29 @@ private:
     std::vector< std::string > colLabels;
 };
 
+#if (__cplusplus < 201103)
 //! Print the output of a fit into a stfnum::Table.
 typedef boost::function<Table(const Vector_double&,const std::vector<stfnum::parInfo>,double)> Output;
  
 //! Default fit output function, constructing a stfnum::Table from the parameters, their description and chisqr.
-Table defaultOutput(const Vector_double& pars, 
+Table defaultOutput(const Vector_double& pars,
                     const std::vector<parInfo>& parsInfo,
                     double chisqr);
 
 //! Initialising function for the parameters in stfnum::Func to start a fit.
 typedef boost::function<void(const Vector_double&, double, double, double, double, double, Vector_double&)> Init;
+#else
+//! Print the output of a fit into a stfnum::Table.
+typedef std::function<Table(const Vector_double&,const std::vector<stfnum::parInfo>,double)> Output;
+
+//! Default fit output function, constructing a stfnum::Table from the parameters, their description and chisqr.
+Table defaultOutput(const Vector_double& pars,
+                    const std::vector<parInfo>& parsInfo,
+                    double chisqr);
+
+//! Initialising function for the parameters in stfnum::Func to start a fit.
+typedef std::function<void(const Vector_double&, double, double, double, double, double, Vector_double&)> Init;
+#endif
 
 //! Function used for least-squares fitting.
 /*! Objects of this class are used for fitting functions 
diff --git a/src/pystfio/pystfio.cxx b/src/pystfio/pystfio.cxx
index 47fd60a6..337a2848 100755
--- a/src/pystfio/pystfio.cxx
+++ b/src/pystfio/pystfio.cxx
@@ -76,6 +76,8 @@ stfio::filetype gettype(const std::string& ftype) {
         stftype = stfio::igor;
     } else if (ftype == "tdms") {
         stftype = stfio::tdms;
+    } else if (ftype == "intan") {
+        stftype = stfio::intan;
     } else {
         stftype = stfio::none;
     }
diff --git a/src/pystfio/pystfio.i b/src/pystfio/pystfio.i
index 2edc5e5d..7a9bdae9 100644
--- a/src/pystfio/pystfio.i
+++ b/src/pystfio/pystfio.i
@@ -431,7 +431,8 @@ filetype = {
     '.abf':'abf',
     '.atf':'atf',
     '.axgd':'axg',
-    '.axgx':'axg'}
+    '.axgx':'axg',
+    '.clp':'intan'}
 
 def read(fname, ftype=None, verbose=False):
     """Reads a file and returns a Recording object.
@@ -446,6 +447,7 @@ def read(fname, ftype=None, verbose=False):
               "atf"  - Axon text file
               "axg"  - Axograph X binary file
               "heka" - HEKA binary file
+              "intan" - INTAN clamp binary file
               if ftype is None (default), it will be guessed from the
               extension.
 #else
diff --git a/src/pystfio/stfio_plot.py b/src/pystfio/stfio_plot.py
index 56c3c6f9..af62efca 100644
--- a/src/pystfio/stfio_plot.py
+++ b/src/pystfio/stfio_plot.py
@@ -19,7 +19,10 @@ HAS_MPL = True
 try:
     import matplotlib
     import matplotlib.pyplot as plt
-    from mpl_toolkits.axes_grid.axislines import Subplot
+    if (float(matplotlib.__version__[0:3]) > 2.1):
+        from mpl_toolkits.axisartist import Subplot
+    else:
+        from mpl_toolkits.axes_grid.axislines import Subplot
 except ImportError as err:
     HAS_MPL = False
     MPL_ERR = err
diff --git a/src/stimfit/Makefile.am b/src/stimfit/Makefile.am
index fe01e894..8bc458de 100755
--- a/src/stimfit/Makefile.am
+++ b/src/stimfit/Makefile.am
@@ -17,7 +17,7 @@ endif
 
 # the application source, library search path, and link libraries
 if BUILD_PYTHON
-    PYTHON_ADDINCLUDES = $(LIBNUMPY_INCLUDES) $(LIBPYTHON_INCLUDES)
+    PYTHON_ADDINCLUDES = $(LIBNUMPY_INCLUDES) $(LIBPYTHON_INCLUDES) $(LIBWXPYTHON_INCLUDES)
 else
     PYTHON_ADDINCLUDES = 
 endif
diff --git a/src/stimfit/gui/app.cpp b/src/stimfit/gui/app.cpp
index 719f171d..fd90d90c 100755
--- a/src/stimfit/gui/app.cpp
+++ b/src/stimfit/gui/app.cpp
@@ -162,19 +162,15 @@ bool wxStfApp::OnInit(void)
     //// Create a document manager
     wxDocManager* docManager = new wxDocManager;
     //// Create a template relating drawing documents to their views
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
     m_biosigTemplate=new wxDocTemplate( docManager,
                                      wxT("All files"), wxT("*.*"), wxT(""), wxT(""),
                                      wxT("Biosig Document"), wxT("Biosig View"), CLASSINFO(wxStfDoc),
                                      CLASSINFO(wxStfView) );
 #endif
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
     m_biosigTemplate=new wxDocTemplate( docManager,
-#   if (BIOSIG_VERSION < 10800)
-                                     wxT("Biosig files"), wxT("*.dat;*.cfs;*.gdf;*.ibw"), wxT(""), wxT(""),
-#   else
                                      wxT("Biosig files"), wxT("*.dat;*.cfs;*.gdf;*.ibw;*.wcp"), wxT(""), wxT(""),
-#   endif
                                      wxT("Biosig Document"), wxT("Biosig View"), CLASSINFO(wxStfDoc),
                                      CLASSINFO(wxStfView) );
 #endif
@@ -193,11 +189,7 @@ bool wxStfApp::OnInit(void)
                                      wxT("ABF Document"), wxT("ABF View"), CLASSINFO(wxStfDoc),
                                      CLASSINFO(wxStfView) );
 #if defined(__WXGTK__) || defined(__WXMAC__)
-#if !defined(__MINGW32__)
-#if !defined(WITHOUT_ABF)
     ABF_Initialize();
-#endif
-#endif
 #endif
     m_atfTemplate=new wxDocTemplate( docManager,
                                      wxT("Axon text file"), wxT("*.atf"), wxT(""), wxT("atf"),
diff --git a/src/stimfit/gui/app.h b/src/stimfit/gui/app.h
index 1c3aacbd..f26f8285 100755
--- a/src/stimfit/gui/app.h
+++ b/src/stimfit/gui/app.h
@@ -205,7 +205,8 @@ enum {
 #endif
 #ifdef WITH_PYTHON
 #if PY_MAJOR_VERSION >= 3
-#include <wx/wxPython/wxpy_api.h>
+#include <wxPython/sip.h>
+#include <wxPython/wxpy_api.h>
 #else
 #include <wx/wxPython/wxPython.h>
 #endif
diff --git a/src/stimfit/gui/childframe.cpp b/src/stimfit/gui/childframe.cpp
index 3be0e005..735eee9b 100755
--- a/src/stimfit/gui/childframe.cpp
+++ b/src/stimfit/gui/childframe.cpp
@@ -498,10 +498,10 @@ void wxStfChildFrame::ShowTable(const stfnum::Table &table,const wxString& capti
     wxStfGrid* pGrid = new wxStfGrid( m_notebook, wxID_ANY, wxPoint(0,20), wxDefaultSize );
     wxStfTable* pTable(new wxStfTable(table));
     pGrid->SetTable(pTable,true); // the grid will take care of the deletion
-    pGrid->SetEditable(false);
+    pGrid->EnableEditing(false);
     pGrid->SetDefaultCellAlignment(wxALIGN_RIGHT,wxALIGN_CENTRE);
     for (std::size_t n_row=0; n_row<=table.nRows()+1; ++n_row) {
-        pGrid->SetCellAlignment(wxALIGN_LEFT,(int)n_row,0);
+        pGrid->SetCellAlignment((int)n_row, 0, wxALIGN_LEFT, wxALIGN_CENTRE);
     }
     m_notebook->AddPage( pGrid, caption, true );
 
diff --git a/src/stimfit/gui/dlgs/convertdlg.cpp b/src/stimfit/gui/dlgs/convertdlg.cpp
index 50595748..522761a0 100644
--- a/src/stimfit/gui/dlgs/convertdlg.cpp
+++ b/src/stimfit/gui/dlgs/convertdlg.cpp
@@ -80,9 +80,7 @@ wxStfConvertDlg::wxStfConvertDlg(wxWindow* parent, int id, wxString title, wxPoi
     myextensions.Add(wxT("ASCII         [*.*   ]"));
     myextensions.Add(wxT("HDF5          [*.h5  ]"));
     myextensions.Add(wxT("HEKA files    [*.dat ]"));
-#if (BIOSIG_VERSION >= 10404)
     myextensions.Add(wxT("Igor files    [*.ibw ]"));
-#endif
 
     wxComboBox* myComboBoxExt;
     myComboBoxExt = new wxComboBox(this, wxCOMBOBOX_SRC, myextensions[0], 
@@ -136,7 +134,7 @@ wxStfConvertDlg::wxStfConvertDlg(wxWindow* parent, int id, wxString title, wxPoi
     wxArrayString mydestextensions; //ordered by importance 
     mydestextensions.Add(wxT("Igor binary   [*.ibw ]"));
     mydestextensions.Add(wxT("Axon textfile [*.atf ]"));
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
     mydestextensions.Add(wxT("GDF (Biosig) [*.gdf ]"));
 #endif
 
@@ -197,7 +195,7 @@ void wxStfConvertDlg::OnComboBoxDestExt(wxCommandEvent& event){
         case 1:
             destFilterExt = stfio::atf;
             break;
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
         case 2:
             destFilterExt = stfio::biosig;
             break;
@@ -241,11 +239,9 @@ void wxStfConvertDlg::OnComboBoxSrcExt(wxCommandEvent& event){
         case 6: 
             srcFilterExt =  stfio::heka;
             break;
-#if (BIOSIG_VERSION >= 10404)
         case 7:
             srcFilterExt =  stfio::igor;
             break;
-#endif
         default:   
             srcFilterExt =  stfio::none;
     }
diff --git a/src/stimfit/gui/dlgs/eventdlg.cpp b/src/stimfit/gui/dlgs/eventdlg.cpp
index 75e59e4d..5386c148 100755
--- a/src/stimfit/gui/dlgs/eventdlg.cpp
+++ b/src/stimfit/gui/dlgs/eventdlg.cpp
@@ -7,10 +7,20 @@
 
 #include "./../../stf.h"
 #include "./eventdlg.h"
+#include "./../app.h"
 
-enum {wxID_COMBOTEMPLATES};
+enum {
+    wxID_COMBOTEMPLATES,
+    wxID_CRITERIA,
+    wxDETECTIONCLEMENTS,
+    wxDETECTIONJONAS,
+    wxDETECTIONPERNIA
+};
 
 BEGIN_EVENT_TABLE( wxStfEventDlg, wxDialog )
+EVT_RADIOBUTTON( wxDETECTIONCLEMENTS, wxStfEventDlg::OnClements )
+EVT_RADIOBUTTON( wxDETECTIONJONAS,   wxStfEventDlg::OnJonas )
+EVT_RADIOBUTTON( wxDETECTIONPERNIA,  wxStfEventDlg::OnPernia )
 END_EVENT_TABLE()
 
 wxStfEventDlg::wxStfEventDlg(wxWindow* parent, const std::vector<stf::SectionPointer>& templateSections,
@@ -58,7 +68,7 @@ wxDialog( parent, id, title, pos, size, style ), m_threshold(4.0), m_mode(stf::c
 
         wxStaticText* staticTextThr;
         staticTextThr =
-            new wxStaticText( this, wxID_ANY, wxT("Threshold:"), wxDefaultPosition, wxDefaultSize, 0 );
+            new wxStaticText( this, wxID_CRITERIA, wxT("Threshold:"), wxDefaultPosition, wxDefaultSize, 0 );
         gridSizer->Add( staticTextThr, 0, wxALIGN_LEFT | wxALIGN_CENTER_VERTICAL | wxALL, 2 );
         wxString def; def << m_threshold;
         m_textCtrlThr =
@@ -77,16 +87,30 @@ wxDialog( parent, id, title, pos, size, style ), m_threshold(4.0), m_mode(stf::c
 
         topSizer->Add( gridSizer, 0, wxALIGN_CENTER | wxALL, 5 );
 
+        //*** Radio options for event detection methods ***//
+        m_radioBox = new wxStaticBoxSizer( wxVERTICAL, this, wxT("Detection method"));
+
         wxString m_radioBoxChoices[] = {
-                wxT("Use template scaling (Clements && Bekkers)"),
-                wxT("Use correlation coefficient (Jonas et al.)"),
-                wxT("Use deconvolution (Pernia-Andrade et al.)")
+                wxT("Template scaling (Clements && Bekkers)"),
+                wxT("Correlation coefficient (Jonas et al.)"),
+                wxT("Deconvolution (Pernia-Andrade et al.)")
         };
-        int m_radioBoxNChoices = sizeof( m_radioBoxChoices ) / sizeof( wxString );
-        m_radioBox =
-            new wxRadioBox( this, wxID_ANY, wxT("Select method"), wxDefaultPosition, wxDefaultSize,
-                            m_radioBoxNChoices, m_radioBoxChoices, 0, wxRA_SPECIFY_ROWS );
-        m_radioBox->SetSelection(0);
+
+
+        wxRadioButton* wxRadioClements = new wxRadioButton(this, wxDETECTIONCLEMENTS, m_radioBoxChoices[0],
+            wxDefaultPosition, wxDefaultSize, wxRB_GROUP);
+
+        wxRadioButton* wxRadioJonas = new wxRadioButton(this, wxDETECTIONJONAS, m_radioBoxChoices[1],
+            wxDefaultPosition, wxDefaultSize);
+
+        wxRadioButton* wxRadioPernia = new wxRadioButton(this, wxDETECTIONPERNIA, m_radioBoxChoices[2],
+            wxDefaultPosition, wxDefaultSize);
+
+        m_radioBox->Add(wxRadioClements, 0, wxALIGN_LEFT | wxALIGN_CENTER_VERTICAL | wxALL, 2);
+        m_radioBox->Add(wxRadioJonas,   0, wxALIGN_LEFT | wxALIGN_CENTER_VERTICAL | wxALL, 2);
+        m_radioBox->Add(wxRadioPernia,  0, wxALIGN_LEFT | wxALIGN_CENTER_VERTICAL | wxALL, 2);
+        //m_radioBox->SetSelection(0);
+
         topSizer->Add( m_radioBox, 0, wxALIGN_CENTER | wxALL, 5 );
     }
 
@@ -103,18 +127,29 @@ wxDialog( parent, id, title, pos, size, style ), m_threshold(4.0), m_mode(stf::c
 }
 
 void wxStfEventDlg::EndModal(int retCode) {
+    wxCommandEvent unusedEvent;
     // similar to overriding OnOK in MFC (I hope...)
-    if (retCode==wxID_OK) {
+    switch( retCode) {
+
+    case wxID_OK:
         if (!OnOK()) {
+            wxLogMessage(wxT("Select a detection method"));
             return;
         }
+        break;
+
+    case wxID_CANCEL:
+        break;
+
+    default:
+        return;
     }
     wxDialog::EndModal(retCode);
 }
 
 bool wxStfEventDlg::OnOK() {
     // Read template:
-    m_template=m_comboBoxTemplates->GetCurrentSelection();
+    m_template = m_comboBoxTemplates->GetCurrentSelection();
     if (m_template<0) {
         wxLogMessage(wxT("Please select a valid template"));
         return false;
@@ -125,7 +160,22 @@ bool wxStfEventDlg::OnOK() {
         long tempLong;
         m_textCtrlDist->GetValue().ToLong( &tempLong );
         m_minDistance = (int)tempLong;
-        switch (m_radioBox->GetSelection()) {
+
+        wxRadioButton* wxRadioClements = (wxRadioButton*)FindWindow(wxDETECTIONCLEMENTS);
+        wxRadioButton* wxRadioJonas = (wxRadioButton*)FindWindow(wxDETECTIONJONAS);
+        wxRadioButton* wxRadioPernia = (wxRadioButton*)FindWindow(wxDETECTIONPERNIA);
+
+        if ( wxRadioClements->GetValue() ) 
+            m_mode = stf::criterion;
+        else if ( wxRadioJonas->GetValue() ) 
+            m_mode = stf::correlation;
+        else if ( wxRadioPernia->GetValue() )
+            m_mode = stf::deconvolution;
+        else
+            return false;
+
+        
+        /*switch (m_radioBox->GetSelection()) {
          case 0:
              m_mode = stf::criterion;
              break;
@@ -135,7 +185,7 @@ bool wxStfEventDlg::OnOK() {
          case 2:
              m_mode = stf::deconvolution;
              break;
-        }
+        }*/
         if (m_mode==stf::correlation && (m_threshold<0 || m_threshold>1)) {
             wxLogMessage(wxT("Please select a value between 0 and 1 for the correlation coefficient"));
             return false;
@@ -143,3 +193,45 @@ bool wxStfEventDlg::OnOK() {
     }
     return true;
 }
+
+void wxStfEventDlg::OnClements( wxCommandEvent& event) {
+    event.Skip();
+    
+    wxRadioButton* wxRadioClements = (wxRadioButton*)FindWindow(wxDETECTIONCLEMENTS);
+    wxStaticText* staticTextThr = (wxStaticText*)FindWindow(wxID_CRITERIA);
+
+    if (wxRadioClements == NULL || staticTextThr == NULL){
+        wxGetApp().ErrorMsg(wxT("Null pointer in wxStfEvenDlg::OnClements()"));
+        return;
+    }
+    staticTextThr->SetLabel(wxT("Threshold:"));
+    
+}
+
+void wxStfEventDlg::OnJonas( wxCommandEvent& event) {
+    event.Skip();
+    
+    wxRadioButton* wxRadioJonas = (wxRadioButton*)FindWindow(wxDETECTIONJONAS);
+    wxStaticText* staticTextThr = (wxStaticText*)FindWindow(wxID_CRITERIA);
+
+    if (wxRadioJonas == NULL || staticTextThr == NULL){
+        wxGetApp().ErrorMsg(wxT("Null pointer in wxStfEvenDlg::OnJonas()"));
+        return;
+    }
+    staticTextThr->SetLabel(wxT("Correlation:"));
+    
+}
+
+void wxStfEventDlg::OnPernia( wxCommandEvent& event) {
+    event.Skip();
+    
+    wxRadioButton* wxRadioPernia = (wxRadioButton*)FindWindow(wxDETECTIONPERNIA);
+    wxStaticText* staticTextThr = (wxStaticText*)FindWindow(wxID_CRITERIA);
+
+    if (wxRadioPernia == NULL || staticTextThr == NULL){
+        wxGetApp().ErrorMsg(wxT("Null pointer in wxStfEvenDlg::OnPernia()"));
+        return;
+    }
+    staticTextThr->SetLabel( wxT("Standard deviation:") );
+    
+}
diff --git a/src/stimfit/gui/dlgs/eventdlg.h b/src/stimfit/gui/dlgs/eventdlg.h
index 7198f66b..56b80cd8 100755
--- a/src/stimfit/gui/dlgs/eventdlg.h
+++ b/src/stimfit/gui/dlgs/eventdlg.h
@@ -42,9 +42,19 @@ private:
     int m_template;
     wxStdDialogButtonSizer* m_sdbSizer;
     wxTextCtrl *m_textCtrlThr, *m_textCtrlDist;
-    wxRadioBox* m_radioBox;
+    wxStaticBoxSizer* m_radioBox;
     wxComboBox* m_comboBoxTemplates;
 
+    wxStaticText* staticTextThr;
+
+    wxRadioButton* wxRadioClements;
+    wxRadioButton* wxRadioJonas;
+    wxRadioButton* wxRadioPernia;
+
+    void OnClements( wxCommandEvent & event );
+    void OnJonas( wxCommandEvent & event );
+    void OnPernia( wxCommandEvent & event );
+
     //! Only called when a modal dialog is closed with the OK button.
     /*! \return true if all dialog entries could be read successfully
      */
diff --git a/src/stimfit/gui/dlgs/fitseldlg.cpp b/src/stimfit/gui/dlgs/fitseldlg.cpp
index a7a8a9d5..b7365837 100755
--- a/src/stimfit/gui/dlgs/fitseldlg.cpp
+++ b/src/stimfit/gui/dlgs/fitseldlg.cpp
@@ -229,7 +229,7 @@ void wxStfFitSelDlg::InitOptions(wxFlexGridSizer* optionsGrid) {
     // Use scaling-------------------------------------------------------
     m_checkBox = new wxCheckBox(this, wxID_ANY, wxT("Scale data amplitude to 1.0"),
                                          wxDefaultPosition, wxDefaultSize, 0); 
-    m_checkBox->SetValue(true);
+    m_checkBox->SetValue(false);
     optionsGrid->Add( m_checkBox, 0, wxALIGN_LEFT | wxALIGN_CENTER_VERTICAL | wxALL, 2 );
     
 }
diff --git a/src/stimfit/gui/doc.cpp b/src/stimfit/gui/doc.cpp
index b8d1bbe0..4154d3aa 100755
--- a/src/stimfit/gui/doc.cpp
+++ b/src/stimfit/gui/doc.cpp
@@ -219,17 +219,9 @@ bool wxStfDoc::OnOpenDocument(const wxString& filename) {
     wxGetApp().wxWriteProfileString( wxT("Settings"), wxT("Last directory"), wxfFilename.GetPath() );
     if (wxDocument::OnOpenDocument(filename)) { //calls base class function
 
-#ifndef TEST_MINIMAL
-    #if 0 //(defined(WITH_BIOSIG) || defined(WITH_BIOSIG2) && !defined(__WXMAC__))
-        // Detect type of file according to filter:
-        wxString filter(GetDocumentTemplate()->GetFileFilter());
-    #else
         wxString filter(wxT("*.") + wxfFilename.GetExt());
-    #endif
         stfio::filetype type = stfio::findType(stf::wx2std(filter));
-#else
-        stfio::filetype type = stfio::none;
-#endif
+
 #if 0 // TODO: backport ascii
         if (type==stf::ascii) {
             if (!wxGetApp().get_directTxtImport()) {
@@ -730,7 +722,7 @@ bool wxStfDoc::SaveAs() {
     filters += wxT("Igor binary wave (*.ibw)|*.ibw|");
     filters += wxT("Mantis TDMS file (*.tdms)|*.tdms|");
     filters += wxT("Text file series (*.txt)|*.txt|");
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
     filters += wxT("GDF file (*.gdf)|*.gdf");
 #endif
 
@@ -750,7 +742,7 @@ bool wxStfDoc::SaveAs() {
             case 3: type=stfio::igor; break;
             case 4: type=stfio::tdms; break;
             case 5: type=stfio::ascii; break;
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
             default: type=stfio::biosig;
 #else
             default: type=stfio::hdf5;
@@ -803,7 +795,6 @@ Recording wxStfDoc::ReorderChannels() {
     return writeRec;
 }
 
-#ifndef TEST_MINIMAL
 bool wxStfDoc::DoSaveDocument(const wxString& filename) {
     Recording writeRec(ReorderChannels());
     if (writeRec.size() == 0) return false;
@@ -819,7 +810,6 @@ bool wxStfDoc::DoSaveDocument(const wxString& filename) {
         return false;
     }
 }
-#endif
 
 void wxStfDoc::WriteToReg() {
     //Write file length
@@ -3336,6 +3326,13 @@ void wxStfDoc::SetIsIntegrated(std::size_t nchannel, std::size_t nsection, bool
 }
 
 void wxStfDoc::ClearEvents(std::size_t nchannel, std::size_t nsection) {
+    wxStfView* pView=(wxStfView*)GetFirstView();
+    if (pView!=NULL) {
+        wxStfGraph* pGraph = pView->GetGraph();
+        if (pGraph != NULL) {
+            pGraph->ClearEvents();
+        }
+    }
     try {
         sec_attr.at(nchannel).at(nsection).eventList.clear();
     }
diff --git a/src/stimfit/gui/graph.cpp b/src/stimfit/gui/graph.cpp
index b9b20692..9151f3d8 100755
--- a/src/stimfit/gui/graph.cpp
+++ b/src/stimfit/gui/graph.cpp
@@ -574,6 +574,19 @@ void wxStfGraph::PlotEvents(wxDC& DC) {
     SetFocus();
 }
 
+void wxStfGraph::ClearEvents() {
+    stf::SectionAttributes sec_attr;
+    try {
+        sec_attr = Doc()->GetCurrentSectionAttributes();
+    }
+    catch (const std::out_of_range& e) {
+        return;
+    }
+    for (event_it it2 = sec_attr.eventList.begin(); it2 != sec_attr.eventList.end(); ++it2) {
+        it2->GetCheckBox()->Destroy();
+    }
+}
+
 void wxStfGraph::DrawCrosshair( wxDC& DC, const wxPen& pen, const wxPen& printPen, int crosshairSize, double xch, double ych) {
     if (isnan(xch) || isnan(ych)) {
         return;
@@ -681,10 +694,10 @@ void wxStfGraph::DoPlot( wxDC* pDC, const Vector_double& trace, int start, int e
 
     switch (pt) {
      case active:
-         yFormatFunc = std::bind1st( std::mem_fun(&wxStfGraph::yFormatD), this);
+         yFormatFunc = std::bind1st( std::mem_fn(&wxStfGraph::yFormatD), this);
          break;
      case reference:
-         yFormatFunc = std::bind1st( std::mem_fun(&wxStfGraph::yFormatD2), this);
+         yFormatFunc = std::bind1st( std::mem_fn(&wxStfGraph::yFormatD2), this);
          break;
      case background:
          Vector_double::const_iterator max_el = std::max_element(trace.begin(), trace.end());
@@ -699,7 +712,7 @@ void wxStfGraph::DoPlot( wxDC* pDC, const Vector_double& trace, int start, int e
          WindowRect.height /= Doc()->size();
          FittorectY(yzoombg, WindowRect, min, max, 1.0);
          yzoombg.startPosY += bgno*WindowRect.height;
-         yFormatFunc = std::bind1st( std::mem_fun(&wxStfGraph::yFormatDB), this);
+         yFormatFunc = std::bind1st( std::mem_fn(&wxStfGraph::yFormatDB), this);
          break;
     }
 
@@ -819,10 +832,10 @@ void wxStfGraph::DoPrint( wxDC* pDC, const Vector_double& trace, int start, int
     
     switch (ptype) {
      case active:
-         yFormatFunc = std::bind1st( std::mem_fun(&wxStfGraph::yFormatD), this);
+         yFormatFunc = std::bind1st( std::mem_fn(&wxStfGraph::yFormatD), this);
          break;
      default:
-         yFormatFunc = std::bind1st( std::mem_fun(&wxStfGraph::yFormatD2), this);
+         yFormatFunc = std::bind1st( std::mem_fn(&wxStfGraph::yFormatD2), this);
          break;
     }
 
diff --git a/src/stimfit/gui/graph.h b/src/stimfit/gui/graph.h
index fed17868..df6d1187 100755
--- a/src/stimfit/gui/graph.h
+++ b/src/stimfit/gui/graph.h
@@ -210,6 +210,9 @@ public:
      */
     void Fittowindow(bool refresh);
 
+    //! Destroys all event check boxes
+    void ClearEvents();
+
     //! Set to true if the graph is drawn on a printer.
     /*! \param value boolean determining whether the graph is printed.
      */
diff --git a/src/stimfit/gui/parentframe.cpp b/src/stimfit/gui/parentframe.cpp
index 3d54c153..d0bedb51 100755
--- a/src/stimfit/gui/parentframe.cpp
+++ b/src/stimfit/gui/parentframe.cpp
@@ -62,7 +62,7 @@
 #include "./dlgs/smalldlgs.h"
 #include "./copygrid.h"
 #include "./../../libstfio/atf/atflib.h"
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
     #include "./../../libstfio/biosig/biosiglib.h"
 #endif
 #include "./../../libstfio/igor/igorlib.h"
@@ -266,6 +266,7 @@ wxStfParentType(manager, frame, wxID_ANY, title, pos, size, type, _T("myFrame"))
 #ifdef WITH_PYTHON
     python_code2 << wxT("import sys\n")
                  << wxT("sys.path.append('.')\n")
+                 << wxT("sys.path.append('/usr/local/lib/stimfit')\n")
 #ifdef IPYTHON
                  << wxT("import embedded_ipython\n")
 #else
@@ -547,9 +548,7 @@ wxStfToolBar* wxStfParentFrame::CreateCursorTb() {
 }
 
 #if 0
-#if defined(WITH_BIOSIG2)
-    #define CREDIT_BIOSIG "Biosig import using libbiosig2 http://biosig.sf.net\n\n"
-#elif defined(WITH_BIOSIG)
+#if defined(WITH_BIOSIG)
     #define CREDIT_BIOSIG "Biosig import using libbiosig http://biosig.sf.net\n\n"
 #else 
     #define CREDIT_BIOSIG ""
@@ -568,7 +567,7 @@ void wxStfParentFrame::OnAbout(wxCommandEvent& WXUNUSED(event) )
     Levenberg-Marquardt non-linear regression, version ") + wxString(wxT(LM_VERSION)) + wxT("\n\
     Manolis Lourakis, http://www.ics.forth.gr/~lourakis/levmar/ \n\n")) +
 
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
     wxString( wxT("BioSig import using libbiosig\n") ) + 
     //+ wxString( wxT("version ") + wxT(BIOSIG_VERSION ) ) +
     wxString( wxT("http://biosig.sf.net\n\n") ) +
@@ -793,18 +792,16 @@ void wxStfParentFrame::OnConvert(wxCommandEvent& WXUNUSED(event) ) {
 
                 stf::wxProgressInfo progDlgOut("Writing file", "Opening file", 100);
                 switch ( eft ) {
-#ifndef WITHOUT_ABF
                  case stfio::atf:
                      stfio::exportATFFile(stf::wx2std(destFilename), sourceFile);
                      dest_ext = wxT("Axon textfile [*.atf]");
                      break;
-#endif
                  case stfio::igor:
                      stfio::exportIGORFile(stf::wx2std(destFilename), sourceFile, progDlgOut);
                      dest_ext = wxT("Igor binary file [*.ibw]");
                      break;
 
-#if (defined(WITH_BIOSIG) || defined(WITH_BIOSIG2))
+#if defined(WITH_BIOSIG)
                  case stfio::biosig:
                      stfio::exportBiosigFile(stf::wx2std(destFilename), sourceFile, progDlgOut);
                      dest_ext = wxT("Biosig/GDF [*.gdf]");
diff --git a/src/stimfit/gui/unopt.cpp b/src/stimfit/gui/unopt.cpp
index 71d11f9b..63898155 100644
--- a/src/stimfit/gui/unopt.cpp
+++ b/src/stimfit/gui/unopt.cpp
@@ -30,9 +30,11 @@
   #pragma GCC diagnostic ignored "-Wwrite-strings"
 #endif
 #if PY_MAJOR_VERSION >= 3
-#include <wx/wxPython/wxpy_api.h>
-#define PyString_Check PyBytes_Check
+#include <wxPython/sip.h>
+#include <wxPython/wxpy_api.h>
+#define PyString_Check PyUnicode_Check
 #define PyString_AsString PyBytes_AsString
+#define PyString_FromString PyUnicode_FromString
 #else
 #include <wx/wxPython/wxPython.h>
 #endif
@@ -101,6 +103,70 @@ wxString GetExecutablePath() {
 }
 #endif // _WINDOWS
 
+#if PY_MAJOR_VERSION >= 3
+PyObject*  wxPyMake_wxObject(wxObject* source, bool setThisOwn) {
+    bool checkEvtHandler = true;
+    PyObject* target = NULL;
+    bool      isEvtHandler = false;
+    bool      isSizer = false;
+
+    if (source) {
+        // If it's derived from wxEvtHandler then there may
+        // already be a pointer to a Python object that we can use
+        // in the OOR data.
+        if (checkEvtHandler && wxIsKindOf(source, wxEvtHandler)) {
+            isEvtHandler = true;
+            wxEvtHandler* eh = (wxEvtHandler*)source;
+            wxPyClientData* data = (wxPyClientData*)eh->GetClientObject();
+            if (data) {
+                target = data->GetData();
+            }
+        }
+
+        // Also check for wxSizer
+        if (!target && wxIsKindOf(source, wxSizer)) {
+            isSizer = true;
+            wxSizer* sz = (wxSizer*)source;
+            wxPyClientData* data = (wxPyClientData*)sz->GetClientObject();
+            if (data) {
+                target = data->GetData();
+            }
+        }
+        if (! target) {
+            // Otherwise make it the old fashioned way by making a new shadow
+            // object and putting this pointer in it.  Look up the class
+            // heirarchy until we find a class name that is located in the
+            // python module.
+            const wxClassInfo* info   = source->GetClassInfo();
+            wxString           name   = info->GetClassName();
+	    wxString           childname = name.Clone();
+            if (info) {
+                target = wxPyConstructObject((void*)source, name.c_str(), setThisOwn);
+		while (target == NULL) {
+		    info = info->GetBaseClass1();
+		    name = info->GetClassName();
+		    if (name == childname)
+                        break;
+		    childname = name.Clone();
+		    target = wxPyConstructObject((void*)source, name.c_str(), setThisOwn);
+		}
+                if (target && isEvtHandler)
+                    ((wxEvtHandler*)source)->SetClientObject(new wxPyClientData(target));
+                if (target && isSizer)
+                    ((wxSizer*)source)->SetClientObject(new wxPyClientData(target));
+            } else {
+                wxString msg(wxT("wxPython class not found for "));
+                msg += source->GetClassInfo()->GetClassName();
+                PyErr_SetString(PyExc_NameError, msg.mbc_str());
+                target = NULL;
+            }
+        }
+    } else {  // source was NULL so return None.
+        Py_INCREF(Py_None); target = Py_None;
+    }
+    return target;
+}
+#endif
 
 bool wxStfApp::Init_wxPython()
 {
@@ -184,7 +250,9 @@ bool wxStfApp::Init_wxPython()
         Py_Finalize();
         return false;
     }
-#if wxCHECK_VERSION(3, 0, 0)
+#if wxCHECK_VERSION(3, 1, 0)
+    PyObject* ver_string = Py_BuildValue("ss","3.1","");
+#elif wxCHECK_VERSION(3, 0, 0)
     PyObject* ver_string = Py_BuildValue("ss","3.0","");
 #elif wxCHECK_VERSION(2, 9, 0)
     PyObject* ver_string = Py_BuildValue("ss","2.9","");
@@ -280,7 +348,11 @@ void wxStfApp::ImportPython(const wxString &modulelocation) {
     python_import << wxT("ip = IPython.ipapi.get()\n");
     python_import << wxT("import sys\n");
     python_import << wxT("sys.path.append(\"") << python_path << wxT("\")\n");
+#if (PY_VERSION_HEX < 0x03000000)
     python_import << wxT("if not sys.modules.has_key(\"") << python_file << wxT("\"):");
+#else
+    python_import << wxT("if '") << python_file << wxT("' not in sys.modules:");
+#endif
     python_import << wxT("ip.ex(\"import ") << python_file << wxT("\")\n");
     python_import << wxT("else:") << wxT("ip.ex(\"reload(") << python_file << wxT(")") << wxT("\")\n");
     python_import << wxT("sys.path.remove(\"") << python_path << wxT("\")\n");
@@ -289,7 +361,11 @@ void wxStfApp::ImportPython(const wxString &modulelocation) {
     // Python code to import a module with PyCrust 
     python_import << wxT("import sys\n");
     python_import << wxT("sys.path.append(\"") << python_path << wxT("\")\n");
+#if (PY_VERSION_HEX < 0x03000000)
     python_import << wxT("if not sys.modules.has_key(\"") << python_file << wxT("\"):");
+#else
+    python_import << wxT("if '") << python_file << wxT("' not in sys.modules:");
+#endif
     python_import << wxT("import ") << python_file << wxT("\n");
     python_import << wxT("else:") << wxT("reload(") << python_file << wxT(")") << wxT("\n");
     python_import << wxT("sys.path.remove(\"") << python_path << wxT("\")\n");
@@ -368,7 +444,7 @@ new_wxwindow wxStfParentFrame::MakePythonWindow(const std::string& windowFunc, c
     Py_DECREF(builtins);
 
     // Execute the code to make the makeWindow function
-    result = PyRun_String(python_code2.char_str(), Py_file_input, globals, globals);
+    result = PyRun_String(python_code2.c_str(), Py_file_input, globals, globals);
     // Was there an exception?
     if (! result) {
         PyErr_Print();
@@ -392,11 +468,7 @@ new_wxwindow wxStfParentFrame::MakePythonWindow(const std::string& windowFunc, c
     // Now build an argument tuple and call the Python function.  Notice the
     // use of another wxPython API to take a wxWindows object and build a
     // wxPython object that wraps it.
-#if PY_MAJOR_VERSION >= 3
-    PyObject* arg = wxPyConstructObject((void*)this, wxT("wxWindow"), false);
-#else
     PyObject* arg = wxPyMake_wxObject(this, false);
-#endif
     wxASSERT(arg != NULL);
     PyObject* py_mpl_width = PyFloat_FromDouble(mpl_width);
     wxASSERT(py_mpl_width != NULL);
@@ -655,7 +727,7 @@ bool wxStfDoc::LoadTDMS(const std::string& filename, Recording& ReturnData) {
     PyObject* data_list = PyTuple_GetItem(stf_tdms_res, 0);
     PyObject* py_dt = PyTuple_GetItem(stf_tdms_res, 1);
     double dt = PyFloat_AsDouble(py_dt);
-    Py_DECREF(py_dt);
+    // Py_DECREF(py_dt);
 
     Py_ssize_t nchannels = PyList_Size(data_list);
     ReturnData.resize(nchannels);
@@ -673,15 +745,15 @@ bool wxStfDoc::LoadTDMS(const std::string& filename, Recording& ReturnData) {
                 double* data = (double*)PyArray_DATA(np_array);
                 std::copy(&data[0], &data[nsamples], &sec.get_w()[0]);
                 ch.InsertSection(sec, ns);
-                Py_DECREF(np_array);
+                // Py_DECREF(np_array);
             }
             ReturnData.InsertChannel(ch, nc);
             nchannels_nonempty++;
         }
-        Py_DECREF(section_list);
+        // Py_DECREF(section_list);
     }
-    Py_DECREF(data_list);
-    Py_DECREF(stf_tdms_res);
+    // Py_DECREF(data_list);
+    // Py_DECREF(stf_tdms_res);
     ReturnData.resize(nchannels_nonempty);
     ReturnData.SetXScale(dt);
     wxPyEndBlockThreads(blocked);
diff --git a/src/stimfit/py/Makefile.am b/src/stimfit/py/Makefile.am
index 1c9c76b7..1770dc8d 100755
--- a/src/stimfit/py/Makefile.am
+++ b/src/stimfit/py/Makefile.am
@@ -12,7 +12,7 @@ nodist_libpystf_la_SOURCES = $(srcdir)/pystf_wrap.cxx
 libpystf_la_SOURCES = $(srcdir)/pystf.cxx # $(SWIG_SOURCES)
 noinst_HEADERS = pystf.h
 
-INCLUDES = $(LIBNUMPY_INCLUDES)
+INCLUDES = $(LIBNUMPY_INCLUDES) $(LIBPYTHON_INCLUDES) $(LIBWXPYTHON_INCLUDES)
 
 libpystf_la_CPPFLAGS = $(SWIG_PYTHON_CPPFLAGS) -I$(top_srcdir)/src
 libpystf_la_CXXFLAGS = $(OPT_CXXFLAGS) $(WX_CXXFLAGS)
diff --git a/src/stimfit/py/embedded_stf.py b/src/stimfit/py/embedded_stf.py
index 3f748b10..b75e0dca 100644
--- a/src/stimfit/py/embedded_stf.py
+++ b/src/stimfit/py/embedded_stf.py
@@ -10,10 +10,11 @@ starting code to embed wxPython into the stf application.
 
 """
 import sys
-if 'win' in sys.platform:
+if 'win' in sys.platform and sys.platform != 'darwin':
     import wxversion
     wxversion.select('3.0-msw')
 import wx
+wx.CallAfter = lambda x, y : (x, y)
 from wx.py import shell
 
 # to access the current versions of Stimfit, NumPy and wxPython
diff --git a/src/stimfit/py/minidemo.py b/src/stimfit/py/minidemo.py
index 9cf44065..702e64fd 100755
--- a/src/stimfit/py/minidemo.py
+++ b/src/stimfit/py/minidemo.py
@@ -1,43 +1,69 @@
-"""Performs fits as decribed in the manual to create 
-preliminary and final templates from minis.dat.
-last revision: May 09, 2008
+"""
+minidemo.py
+
+This script sets base, peak and fit cursors to
+perform events detection as decribed in the Stimfit manual [1]
+It creates a preliminary and final templates from a file 'minis.dat'.
+
+You can download the file here: http://stimfit.org/tutorial/minis.dat
+
+last revision:  Wed Sep  5 09:38:41 CEST 2018
+
 C. Schmidt-Hieber
+
+[1] https://neurodroid.github.io/stimfit/manual/event_extraction.html
 """
 
 import stf
+from wx import MessageBox
+
+if stf.get_filename()[-9:] != 'minis.dat':
+    MessageBox('Use minis.dat for this demo.', 'Warning')
+
+
 def preliminary():
-    """Creates a preliminary template"""
-    stf.set_peak_start(209900)
-    stf.set_peak_end(210500)
-    stf.set_fit_start(209900)
-    stf.set_fit_end(210400)
+    """
+    Sets peak, base and fit cursors around a synaptic event
+    and performs a biexponential fit to create the preliminary template
+    for event detection.
+    """
+    stf.base.cursor_index = (209600, 209900)
+    stf.peak.cursor_index = (209900, 210500)
+    stf.fit.cursor_index = (209900, 210400)
+
     stf.set_peak_mean(3)
-    stf.set_base_start(209600)
-    stf.set_base_end(209900)
-    stf.measure()
+
+    stf.measure()  # update cursors
+
     return stf.leastsq(5)
 
+
 def final():
-    """Creates a final template"""
-    stf.set_peak_start(100)
-    stf.set_peak_end(599)
-    stf.set_fit_start(100)
-    stf.set_fit_end(599)
+    """
+    Sets peak, base and fit cursors around a synaptic event
+    and performs a biexponetial fit to create the final template
+    for event detection.
+    """
+    stf.base.cursor_index = (000, 100)
+    stf.peak.cursor_index = (100, 599)
+    stf.fit.cursor_index = (100, 599)
+
     stf.set_peak_mean(3)
-    stf.set_base_start(0)
-    stf.set_base_end(100)
-    stf.measure()
+
+    stf.measure()  # update cursors
+
     return stf.leastsq(5)
 
+
 def batch_cursors():
-    """Sets appropriate cursor positions for analysing
-    the extracted events."""
-    stf.set_peak_start(100)
-    stf.set_peak_end(598)
-    stf.set_fit_start(120)
-    stf.set_fit_end(598)
+    """
+    Sets peak, base and fit cursors around a synaptic event
+    for the batch analysis of the extracted events.
+    """
+    stf.base.cursor_index = (000, 100)
+    stf.peak.cursor_index = (100, 598)
+    stf.fit.cursor_index = (120, 598)
+
     stf.set_peak_mean(3)
-    stf.set_base_start(0)
-    stf.set_base_end(100)
-    stf.measure()
 
+    stf.measure()  # update cursors
diff --git a/src/stimfit/py/pystf.cxx b/src/stimfit/py/pystf.cxx
index c4ddd832..f0d7c79c 100755
--- a/src/stimfit/py/pystf.cxx
+++ b/src/stimfit/py/pystf.cxx
@@ -42,7 +42,8 @@
 
 #ifdef WITH_PYTHON
     #if PY_MAJOR_VERSION >= 3
-        #include <wx/wxPython/wxpy_api.h>
+        #include <wxPython/sip.h>
+        #include <wxPython/wxpy_api.h>
         #define PyInt_FromLong PyLong_FromLong
         #define PyString_AsString PyBytes_AsString
     #else
diff --git a/src/stimfit/stf.h b/src/stimfit/stf.h
index f44aeb8b..adb4156d 100644
--- a/src/stimfit/stf.h
+++ b/src/stimfit/stf.h
@@ -27,6 +27,9 @@
 #ifndef _WINDOWS
 #if (__cplusplus < 201103)
     #include <boost/function.hpp>
+#else
+    #include <algorithm>
+    #include <memory>
 #endif
 #endif
 
diff --git a/src/test/fit.cpp b/src/test/fit.cpp
index 0d713cf4..151ebe02 100644
--- a/src/test/fit.cpp
+++ b/src/test/fit.cpp
@@ -383,7 +383,7 @@ TEST(fitlib_test, id_02_monoexponential_with_delay){
     std::string info;
     int warning;
     double chisqr = stfnum::lmFit(data, dt, funcLib[2], opts, 
-        true, /*use_scaling*/
+        false, /*use_scaling*/
         pars, info, warning );
 
     EXPECT_EQ(warning, 0);
@@ -763,7 +763,7 @@ TEST(fitlib_test, id_09_alpha){
     int warning;
 
     double chisqr = stfnum::lmFit(data, dt, funcLib[9], opts, 
-        true, /*use_scaling*/
+        false, /*use_scaling*/
         pars, info, warning );
 
     EXPECT_EQ(warning, 0);
@@ -812,7 +812,7 @@ TEST(fitlib_test, id_10_HH_gNa_offsetfixed){
     int warning;
 
     double chisqr = stfnum::lmFit(data, dt, funcLib[10], opts, 
-        true, /* use_scaling */
+	false, /* use_scaling */
         pars, info, warning );
 
     EXPECT_EQ(warning, 0);
@@ -861,7 +861,7 @@ TEST(fitlib_test, id_11_HH_gNa_biexpoffsetfixed){
     int warning;
 
     double chisqr = stfnum::lmFit(data, dt, funcLib[11], opts, 
-        true, /*use_scaling*/
+        false, /*use_scaling*/
         pars, info, warning );
 
     EXPECT_EQ(warning, 0);
diff --git a/Makefile.am b/Makefile.am
index 232b2a2a..52922361 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -115,13 +115,9 @@ noinst_HEADERS = \
 	./src/test/gtest/include/gtest/internal/gtest-type-util.h \
 	./src/test/gtest/src/gtest-internal-inl.h
 
-if WITH_BIOSIG2
-    noinst_HEADERS += ./src/libstfio/biosig/biosiglib.h
-else
 if WITH_BIOSIG
     noinst_HEADERS += ./src/libstfio/biosig/biosiglib.h
 endif # WITH_BIOSIG
-endif # WITH_BIOSIG2
 
 EXTRA_DIST = ./src/stimfit/res/16-em-down.xpm
 EXTRA_DIST+= ./src/stimfit/res/16-em-open.xpm
@@ -185,8 +181,8 @@ EXTRA_DIST+= ./dist/debian/control
 EXTRA_DIST+= ./dist/debian/copyright
 EXTRA_DIST+= ./dist/debian/docs
 EXTRA_DIST+= ./dist/debian/mkdeb.sh
-EXTRA_DIST+= ./dist/debian/python-stfio.files
-EXTRA_DIST+= ./dist/debian/python-stfio.install
+EXTRA_DIST+= ./dist/debian/python3-stfio.files
+EXTRA_DIST+= ./dist/debian/python3-stfio.install
 EXTRA_DIST+= ./dist/debian/rules
 EXTRA_DIST+= ./dist/debian/stimfit.1
 EXTRA_DIST+= ./dist/debian/stimfit.desktop
@@ -206,7 +202,7 @@ EXTRA_DIST+= ./src/test/gtest/src/gtest-test-part.cc
 EXTRA_DIST+= ./src/test/gtest/src/gtest-typed-test.cc
 
 if BUILD_PYTHON
-    PYTHON_ADDINCLUDES = $(LIBPYTHON_INCLUDES)
+    PYTHON_ADDINCLUDES = $(LIBPYTHON_INCLUDES) $(LIBWXPYTHON_INCLUDES)
     PYTHON_ADDLDFLAGS = $(LIBPYTHON_LDFLAGS)
     PYTHON_ADDLIBS = ./src/stimfit/py/libpystf.la
 else !BUILD_PYTHON
@@ -231,138 +227,17 @@ stimfit_LDADD += ./src/libbiosiglite/libbiosiglite.la
 stimfittest_LDADD += ./src/libbiosiglite/libbiosiglite.la
 endif
 
-if !ISDARWIN
-if BUILD_DEBIAN
-LTTARGET=/usr/lib/stimfit
-install-exec-hook:
-	$(LIBTOOL) --finish $(prefix)/lib/stimfit
-	chrpath -r $(LTTARGET) $(prefix)/bin/stimfit
-	chrpath -r $(LTTARGET) $(prefix)/lib/stimfit/libpystf.so
-	chrpath -r $(LTTARGET) $(prefix)/lib/stimfit/libstimfit.so
-	chrpath -r $(LTTARGET) $(prefix)/lib/stimfit/libstfio.so
-	chrpath -r $(LTTARGET) $(prefix)/lib/stimfit/libstfnum.so
-	chrpath -r $(LTTARGET) $(prefix)/lib/stimfit/libbiosiglite.so
-	install -d $(prefix)/share/pixmaps
-	install -d $(prefix)/share/applications
-	install -m 644 $(top_srcdir)/src/stimfit/res/stimfit16x16.xpm $(prefix)/share/pixmaps/stimfit16x16.xpm
-	install -m 644 $(top_srcdir)/src/stimfit/res/stimfit32x32.xpm $(prefix)/share/pixmaps/stimfit32x32.xpm
-	install -m 644 $(top_srcdir)/dist/debian/stimfit.desktop $(prefix)/share/applications/
-else !BUILD_DEBIAN
 LTTARGET=$(prefix)/lib/stimfit
 install-exec-hook:
 	$(LIBTOOL) --finish $(LTTARGET)
-	chrpath -r $(LTTARGET) $(prefix)/bin/stimfit
 	install -d $(prefix)/share/pixmaps
 	install -d $(prefix)/share/applications
 	install -m 644 $(top_srcdir)/src/stimfit/res/stimfit16x16.xpm $(prefix)/share/pixmaps/stimfit16x16.xpm
 	install -m 644 $(top_srcdir)/src/stimfit/res/stimfit32x32.xpm $(prefix)/share/pixmaps/stimfit32x32.xpm
 	install -m 644 $(top_srcdir)/dist/debian/stimfit.desktop $(prefix)/share/applications/
-endif !BUILD_DEBIAN
 uninstall-hook:
 	rm -f $(prefix)/share/pixmaps/stimfit16x16.xpm
 	rm -f $(prefix)/share/pixmaps/stimfit32x32.xpm
 	rm -f $(prefix)/share/applications/stimfit.desktop
-else ISDARWIN
-LTTARGET=$(prefix)/lib/stimfit
-# wxMac resource fork/unbundled app
-install: stimfit
-	mkdir -p ${DESTDIR}/stimfit.app/Contents/MacOS
-	mkdir -p ${DESTDIR}/stimfit.app/Contents/Resources
-	mkdir -p ${DESTDIR}/stimfit.app/Contents/Resources/English.lproj
-	mkdir -p ${DESTDIR}/stimfit.app/Contents/Frameworks/stimfit
-	mkdir -p ${DESTDIR}/stimfit.app/Contents/lib/stimfit
-	cp -v ./src/stimfit/.libs/libstimfit.dylib ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libstimfit.dylib
-	cp -v ./src/libstfio/.libs/libstfio.dylib ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libstfio.dylib
-	cp -v ./src/libstfnum/.libs/libstfnum.dylib ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libstfnum.dylib
-if WITH_BIOSIGLITE
-	cp -v ./src/libbiosiglite/.libs/libbiosiglite.dylib ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libbiosiglite.dylib
-endif
-	cp $(top_srcdir)/dist/macosx/stimfit.plist.in ${DESTDIR}/stimfit.app/Contents/Info.plist
-	echo "APPL????\c" > ${DESTDIR}/stimfit.app/Contents/PkgInfo
-	rm -f ${DESTDIR}/stimfit.app/Contents/MacOS/stimfit$(EXEEXT)
-	cp -p -f .libs/stimfit$(EXEEXT) ${DESTDIR}/stimfit.app/Contents/MacOS/stimfit$(EXEEXT)
-if BUILD_PYTHON
-	cp -v ./src/stimfit/py/.libs/libpystf.dylib ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libpystf.dylib
-	ln -sf ../../lib/stimfit/libpystf.dylib ${DESTDIR}/stimfit.app/Contents/Frameworks/stimfit/_stf.so
-	cp -v $(top_srcdir)/src/stimfit/py/*.py ${DESTDIR}/stimfit.app/Contents/Frameworks/stimfit/
-	cp -v $(top_srcdir)/src/pystfio/*.py ${DESTDIR}/stimfit.app/Contents/Frameworks/stimfit/
-	${PYTHON} -m compileall -l ${DESTDIR}/stimfit.app/Contents/Frameworks/stimfit/
-endif BUILD_PYTHON
-	$(POSTLINK_COMMAND) ${DESTDIR}/stimfit.app/Contents/MacOS/stimfit$(EXEEXT) \
-	                    $(srcdir)/dist/macosx/app.r
-	$(MACSETFILE) -a C ${DESTDIR}/stimfit.app/Contents/MacOS/stimfit$(EXEEXT)
-	cp -f $(top_srcdir)/dist/macosx/stimfit.icns ${DESTDIR}/stimfit.app/Contents/Resources/stimfit.icns
-	install_name_tool -change \
-	                  $(LTTARGET)/libstimfit.dylib \
-	                  @executable_path/../lib/stimfit/libstimfit.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/MacOS/stimfit
-	install_name_tool -change \
-	                  $(LTTARGET)/libstfio.dylib \
-	                  @executable_path/../lib/stimfit/libstfio.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/MacOS/stimfit
-	install_name_tool -change \
-	                  $(LTTARGET)/libstfnum.dylib \
-	                  @executable_path/../lib/stimfit/libstfnum.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/MacOS/stimfit
-	install_name_tool -change \
-	                  $(LTTARGET)/libstimfit.dylib \
-	                  @executable_path/../lib/stimfit/libstimfit.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libstimfit.dylib
-	install_name_tool -change \
-	                  $(LTTARGET)/libstfio.dylib \
-	                  @executable_path/../lib/stimfit/libstfio.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libstimfit.dylib
-	install_name_tool -change \
-	                  $(LTTARGET)/libstfio.dylib \
-	                  @executable_path/../lib/stimfit/libstfio.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libstfio.dylib
-	install_name_tool -change \
-	                  $(LTTARGET)/libstfnum.dylib \
-	                  @executable_path/../lib/stimfit/libstfnum.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libstimfit.dylib
-	install_name_tool -change \
-	                  $(LTTARGET)/libstfnum.dylib \
-	                  @executable_path/../lib/stimfit/libstfnum.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libstfnum.dylib
-if WITH_BIOSIGLITE
-	install_name_tool -change \
-	                  $(LTTARGET)/libbiosiglite.dylib \
-	                  @executable_path/../lib/stimfit/libbiosiglite.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/MacOS/stimfit
-	install_name_tool -change \
-	                  $(LTTARGET)/libbiosiglite.dylib \
-	                  @executable_path/../lib/stimfit/libbiosiglite.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libstimfit.dylib
-	install_name_tool -change \
-	                  $(LTTARGET)/libbiosiglite.dylib \
-	                  @executable_path/../lib/stimfit/libbiosiglite.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libstfnum.dylib
-endif
-if BUILD_PYTHON
-	install_name_tool -change \
-	                  $(LTTARGET)/libstimfit.dylib \
-	                  @executable_path/../lib/stimfit/libstimfit.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libpystf.dylib
-	install_name_tool -change \
-	                  $(LTTARGET)/libstfio.dylib \
-	                  @executable_path/../lib/stimfit/libstfio.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libpystf.dylib
-	install_name_tool -change \
-	                  $(LTTARGET)/libstfnum.dylib \
-	                  @executable_path/../lib/stimfit/libstfnum.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libpystf.dylib
-	install_name_tool -change \
-	                  $(LTTARGET)/libpystf.dylib \
-	                  @executable_path/../lib/stimfit/libpystf.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libpystf.dylib
-if WITH_BIOSIGLITE
-	install_name_tool -change \
-	                  $(LTTARGET)/libbiosiglite.dylib \
-	                  @executable_path/../lib/stimfit/libbiosiglite.dylib \
-	                  ${DESTDIR}/stimfit.app/Contents/lib/stimfit/libpystf.dylib
-endif
-endif BUILD_PYTHON
-
-endif ISDARWIN
 
 endif  # !BUILD_MODULE
