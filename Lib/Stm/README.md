St Lib inkl. Cmsis
==================

* in ihrer jeweiligen aktuellen Version
  - F10x: V3.5.0 (stsw-stm32054.zip)
  - F2xx: V1.1.0 (stsw-stm32062.zip)
  - F4xx: V1.3.0 (stm32f4_dsp_stdperiph_lib.zip)
* für unterschiedliche Stm32 Derivate
* Meine Änderungen:
  - Whitespace Cleanup
    - *.c *.h *.s *.S *.ld
    - Trailing Whitespace entfernt
    - <CR> entfernt
    - Tabs entfernt
  - Schreibschutz von den Dateien entfernt
    - Check : find . -print0 | xargs -0 ls -lda
    - Change: chmod -R +w .
