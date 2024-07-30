/* Define the memory regions */
MEMORY
{
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 10M
    IN (rwx) : ORIGIN = 0x30000000, LENGTH = 1M
}

/* Define the sections */
SECTIONS
{
    . = ORIGIN(RAM);

    /* Code and read-only data */
    .text : ALIGN(4)
    {
        *(.text.init)
        *(.text*)
        *(.rodata*)
    } > RAM

    /* Initialized data */
    .data : ALIGN(4)
    {
        *(.data*)
    } > RAM

    /* Uninitialized data */
    .bss : ALIGN(4)
    {
        *(.bss)
        *(COMMON)
    } > RAM

    /* Small uninitialized data */
    .sbss : ALIGN(4)
    {
        *(.sbss*)
    } > RAM

    /* Stack section */
    .stack (NOLOAD) : ALIGN(4)
    {
        __sp = . + 0x10000;  /* Adjust stack size as needed */
        . = .;               /* Keep location counter at the end of stack */
    } > RAM

    /* Heap section */
    .heap (NOLOAD) : ALIGN(4)
    {
        HEAP = .;
        . = . + 1048576;  /* Heap size */
    } > RAM

    /* Custom sections */
    .in_name_len (NOLOAD) : ALIGN(1)
    {
        . = ORIGIN(IN);
        IN_FUNC_NAME_LEN = .;
        . = . + 4;
    } > IN

    .in_name (NOLOAD) : ALIGN(1)
    {
        IN_FUNC_NAME = .;
        . = . + 255;
    } > IN

    .in_args_len (NOLOAD) : ALIGN(1)
    {
        IN_FUNC_ARGS_LEN = .;
        . = . + 4;
    } > IN

    .in_args (NOLOAD) : ALIGN(1)
    {
        IN_FUNC_ARGS = .;
        . = . + 10240;  /* Set args max length */
    } > IN

    /* End of the data section */
    _end = .;

    /* Discard sections to minimize binary size */
    /DISCARD/ : {
        *(.eh_frame)
        *(.comment)
        *(.debug*)
        *(.note*)
        *(.symtab)
        *(.strtab)
        *(.riscv.attributes)
    }
}
