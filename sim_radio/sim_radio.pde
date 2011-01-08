/*
This is a simple Arduino sketch to implement a radio panel for
X-plane. It uses one line of a 16 x 2 LCD dislay, and a 4x4 matrix
keyboard. All the brains is in the X-plane plugin.

This is running on an Arduino Uno, has been tested on a Duemilanove,
and should run on any similar Arduino.

Note that on an Arduino, the Analog pins map to digital pins 14+. This
code uses the analog pins to support the keypad.

Check out the pin definitions in the code to see what's connected where.


This code is licensed under the Simplified BSD License:

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
*/

#include <Keypad.h>
#include <Wire.h>
#include "lc_display.h"
#include "stdlib.h"

#define LINE_BUFFER_SIZE 20
char line[LINE_BUFFER_SIZE];
uint8_t char_counter;
char Verbose = 0;

long freqs[2];
int cursor_pos=0;
int mode=0;
		
int loop_counter=0;
int switch_index=0;

const byte ROWS = 4; //four rows
const byte COLS = 4; //three columns
char keys[ROWS][COLS] = {
  {'P','U','S', '_'},
  {'M','D','_', '_'},
  {'0','2','4', '_'},
  {'1','3','5', '_'}
};
byte rowPins[ROWS] = {14, 15, 16, 17}; //connect to the row pinouts of the keypad
byte colPins[COLS] = {4, 5, 6, 7}; //connect to the column pinouts of the keypad

Keypad keypad = Keypad( makeKeymap(keys), rowPins, colPins, ROWS, COLS );



void setup()
{
  Serial.begin(115200);           // start serial for output
  if (Verbose==1) Serial.print("\nRadio panel interface\r\n");
  lcd_init();
  freqs[0]=12270;
  freqs[1]=11950;
  cursor_pos=0;
  mode=0;
  lcd_setup();
  
  lcd_report_freqs_right();
  lcd_report_freqs_left();
  lcd_report_mode();
  lcd_report_cursor();
}


void loop()
{

  
//  delay(50);
//  lcd_report_position();
  if (Serial.available()) sp_process();

  char key = keypad.getKey();
  
  if (key != NO_KEY){
    Serial.print("S");
    Serial.println(key);
  }

  delay(10);
}


void sp_process()
{

  char c;
  uint8_t status;
  long value;

// Only gets processed if there is something waiting on the serial port:
  while((c = Serial.read()) != -1) 
  {
  	// Echo sent characters if required:
  	if (Verbose==1) {
            Serial.print(c);		
	    if (c == '\r') {
              Serial.print('\n');
            }
         }
	
    if((char_counter > 0) && ((c == '\n') || (c == '\r'))) {  // Line is complete. Then execute!
      line[char_counter] = 0;
      char_counter=0;
      
      if (Verbose==1) Serial.println(line);
      
      //Process line:
     value = atoi(&line[1]);
     if (Verbose==1){
       Serial.print("Value: ");
       Serial.println(value);
     }
 
      if (line[0]=='L'){
        freqs[0]=value;
        lcd_report_freqs_left();
      }

      if (line[0]=='R'){
        freqs[1]=value;
        lcd_report_freqs_right();
        lcd_report_cursor();
      }
      
      if (line[0]=='M'){
        mode = value;
        lcd_report_mode();
      }
      if (line[0]=='C'){
        cursor_pos = value;
        lcd_report_cursor();
      }
    } else if (c <= ' ') { // Throw away whitepace and control characters
    } else if (c >= 'a' && c <= 'z') { // Upcase lowercase
      line[char_counter++] = c-'a'+'A';
    } else {
      line[char_counter++] = c;
    }
  }
}


