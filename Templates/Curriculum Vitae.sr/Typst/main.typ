#show heading: set text(font: "Linux Biolinum")

#show link: underline
#set page(
 margin: (x: 0.9cm, y: 1.3cm),
)
#set par(justify: true)

#let chiline() = {v(-3pt); line(length: 100%); v(-5pt)}

= Riccardo Persello

riccardo.persello\@icloud.com |
#link("https://github.com/persello")[github.com/persello] | #link("https://www.linkedin.com/in/riccardo-persello")[linkedin.com/in/riccardo-persello]

== Education
#chiline()

*University of Udine* #h(1fr) 2019/10 -- present \
Bachelor's degree in Electronics Engineering #h(1fr) Udine, Italy \
- Computer science and networking curriculum with courses in web development, operating systems, software analysis and design, C++ and VHDL development, in addition to the regular Electronics courses.

*ISIS Arturo Malignani* #h(1fr) 2014/09 -- 2019/07 \
High school diploma in Electronics #h(1fr) Udine, Italy \
- Participated in the Italian National Electronics competition - 2nd place.
- Siemens PLC training course (ladder logic).

== Work Experience
#chiline()

*DM Elektron* #h(1fr) 2018/04 -- 2018/06 \
Hardware/firmware tester #h(1fr) Buja, Italy \
- Debugging of a portable, battery powered device, with days-long power consumption analysis.
- On-line management portal device integration tests.

*DM Elektron* #h(1fr) 2017/04 -- 2017/06 \
Electronic components database entry clerk #h(1fr) Buja, Italy

== Projects
#chiline()

*UNIUD E-Racing Team* #h(1fr) 2021/11 -- present \
Formula SAE / Formula Student #h(1fr) Udine, Italy \
- Lead the launch of the electronics department in the first Formula SAE team at the University of Udine, evaluating and choosing software, hardware and development technologies for on-board systems and vehicle telemetry. Managed the unit for one year.
- Rust developer for on-board systems (code-generated messaging library and BMS firmware), and for local and server-side software (Rust with a web frontend, Docker containers).

*pulse.loop* #h(1fr) 2022/03 -- 2023/05 \
Development of open-source firmware and software for a wrist-worn pulse oximetry device #h(1fr) Udine, Italy \
- Developed a SwiftUI multiplatform companion app for configuring and viewing real-time data from the device.
- Developed two libraries for simplifying the usage of client and server Bluetooth LE stacks. Bluedroid is a safe Rust wrapper for the homonym embedded C library, and CharacteristicKit is a Swift package that uses metaprogramming concepts to simplify the modelling of BLE peripherals over CoreBluetooth.
- Built a showcase website for the project (Svelte + Tailwind).

*Swift Student Challenge* #h(1fr) 2021, 2022 \
Won two editions of the Apple Swift Student Challenge
- In 2021, I developed a library for solving linear circuits using the Modified Nodal Analysis method, using Accelerate to manipulate matrices.
- In 2022, I developed a playground that showcased data transmission over sound waves, using multi-tone multi-frequency modulation.

#let name(params) = output