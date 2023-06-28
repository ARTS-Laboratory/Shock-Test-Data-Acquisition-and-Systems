# Data Acquisition - PCB Shock Test Damage
Run instructions\n

1. Pressurize system\n
2. Place safety pin into Touch Test\n
3. Turn Touch Test on\n
4. Connect trigger banana pins to DMM(Voltage measurement)\n
5. Make sure PXIe is on\n
6. Configure auto operation: number of drops, drop height, and set a rest period of 75 seconds\n
7. Open DataAcquisition.vi in PCBDropTestSystem folder\n
8. Set the number of drops and add the filepath of the output file to the path textbox. The final element of the filepath must be a .lvm\n file (C:\Users\localuser\Documents\data.lvm)\n
9. Turn trigger and BK Meter on\n
10. Start DataAcquisition.vi\n
11. Start Auto Operation\n
12. Run Tests\n
13. After VI stops, turn off the trigger, Touch Test, and BK Meter, put safety\n pin away, and depressurize system\n
