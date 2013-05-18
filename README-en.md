ipaex-type1 PACKAGE
===================

This package contains the IPAex Fonts converted into Unicode subfonts
in Type1 format, which is most suitable for use with the CJK package.
Font conversion was done with ttf2pt1.

### Installation

Place the files in the package as follows:

  - `tfm/*.tfm`       → $TEXMF/fonts/tfm/public/ipaex-type1/
  - `type1/*.pfb`     → $TEXMF/fonts/type1/public/ipaex-type1/
  - `ipaex-type1.map` → $TEXMF/fonts/map/dvips/ipaex-type1/
  - `*.fd`            → $TEXMF/tex/latex/ipaex-type1/

After that, invoke updmap as usual.

    updmap --enable Map ipaex-type1.map

### Usage in LaTeX

After installation, you can use the following two families,

  * ipxm = IPAexMincho
  * ipxg = IPAexGothic

in the folloing encodings:

  * OT1 / T1 / TS1 encodings
  * `UTF8` encoding of the CJK package (internally called C70)

An example of using an alphabetic encoding.

    \documentclass{article}
    \renewcommand{\rmdefault}{ipxm}
    \renewcommand{\sfdefault}{ipxg}
    \begin{document}
    \textsf{Test}\quad Hello, {\TeX} world!
    \end{document}

An example of using the CJK package.

    % encoded in UTF-8
    \documentclass{article}
    \usepackage{CJK}
    \begin{document}
    \begin{CJK*}{UTF8}{ipxm}
    これは簡単なテスト文書です。
    \end{CJK*}
    \end{document}

### License

This package is distributed under the “IPA Font License
Agreement v1.0” (see the file named LICENSE for detail).

Revision History
----------------

  * Version 0.3a [2013/05/18]
      - (experimental) Set offset in vertical writing.
  * Version 0.3  [2013/05/08]
      - (experimental) Supported vertical writing.
  * Version 0.2a [2013/04/22]
      - Fixed spacing in some TFMs in OT1/T1/TS1 encodings.
  * Version 0.2  [2013/04/21]
      - First public version.

--------------------
Takayuki YATO (aka. "ZR")  
http://zrbabbler.sp.land.to/
