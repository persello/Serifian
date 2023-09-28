#import "Template//eracing-template.typ": *

#show: eracing-template.with(
  title: "How we used Tesla's sponsored material in 2023",
  authors: (),
  lang: "en",
  date: "September 19, 2023",
  small-titles: false,
  light-ratio: 80%  
)
#set align(center)
#figure(
  image("DSC_0585.jpg", width: 70%),
)

#set align(left)
= Battery assembly
To build our segment we used *576 Molicel INR-21700-P42A* cells kindly sponsored to us by Tesla.

#v(10pt)
#set align(center)
#figure(
  image("DSC_0850.jpg", width: 70%),
  caption:"Closeup of our 2023 battery pack during inspections during FSAE Italy"
)
#v(10pt)
#figure(
  image("_DSC0340.jpg", width: 70%),
  caption:"Team members showing a sample of our battery modules during FS Spain Accumulator Scrutineering"
)
#set align(left)


#colbreak()

= BMS Slave and Master
We designed our own custom BMS Slave and Master boards. Using the ESP32 C3 on the master allowed us to implement the same strategy used for the rest of the car: modular ECUs programmed in Rust communicating via CAN bus.

To ensure maximum safety, the BMS master can be communicated with also via *WiFi*, establishing redundancy and protection against CAN failure, and allowing us to monitor voltage, temperature and current readings wirelessly on short range even when the battery is not inside the car.

= Awards and Accomplishments
Thanks to the BMS control and many other features of our fully custom telemetry system, we were awarded with the "*Innovation in the Electronics Development Process*" Award during our stay in Varano De'Melegari for FSAE Italy - we stood on the podium at our very first FSAE/FS competition!
#v(10pt)
#set align(center)
#figure(
image("Figures//IMG-20230717-WA0010.jpg", width: 70%),
  caption: "UNIUD E-Racing Team on the podium of Autodromo Riccardo Paletti of Varano De'Melegari for FSAE Italy"
)
#v(10pt)
#figure(
image("photo_2023-09-26_23-45-28.jpg", width: 70%),
  caption: "UNIUD E-Racing Team on the podium of Circuit De Barcelona-Catalunya for FS Spain"
)
#v(10pt)
#figure(
image("DSC_0400_02.jpg", width: 70%),
  caption: "Our first car, 'Serena I' during the Autocross event in FS Spain"
)