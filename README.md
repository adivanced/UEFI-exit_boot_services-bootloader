# UEFI-exit_boot_services-bootloader
An example of a UEFI bootloader with an exit_boot_services call, written in NASM.

It is a pretty much minimal working example, but also includes some code for UEFI GOP, needed for signaling that the program executed exit_boot_services successfully. 

After running the ```make``` utility, you will have the BOOTX64.EFI executable. In order to run it, format your USB drive to FAT32. Create a /EFI/BOOT/ on your disk and put your BOOTX64.EFI into the /EFI/BOOT directory. Get to the UEFI firmware settings and disable the secure boot option, then put your USB drive on the top of the boot priority list.

If the program drew a row of pixels on your screen, then it worked properly and exit_boot_services returned 0.

Note that this program will probably not work qemu because of the call to exit_boot_services. 

Note that this implementation is basic and lacks some error handling and memory_map buffer dynamic allocation.
