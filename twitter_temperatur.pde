#if defined(ARDUINO) && ARDUINO > 18   // Arduino 0019 or later
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDNS.h>
#include <Twitter.h>
#include <DS18S20.h>

DS18S20_List ds18s20(2);
#define ID_OUTSIDE 0xC65F

// Ethernet Shield Settings
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };

// substitute an address on your own network here
byte ip[] = { 192,168,178,35 };

// Your Token to Tweet (get it from http://arduino-tweet.appspot.com/)
Twitter twitter("...");

// Google spreadsheet issues
char formkey[] = "dGg5SHB3aGRYMUVRYWE1N3lZTW8yOGc6MQ";
byte server[] = { 209,85,229,101 }; // Google IP
Client client(server, 80);

boolean once;

void setup()
{
  once = true; 
  pinMode(9, OUTPUT);     

  delay(1000);
  Ethernet.begin(mac, ip);
  Serial.begin(9600);
  Serial.print("Sensors found: ");
  Serial.println(ds18s20.count,DEC);

  Serial.println("connecting ...");
}

void loop()
{
  Serial.println();
  delay(1000);
  ds18s20.update(); 

  for (int i=0;i<ds18s20.count;i++)
  {
    Serial.print("Sensor ");
    Serial.print(i,DEC);
    Serial.print(", id=0x");
    Serial.print(ds18s20.get_id(i),HEX);
    Serial.print(", T=");
    Serial.print(ds18s20.get_temp(i));
    Serial.println("C");
  }

  float T_outside=ds18s20.get_temp_by_id(ID_OUTSIDE);

  once = false;
  Serial.print("Outside temperature: ");
  print_temperature(T_outside);
  Serial.println("C");

  digitalWrite(9, HIGH);

  // Message to post
  char msg[100];
  char tmp_in[10];
  char tmp_out[10];

  ftoa(tmp_in, (double)ds18s20.get_temp(0), 2);
  ftoa(tmp_out, (double)ds18s20.get_temp(1), 2);
 
  sprintf(msg, "Interne Temperatur: %s C Externe Temperatur: %s C. #Arduino", tmp_in, tmp_out);
  Serial.println(msg);
 
  String data;
  data+="";
  data+="entry.0.single=";
  data+=tmp_in;
  data+="&entry.2.single=";
  data+=tmp_out;
  data+="&submit=Submit";
 
  Serial.println("Start connecting the internet...");
  if (client.connect()) {
    Serial.println("connected");

    client.print("POST /formResponse?formkey=");
    client.print(formkey);
    client.println("&ifq HTTP/1.1");
    client.println("Host: spreadsheets.google.com");
    client.println("Content-Type: application/x-www-form-urlencoded");
    client.println("Connection: close");
    client.print("Content-Length: ");
    client.println(data.length());
    client.println();
    client.print(data);
    client.println();

    Serial.print("POST /formResponse?formkey=");
    Serial.print(formkey);
    Serial.println("&ifq HTTP/1.1");
    Serial.println("Host: spreadsheets.google.com");
    Serial.println("Content-Type: application/x-www-form-urlencoded");
    Serial.println("Connection: close");
    Serial.print("Content-Length: ");
    Serial.println(data.length());
    Serial.println();
    Serial.print(data);
    Serial.println();

  }
  delay(1000);
  client.stop();
  if (false) { //!client.connected()) {
    Serial.println();
    Serial.println("disconnecting.");
    client.stop();
  }
  
  if (once)
  {
    Serial.println("Start Twittering...");
    if (twitter.post(msg)) {
      // Specify &Serial to output received response to Serial.
      // If no output is required, you can just omit the argument, e.g.
      // int status = twitter.wait();
      Serial.println("Send Tweet...");
      int status = twitter.wait(&Serial);
      if (status == 200) {
        Serial.println("OK.");
      } 
      else {
        Serial.print("failed : code ");
        Serial.println(status);
      }
    } 
    else {
      Serial.println("connection failed.");
    }
  }
  digitalWrite(9, LOW);

  delay (5000); // 2 Stunden Jan delay (7200000);

  return;
}

char *ftoa(char *a, double f, int precision)
{
  long p[] = {0,10,100,1000,10000,100000,1000000,10000000,100000000};
  
  char *ret = a;
  long heiltal = (long)f;
  itoa(heiltal, a, 10);
  while (*a != '\0') a++;
  *a++ = '.';
  long desimal = abs((long)((f - heiltal) * p[precision]));
  itoa(desimal, a, 10);
  return ret;
}

