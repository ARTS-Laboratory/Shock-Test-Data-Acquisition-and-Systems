# Data Acquisition - PCB Shock Test Damage
Run instructions\n

1. Pressurize system\n
2. Place safety pin into Touch Test\n
3. Turn Touch Test on\n
4. Connect trigger banana clips to DMM(Voltage measurement)\n
5. Make sure PXIe is turned on\n
6. Configure auto operation and drop height\n
7. Open DataAcquisition.vi in PCBDropTestSystem\n
8. Set the number of drops and add the filepath of the output file to the path\n textbox. The final element of the filepathmust be a .lvm file\n (C:\Users\localuser\Documents\data.lvm)\n
9. Turn trigger on\n
10. Start DataAcquisition.vi\n
11. Start Auto Operation\n
12. Run Tests\n
13. After VI stops, turn off the trigger and Touch Test, put safety pin away,\n and depressurize system\n