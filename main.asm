[BITS 64]
[DEFAULT ABS]
[ORG 0x00100000]

%include "jd9999_hdr_macro.inc"  ; Windows PE32+ header implementation by JD9999, that I turned into a macro.

jd9999_hdr_macro textsize, datasize, 0x00100000, textsize+datasize+1024

section .text follows=.header
   sub rsp, 6*8+8 ; Copied from Charles AP's implementation, fix stack alignment issue (Thanks Charles AP!)

   mov qword [EFI_HANDLE], rcx           ; Handover variables 
   mov qword [EFI_SYSTEM_TABLE], rdx

   mov rax, qword [EFI_SYSTEM_TABLE]
   mov rax, qword [rax+96]
   mov rax, qword [rax+56]
   mov qword [EFI_GET_MMAP], rax ; void* EFI_GET_MMAP = EFI_SYSTEM_TABLE->EFI_BOOT_SERVICES->EFI_GET_MEMORY_MAP

   mov rax, qword [EFI_SYSTEM_TABLE]
   mov rax, qword [rax+96]
   mov rax, qword [rax+320]
   mov qword [EFI_LOCATE_PROTOCOL], rax ; void* EFI_LOCATE_PROTOCOL = EFI_SYSTEM_TABLE->EFI_BOOT_SERVICES->EFI_LOCATE_PROTOCOL

   mov rax, qword [EFI_SYSTEM_TABLE]
   mov rax, qword [rax+96]
   mov rax, qword [rax+232]
   mov qword [EFI_EXIT_BOOT_SERVICES], rax ; void* EFI_EXIT_BOOT_SERVICES = EFI_SYSTEM_TABLE->EFI_BOOT_SERVICES->EFI_EXIT_BOOT_SERVICES





   mov rcx, EFI_GOP_GUID ; arg1 - pointer to the GOP GUID
   mov rdx, 0            ; arg2 - optional registration key
   mov r8, EFI_GOP       ; arg3 - a pointer that will point to a _EFI_GRAPHICS_OUTPUT_PROTOCOL struct on return
   sub rsp, 32
   call qword [EFI_LOCATE_PROTOCOL] 
   add rsp, 32

   mov rax, qword [EFI_GOP]
   mov rcx, qword [EFI_GOP] ; arg1 - pointer to _EFI_GRAPHICS_OUTPUT_PROTOCOL
   mov rdx, 0               ; arg2 - video mode id
   sub rsp, 32
   call qword [rax+8]       ; Set video mode by calling _EFI_GRAPHICS_OUTPUT_PROTOCOL->EFI_GRAPHICS_OUTPUT_PROTOCOL_SET_MODE 
   add rsp, 32

   mov rax, qword [EFI_GOP]
   mov rax, qword [rax+24]
   mov rax, qword [rax+24]
   mov qword [framebuff_addr], rax  ; framebuff_addr = _EFI_GRAPHICS_OUTPUT_PROTOCOL->Mode->FrameBufferBase



   call_mmap:

   mov rcx, mm_sz  ; arg1 - pointer to the size of the buffer, we supplied to the get_mmap 
   mov rdx, mmap   ; arg2 - pointer to the mmap buffer
   mov r8, mmkey   ; arg3 - in mmkey, get_mmap will return the current mmap's key on success
   mov r9, mmdsz   ; arg4 - in mmdsz, get_mmap will return the size of EFI_MEMORY_DESCRIPTOR on success
   mov r10, mmdsv  ; arg5 - in mmdsv, get_mmap will return the version number, associated with EFI_MEMORY_DESCRIPTOR on success
   sub rsp, 32
   call qword [EFI_GET_MMAP] 
   add rsp, 32

   and rax, rax  ; since the mm_sz is 0, get_mmap will fail the first time we call it. 
   jnz call_mmap ; But upon failing, it will put the desired buffer size into mm_sz, so, the second call should be successful and return 0.

   mov rcx, qword [EFI_HANDLE] ; arg1 - EFI_HANDLE handover variable 
   mov rdx, qword [mmkey]      ; arg2 - mmkey, we got from get_mmap
   sub rsp, 32
   call qword [EFI_EXIT_BOOT_SERVICES]
   add rsp, 32

   and rax, rax ; if exit_boot_services failed, we jump to the program stall sequence right away
   jnz end      ; if it did not, we first put some pixels on the screen to indicate our success and only then stall.

   cld
   mov rdi, qword [framebuff_addr]
   mov eax, 0x22822833              ; some random pixel color
   mov rcx, 0x2223                  ; some random amount of pixels
   rep stosd

   end:

   cli
   hlt  ; stall indefinitely 


   times 1024 - ($-$$) db 0 ;alignment
   textsize equ $-$$

section .data follows=.text
   EFI_HANDLE dq 0
   EFI_SYSTEM_TABLE dq 0

   EFI_GET_MMAP dq 0
   EFI_LOCATE_PROTOCOL dq 0
   EFI_EXIT_BOOT_SERVICES dq 0

   EFI_GOP_GUID:
      dd 0x9042a9de
      dw 0x23dc
      dw 0x4a38
      db 0x96
      db 0xfb
      db 0x7a
      db 0xde
      db 0xd0
      db 0x80
      db 0x51
      db 0x6a

   EFI_GOP dq 0

   mm_sz dq 0
   mmkey dq 0
   mmdsz dq 0
   mmdsv dq 0

   framebuff_addr dq 0


times 1024 - ($-$$) db 0 ;alignment

mmap:               ; mmap buffer. The better way of implementing the get_mmap call is to dynamically allocate our buffer using UEFI services after the first call to get_mmap.
    times 4096 db 0 ; But I simply assumed, that 4096 bytes will be enough to fit our mmap.

    datasize equ $-$$   