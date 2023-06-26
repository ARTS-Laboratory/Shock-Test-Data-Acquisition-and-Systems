class ParseData:
  #This function takes in the large output file
  #from the PCB drop test VI and parses it into formatted data
  def parse():
    fileOutName = r"C:\Users\localuser\Documents\goshorna\Project 1\Data\acc_data_"
    inputFile = open(r"C:\Users\localuser\Documents\goshorna\Project 1\Data\data.lvm")#Add the file name before running
    accParity = 0 #Acceleration parity (was last line an acceleration measurement
    fileNum = 0
    timeOffset = 0
    fileOut = fileOutName + str(fileNum) + ".txt"
    f = open(fileOut, "w")
    fileNum += 1

    for line in inputFile:
     fileOut = fileOutName + str(fileNum) + ".txt"
     commaExists = line.find(",");#commaExists and accParity are used to determine the start and end of the outfiles
     if commaExists == -1 and accParity == 0:#End of impedance measurements, start new file
      f.close()
      f = open(fileOut, "w")
      i = line.index(".") + 7
      timeOffset = float(line[0: i])
      line2 = line.replace(line[0: i], "0.0000000")
      f.write(line2)
      fileNum += 1
      accParity = 1
     elif commaExists == -1 and accParity == 1:#Reading acceleration measurement lines, adjust time
      i = line.index(".") + 7
      newTime = float(line[0: i]) - timeOffset
      rTime = ("%.7f" % newTime)#formats time to 7 decimal points
      line2 = line.replace(line[0: i], str(rTime))
      f.write(line2)
     elif commaExists != -1 and accParity == 1:#End of acceleration measurements, change accParity
      f.write(line)
      accParity = 0
     else:
      f.write(line)
  
    f.close()
    inputFile.close()

