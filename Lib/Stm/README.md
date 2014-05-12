St Lib inkl. Cmsis
==================

* in ihrer jeweiligen aktuellen Version
  - F10x: V3.5.0 (stsw-stm32054.zip)
  - F2xx: V1.1.0 (stsw-stm32062.zip)
  - F4xx: V1.3.0 (stm32f4_dsp_stdperiph_lib.zip)
* für unterschiedliche Stm32 Derivate
* Meine Änderungen:
  - Whitespace Cleanup
    - *.h, *.c, *.s, *.S, *.ld
    - *.txt
    - Trailing Whitespace entfernt
    - <CR> entfernt
    - Tabs entfernt
      - einige Sourcen sind offenbar mit Tabwidth=8 (F4xx arm_fft_bin_data.c)
        Ich habe dies nicht berücksichtigt und mein Detabbing erst mal komplett mit Tabwidth=8 gemacht
  - Ansi/Utf-8: � ausgetauscht
  - Schreibschutz von den Dateien entfernt
    - Check : find . -print0 | xargs -0 ls -lda
    - Change: chmod -R +w .

Gefundene Dateitypen:
- *.h, *.c, *.s, *.S, *.ld → Sourcen (C, Asm, Linkerskript)
- *.txt → Ascii Textfiles
- *.a → GCC Library
- *.asm → Assembler (Tasking, Hitop)
- *.lib → Keil Library
- .cproject, .project, *.launch, *.prefs → Eclipse Projectfiles etc. (bzw. Atollic Studio)
- *.uvopt, *.uvproj → Keil Projectfiles
- *.pdf, *.htm, *.html, *.css, *.jpg, *.bmp, *.gif, *.png, *.chm, *.doc → diverse Doku
- *.lnk, *.lsl, *.scr → Tasking / Hitop Settings
- *.ewd, *.ewp, *.eww → Iar Settings
- Weitere vorerst nicht untersuchte:
  - *.exe
  - *.FLM
  - *.htp
  - *.icf
  - *.ini
  - *.js
  - *.mht
  - *.rapp
  - *.rprj
  - *.svd
  - *.xls
  - *.xsd
