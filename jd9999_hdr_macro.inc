; JD_9999's PE32+ header blueprint for the UEFI apps. Turned it into a NASM macro, that makes it utilizable in pretty much any UEFI app.

; %1 - size of the code segment
; %2 - size of the data segemnt
; %3 - image entry address
; %4 - Image size
%macro jd9999_hdr_macro 4

section .header
DOS_HEADER:
   dw 0x5a4d ;DOS Magic number
   times 29 dw 0 ;Zeroes
   dd 0x00000080 ;Address of PE header

DOS_STUB:
   ; I don't know how to write this as text, so you get zeroes
   times 32 dw 0

PE_HEADER:
   dd 0x00004550 ;PE Magic number
   dw 0x8664 ;Building for x86 architecture
   dw 2 ;Two sections (.text, .data)
   dd 0x5ed4b58 ;number of seconds between 00:00:00 1st January 1970 and 00:00:00 1st July 2021
   dd 0x0 ;No symbol table
   dd 0x0 ;No symbols in the non-existent symbol table!
   dw oSize ;The size of the entire optional header. See the OPTIONAL_HEADER_END label for the calculation.
   dw 0x1002 ;Is a valid image file, is a system file. No other fancy characteristics.

oSize equ OPTIONAL_HEADER_END - OPTIONAL_HEADER_STANDARD_FIELDS

OPTIONAL_HEADER_STANDARD_FIELDS: ;Not actually optional
   dw 0x020b ;PE32+ Executable. I want my 64-bit registers!
   dw 0x0 ;What linker?
   dd %1 ;The size of the code segment
   dd %2 ;The size of the data segment
   dd 0x0 ;No .bss section. All variables to be initialised.
   dd 1024 ;The program's entry point
   dd 1024 ;The program's first instruction. Same as the start of the code execution. Duh.

OPTIONAL_HEADER_WINDOWS_FIELDS: ;This is required for UEFI applications too. Trust me, plenty of debugging went into that discovery.
   dq %3 ;The entry point of the image
   dd 0x1024 ;The section alignment
   dd 0x1024 ;The file alignment
   dw 0x0 ;No operating system requirements
   dw 0x0 ;Still no operating system requirements
   dw 0x0 ;Major image version number
   dw 0x1 ;Minor image version number
   dw 0x0 ;Major subsystem version. Doesn't matter, as long as it supports UEFI.
   dw 0x0 ;Minor subsystem version. Doesn't matter, as long as it supports UEFI.
   dd 0x0 ;A dedicated zero
   dd %4 ;Image size
   dd 1024 ;Header size
   dd 0x0 ;Checksum //TODO ADD LATER
   dw 0x000A ;UEFI Subsystem number.
   dw 0x0 ;Not a DLL, so this can be zero

   ;Using PE32+ file type, so the following are dqs, not dds
   dq 0x8000 ;Amount of stack space to reserve
   dq 0x8000 ;Amount of stack space to commit immediately
   dq 0x8000 ;Amount of local heap space to reserve
   dq 0x0 ;Amount of local heap space to commit immediately. Hopefully not needed.
   dd 0x0 ;Another four bytes dedicated to being zeroes
   dd 0x0 ;Number of data dictionary entries

;OPTIONAL_HEADER_DATA_DIRECTORIES: ;We don't have any special sections, so we don't need this header!

OPTIONAL_HEADER_END: ;This label is required for calculating value of oSize

SECTION_TABLE: ;as if you don't have enough information already :\
.1: ;text section
   dq `.text` ;The name of the text section
   dd %1 ;virtual size.
   dd 1024 ;virtual entry point address.
   dd %1 ;actual size.
   dd 1024 ;actual entry point address.
   dd 0 ;No relocations
   dd 0 ;No line numbers
   dw 0 ;No relocations
   dw 0 ;No line numbers
   dd 0x60000020 ;Contains executable code, can be executed as code, can be read.

.2: ;data section
   dq `.data` ;The name of the data section
   dd %2 ;virtual size.
   dd 1024+%1 ;virtual entry point address.
   dd %2 ;actual size.
   dd 1024+%1 ;actual entry point address.
   dd 0 ;No relocations
   dd 0 ;No line numbers
   dw 0 ;No relocations
   dw 0 ;No line numbers
   dd 0xc0000040 ;Contains initialised data, can be read, can be written to.

times 1024 - ($-$$) db 0 ;alignment

%endmacro