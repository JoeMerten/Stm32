St Lib inkl. Cmsis
==================

Stlib Download:
- http://www.st.com/web/en/search/partNumberKeyword
- dann als Suchbetriff eingeben: "Stm32 Standard Peripheral Library"
- nun die lange Liste durchblättern nach der gesuchten Lib

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
  - Ansi/Utf-8: Komische Apostrophe und Anführungszeichen (�) ausgetauscht
  - Schreibschutz von den Dateien entfernt
    - Check : find . -print0 | xargs -0 ls -lda
    - Change: chmod -R +w .

Gefundene Dateitypen (nur F10x, F2xx, F4xx untersucht, also exklusive F3xx):
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

Bzgl. F3xx:
  - kurz betrachtet am 19.9.2014
  -> http://www.st.com/web/en/catalog/mmc/FM141/SC1169/SS1576?sc=stm32f3
  - F30x: V1.1.0 (stm32f30x_dsp_stdperiph_lib.zip) STSW-STM32108   -> STM32F30x/31x DSP and standard peripherals library, including 81 examples for 25 different peripherals and template project for 5 different IDEs (UM1581)
  - http://www.st.com/st-web-ui/static/active/en/st_prod_software_internet/resource/technical/software/firmware/stm32f30x_dsp_stdperiph_lib.zip
  - F37x: V1.0.0 (stm32f37x_dsp_stdperiph_lib.zip) STSW-STM32115   -> STM32F37x/38x DSP and standard peripherals library, including 73 examples for 26 different peripherals and template project for 5 different IDEs (UM1565)
  - http://www.st.com/st-web-ui/static/active/en/st_prod_software_internet/resource/technical/software/firmware/stm32f37x_dsp_stdperiph_lib.zip
  - in Sume ca. 266 MiB, 4.300 Files