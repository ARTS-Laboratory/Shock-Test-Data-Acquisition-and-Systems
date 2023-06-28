# Data Acquisition - PCB Shock Test Damage
Run instructions

1. Pressurize system
2. Place safety pin into Touch Test
3. Turn Touch Test on
4. Connect trigger banana pins to DMM(Voltage measurement)
5. Make sure PXIe is on
6. Configure auto operation: number of drops, drop height, and set a rest period of 75 seconds
7. Open DataAcquisition.vi in PCBDropTestSystem folder
8. Set the number of drops and add the filepath of the output file to the path textbox. The final element of the filepath must be a .lvm file (C:\Users\localuser\Documents\data.lvm)
9. Turn trigger and BK Meter on
10. Start DataAcquisition.vi
11. Start Auto Operation
12. Run Tests
13. After VI stops, turn off the trigger, Touch Test, and BK Meter, put safety\n pin away, and depressurize system
