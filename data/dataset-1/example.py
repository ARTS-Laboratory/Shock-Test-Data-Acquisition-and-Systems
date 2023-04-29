import json
import matplotlib.pyplot as plt
import numpy as np
"""
Load data from a file and make plots
"""

test_index = 2

name = 'test%d.json'%test_index

with open(name) as f:
    data_dict = json.load(f)
    f.close()
print("keys: ")
for key in data_dict.keys():
    print(key)
#%% extract data
t = np.array(data_dict['time'])
acc1 = np.array(data_dict['accelerometer_1'])
acc2 = np.array(data_dict['accelerometer_2'])
#%% make a plot
g = np.logical_and(t>.022, t<.035)
t_ms = (t[g] - t[g][0])*1000
acc1_plt = acc1[g]
acc2_plt = acc2[g]

plt.figure(figsize=(6,3))
plt.plot(t_ms, acc1_plt, label='PCB')
plt.plot(t_ms, acc2_plt, label='table')
plt.ylabel('acceleration (m/s$^2$)')
plt.xlabel('time (ms)')
plt.xlim((t_ms[0], t_ms[-1]))
plt.legend()
plt.grid(True)
plt.tight_layout()
