/*
lc_display

Implements some simple functions for the LCD display. Could be in
the main sketch, but ended up in a different file for historial 
reasons.

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


//*************************************************************************************
// include the library code:
#include <LiquidCrystal.h>

// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(LCD_RS, LCD_ENABLE, LCD_DB0, LCD_DB1, LCD_DB2, LCD_DB3);

// Some special characters, basically small letters used to display
// which radio the panel is currently controlling.
#define NAV 0
#define COM 1
#define ADF 2
#define ONE 3
#define TWO 4

byte adf[8] = {
  B00000,
  B00000,
  B00110,
  B01001,
  B01111,
  B01001,
  B01001,
};

byte nav[8] = {
  B00000,
  B00000,
  B01001,
  B01101,
  B01111,
  B01011,
  B01001,
};
byte com[8] = {
  B000000,
  B000000,
  B000110,
  B001001,
  B001000,
  B001001,
  B000110,
};
byte two[8] = {
  B00000,
  B00000,
  B01100,
  B10010,
  B00100,
  B01000,
  B11110,
};
byte one[8] = {
  B00000,
  B00000,
  B01000,
  B11000,
  B01000,
  B01000,
  B11100,
};



extern long freqs[2];		
extern int cursor_pos;
extern int mode;


int pos_line=0;

//extern "C" void lcd_report_position();
//extern "C" void lcd_init();

void lcd_setup(void)
{
  lcd.createChar(NAV,nav);
  lcd.createChar(COM,com);
  lcd.createChar(ADF,adf);
  lcd.createChar(ONE,one);
  lcd.createChar(TWO,two);
  
}

void lcd_print_char(char character)
{
	lcd.print(character);
}

void lcd_print_long(long num)
{
	lcd.print(num);
}
void lcd_print_str(char * line)
{
	lcd.print(line);
}


void lcd_init() {
  // set up the LCD's number of columns and rows: 
  lcd.begin(16, 2);
  pinMode(13,OUTPUT);
  digitalWrite(13, HIGH);
}


void lcd_print_freq(long freq)
{
    long whole;
    long fraction;

   if (freq > 9000) {
     // It's a VHF frequency in 10 kHz steps:
      whole = freq/100;
      fraction = freq  % 100;     
      lcd.print(whole);
      lcd.print('.');
      if (fraction<10){
        lcd.print('0');
      }
      lcd.print(fraction);
     
   } else {
     // It's an ADF frequency in Hz:
        if (freq<100) lcd.print("0");
        if (freq<10) lcd.print("0");
	lcd.print(freq);
        lcd.print("   ");
   }  
 } 


void lcd_report_freqs(void)
{

// Only report 1 of X, Y or Z position per time, allows time for other
// stuff to happen (ie doesn't hog the main thread for too long.

	switch (pos_line){
	case 0:  lcd.setCursor(0, 1);
			 lcd_print_freq(freqs[0]);
                          break;
	case 1:  lcd.setCursor(10, 1);
			 lcd_print_freq(freqs[1]);
			 break;
	}
	pos_line++;
	if (pos_line>1) pos_line=0;
}
void lcd_report_freqs_left(void)
{
  lcd.setCursor(0, 1);
  lcd_print_freq(freqs[0]);
}
void lcd_report_freqs_right(void)
{
  lcd.setCursor(10, 1);
  lcd_print_freq(freqs[1]);
}

void lcd_report_mode(void)
{
  lcd.setCursor(7,1);
  switch (mode){
  case 0:
     lcd.write(NAV);
     lcd.write(ONE);
     break;
  case 1:
     lcd.write(NAV);
     lcd.write(TWO);
     break;
  case 2:
     lcd.write(COM);
     lcd.write(ONE);
     break;
  case 3:
     lcd.write(COM);
     lcd.write(TWO);
     break;
  case 4:
     lcd.write(ADF);
     lcd.write(ONE);
     break;
  case 5:
     lcd.write(ADF);
     lcd.write(TWO);
     break;
 }
 if ((mode==5)||(mode==4)){
     lcd_report_cursor();
   } else {
     lcd.noCursor();
   }
}

void lcd_report_cursor(void)
{
  if (cursor_pos>0){
    lcd.cursor();
    lcd.setCursor(9+cursor_pos,1);
  } else {
    lcd.noCursor();
  }
  
}


