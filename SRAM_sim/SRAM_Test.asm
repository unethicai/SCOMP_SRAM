                  ORG 0

                  LOADI 5
                  OUT SRAM_DATA
                  LOADI 6
                  IN SRAM_DATA

                  LOADI 8
                  OUT SRAM_ADDR_BANK0
                  LOADI &H53
                  OUT SRAM_DATA_INCR
                  LOADI &H32
                  OUT SRAM_DATA_DECR
                  IN SRAM_DATA_INCR
                  IN SRAM_DATA


SRAM_ADDR_BANK0:  EQU &H10
SRAM_ADDR_BANK1:  EQU &H11
SRAM_ADDR_BANK2:  EQU &H12
SRAM_ADDR_BANK3:  EQU &H13
SRAM_ADDR_LOW:    EQU &H14
SRAM_ADDR_HIGH:   EQU &H15
SRAM_JUMP_OFFSET: EQU &H16
SRAM_DATA:        EQU &H17
SRAM_DATA_INCR:   EQU &H18
SRAM_DATA_DECR:   EQU &H19