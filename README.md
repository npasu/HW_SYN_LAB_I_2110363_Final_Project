# HW_SYN_LAB_I_2110363_Final_Project
Hardware Synthesis Laboratory I - 2110363 Final Project By B2

This project implements a realtime video processing system on the Basys 3 FPGA board. It captures live video from an OV7670 camera sensor, stores the frame data in Block RAM, processes the image through hardware-based filters, and displays the result on a monitor via VGA.

## System Architecture
- Clock Management : Utilizes the Clocking Wizard IP to generate synchronized frequencies.
- Camera Interface
  - SCCB Master : Camera Configuration
  - OV7670 Capture: 'VSYNC' and 'HREF' signals detection
- Memory System : True Dual-Port BRAM
- Processing & Display : 320x240 and 640x480 versions
  - VGA Controller : Generates standard sync signals.
  - Filter Engine : Applies real-time image effects.
    - 'SW0' → Grayscale filter
    - 'SW1' → Blue channel only filter
    - 'SW2' → Green channel only filter
    - 'SW3' → Red channel only filter
    - 'SW0'+'SW1'+'SW2'+'SW3' → Color invertion filter

## Source Code
- 320px version → [final_project_320_240](./final_project_320_240/final_project_320_240.srcs)
- 640px version → [final_project_640_480](./final_project_640_480/final_project_640_480.srcs)
