"""
RadioMultiControl.py

An X-plane plugin that communicates with Arduino hardware via a USB serial
port. The Arduino implements a radio multi-control similar to that in many
X-plane aircraft: two each of navs, coms and adf, with active and standby
frequencies.

This is based on a python example by Sandy Barbour.






This plug-in is licensed under the Simplified BSD License:

Copyright 2011, DaffeySoft. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are
permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of
      conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list
      of conditions and the following disclaimer in the documentation and/or other materials
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY DaffeySoft ``AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL DaffeySoft OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


"""

import serial

from XPLMProcessing import *
from XPLMDataAccess import *
from XPLMUtilities import *

class PythonInterface:
	def XPluginStart(self):
		global gOutputFile, gPlaneLat, gPlaneLon, gPlaneEl
		self.Name = "RadioMulticontrol"
		self.Sig =	"DaffeySoft.Python.RadioMulticontrol"
		self.Desc = "A plugin that communicates to an Arduino radio panel."
		
		self.refresh = 0.15
		self.ser = None

		self.refs_left_txt	= ["sim/cockpit/radios/nav1_freq_hz",
					 "sim/cockpit/radios/nav2_freq_hz",
					 "sim/cockpit/radios/com1_freq_hz",
					 "sim/cockpit/radios/com2_freq_hz",
					 "sim/cockpit/radios/adf1_freq_hz",
					 "sim/cockpit/radios/adf2_freq_hz",
					 ]
		self.refs_right_txt = [
					 "sim/cockpit/radios/nav1_stdby_freq_hz",
					 "sim/cockpit/radios/nav2_stdby_freq_hz",
					 "sim/cockpit/radios/com1_stdby_freq_hz",
					 "sim/cockpit/radios/com2_stdby_freq_hz",
					 "sim/cockpit/radios/adf1_stdby_freq_hz",
					 "sim/cockpit/radios/adf2_stdby_freq_hz",
					 ]
		self.refs_mode = XPLMFindDataRef("sim/cockpit/radios/nav_com_adf_mode")
			
		self.leftf = 0
		self.rightf = 0
		self.mode = 0	
		self.adfCursorPos = 0
				 
				 
		autopilot = {'altitude':'sim/cockpit/autopilot/altitude',
					 'heading':'sim/cockpit/autopilot/heading_mag',
					 'vs':'sim/cockpit/autopilot/vertical_velocity',
					}
					
		self.autopilot_refs = {}
		for key in autopilot:
			self.autopilot_refs[key] = XPLMFindDataRef(autopilot[key]) 

		"""
		Open a file to write to. While debugging, this program wrote to
		a file in its home directory. I've left that in, alternatively
		you could erase every line referring to self.OutputFile.
		"""
		#self.outputPath = XPLMGetSystemPath() + "timedprocessing1.txt"
		self.outputPath = "~/git_code/xplane_radio/timedprocessing1.txt"
		self.OutputFile = open(self.outputPath, 'w')
		
		self.refs_left = []
		for ref in self.refs_left_txt:
			self.refs_left.append(XPLMFindDataRef(ref))
		self.refs_right = []
		for ref in self.refs_right_txt:
			self.refs_right.append(XPLMFindDataRef(ref))
		
		
		"""
		Register our callback for the refresh period specified in XPluginStart.
		"""
		self.FlightLoopCB = self.FlightLoopCallback
		XPLMRegisterFlightLoopCallback(self, self.FlightLoopCB, self.refresh, 0)
		
		'''Open a serial port to the radio panel
		
		If you are porting you'll need to adjust the name of the com port
		to that on your computer. If you have the Arduino application, go 
		Tools-Serial Port and see what is there, and try that. For my computer
		with the particular Arduino I'm using, I see only one /dev/tty.usb
		entry, and that's the one.

		I don't have a Windows PC, but I'm guessing this will be 'COM1' or
		something like that.
		'''
		portname = '/dev/tty.usbmodem26231'
		try:
			self.OutputFile.write('about to open serial\n')
			self.ser = serial.Serial(portname, 115200, timeout = 12)
		except:
			self.ser = None
		
		'''
		Return with info required by plug-in system
		'''
		return self.Name, self.Sig, self.Desc

	def XPluginStop(self):
		# Unregister the callback
		XPLMUnregisterFlightLoopCallback(self, self.FlightLoopCB, 0)

		# Close the file
		self.OutputFile.close()
		if self.ser:
			self.ser.close()


	def XPluginEnable(self):
		return 1

	def XPluginDisable(self):
		pass

	def XPluginReceiveMessage(self, inFromWho, inMessage, inParam):
		pass

	def FlightLoopCallback(self, elapsedMe, elapsedSim, counter, refcon):
		mode = XPLMGetDatai(self.refs_mode)
		if mode != self.mode:
			line = 'M%d\n' % (mode,)
			self.OutputFile.write(line)
			self.serialWrite(line)
			if ((self.mode<4) and (mode>4)):
				line = 'C%d\n' % (self.adfCursorPos)
				self.OutputFile.write(line)
				self.serialWrite(line)
			if ((self.mode>4) and (mode<4)):
				self.serialWrite("C0\n")
				self.OutputFile.write("C0\n")
			self.mode = mode
			
		leftf = XPLMGetDatai(self.refs_left[mode])
		if leftf != self.leftf:
			line = 'L%d\n' % (leftf,)
			self.OutputFile.write(line)
			self.leftf = leftf
			self.serialWrite(line)

		rightf = XPLMGetDatai(self.refs_right[mode])
		if rightf != self.rightf:
			line = 'R%d\n' % (rightf,)
			self.OutputFile.write(line)
			self.rightf = rightf
			self.serialWrite(line)
		self.OutputFile.flush()

		line = ''
		if self.ser:
			while self.ser.inWaiting():
				line += str(self.ser.read(1))
			if len(line)>=3:
				if line[0]=='S':
					value = line[1]
					if (value>='0') and (value<='5'):
						XPLMSetDatai(self.refs_mode, int(value))
					elif value=='S':
						XPLMSetDatai(self.refs_left[mode], rightf)
						XPLMSetDatai(self.refs_right[mode], leftf)
					elif (value =='P') or (value =='M') or (value=='U') or (value=='D'):
						if mode <4:
							if mode < 2:
								minf = 108
								maxf = 117
							elif mode <4:
								minf = 118
								maxf = 136
							else:
								minf = 0
								maxf = 9 
							if value == 'P':
								if (rightf % 100) <95:
									incr = 5
								else:
									incr = -95
							elif value == 'U':
								incr = 100
							elif value == 'M':
								if (rightf % 100) > 4:
									incr = -5
								else:
									incr = 95
							elif value =='D':
								incr = -100
							if rightf / 100 >maxf:
								rightf = minf * 100 + (rightf % 100)
							if rightf / 100 < minf:
								rightf = maxf * 100 + (rightf % 100)
							XPLMSetDatai(self.refs_right[mode], rightf+incr)
						else:		# ADF modes
							if (value == 'U') or (value =='D'):
								if value == 'U':
									self.adfCursorPos = (self.adfCursorPos + 1) % 4
								if value == 'D':
									self.adfCursorPos = (self.adfCursorPos - 1) % 4
								line = 'C%d\n' % (self.adfCursorPos,)
								self.OutputFile.write(line)
								self.serialWrite(line)
							if ((value == 'P') or (value=='M')) and (self.adfCursorPos>0):
								cursorPos = self.adfCursorPos
								fstring = "%03d" % rightf
								before = fstring[0:cursorPos-1]
								after = fstring[cursorPos:]
								digit = int(fstring[cursorPos-1:cursorPos])
								if value == 'P':
									digit = (digit+1) % 10
								if value == 'M':
									digit = (digit-1) % 10
								fstring = before + str(digit) + after
								freq = int(fstring)
								if freq<190:
									freq = 190
								XPLMSetDatai(self.refs_right[mode], freq)
								
		return self.refresh
		
		
	def serialWrite(self, line):
		if self.ser:
			for c in line:
				self.ser.write(c)

