# -*- coding: utf-8 -*-
"""
Loading and plotting data.
"""

from IPython import get_ipython
get_ipython().magic('reset -sf')


import numpy as np
import matplotlib.pyplot as plt
cc = plt.rcParams['axes.prop_cycle'].by_key()['color']


plt.close('all')
#%%
import numpy as np
'''
function for loading from .lvm
returns [tt, aa1, aa2, freq, Z, theta]

tt - time (s)
aa1 - PCB accelerometer
aa2 - table accelerometer
freq - frequency of impedance measurements
Z - impedance magnitude
theta - impedance angle
'''
def load_lvm(filename):
    data = np.loadtxt(file_name+'.lvm',skiprows=24,delimiter=',',usecols=(0,1,2))
    # time (given in seconds)
    tt = data[:,0]*1e3 # convert time to milliseconds
    # PCB accelerometer
    aa1 = data[:,1]
    # table accelerometer
    aa2 = data[:,2]
    
    electrical_test_data = np.loadtxt(file_name+'.lvm',skiprows=24,delimiter=',',usecols=(3,4,5),max_rows=5)
    electrical_test_data = np.flip(electrical_test_data,axis=0)
    freq = electrical_test_data[:,0]
    Z = electrical_test_data[:,1]
    theta = electrical_test_data[:,2]
    
    return [tt, aa1, aa2, freq, Z, theta]
#%% use function to make plots
for i in range(17,27):

    file_name = 'MT_AZT_2103_1_0'+str(i)
    
    tt, aa1, aa2, freq, Z, theta = load_lvm(file_name + '.lvm')
    
    # make a multiplot time series and impedance with frequency
    pcb_center= tt[np.argmax(aa2)]
    tt = tt - (pcb_center-1)
    
    plt.figure(figsize=(6,7))
    plt.subplot(211)
    plt.plot(tt,aa1,'-o',lw=0.8,markersize=3,label='PCB')
    plt.plot(tt,aa2,'--d',lw=0.8,markersize=3,label='table')
    plt.xlim([0,5])
    plt.ylim([-150000,200000])
    plt.grid(True)
    plt.xlabel('time (ms)')
    plt.ylabel('acceleration (m/s$^2$)')
    plt.legend()
    
    x = np.linspace(-2, 2, 10)
    #ax0 = plt.subplot(211)
    #ax1 = ax0.twinx() # Create a twin of Axes with a shared x-axis but independent y-axis.
    ax2 = plt.subplot(212)
    ax3 = ax2.twinx() # Create a twin of Axes with a shared x-axis but independent y-axis.
    ax3.set_xticks([0,1,2,3,4])
    ax2.set_xticklabels(freq)
    #ax3.set_xlabel(list(frequency))
    #ax1.get_shared_y_axes().join(ax1, ax3)
    #c1, = ax0.plot(x, np.sin(x), c='red')
    #c2, = ax1.plot(x, np.cos(x), c='blue')
    c3, = ax2.plot(Z,'-o',c=cc[2])
    c4, = ax3.plot(theta,'--d',c=cc[3])
    plt.legend([c3, c4], ["Z", "theta"])
    #loc = "upper left", bbox_to_anchor=(.070, 2.25))
    ax2.set_xlabel('frequency (Hz)')
    ax2.set_ylabel('Z (ohm)')
    ax3.set_ylabel('angle (degree)')
    ax2.set_ylim([-5e7,8e8])
    ax3.set_ylim([-92,-78])

    plt.tight_layout()
    # plt.savefig(file_name)