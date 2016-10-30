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
  - `*.sty`           → $TEXMF/tex/latex/ipaex-type1/
  - `*.fd`, `*.fdx`   → $TEXMF/tex/latex/ipaex-type1/

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

In addition, the ipaex-type1 bundle of version 0.4 or later provides a
package (also called “ipaex-type1”) which enables users to use the
fonts more easily.

### License

This package is distributed under the “IPA Font License
Agreement v1.0” (see the file named LICENSE for detail).

ipaex-type1 Package
-------------------

### Loading

There are no package options available.

    \usepackage{ipaex-type1}

### Usage

The description assumes that the CJK package is employed.

  * `\ipxmfamily`/`\ipxgfamily`: Changes both the CJK and non-CJK
    families to `ipxm`/`ipxg`.
  * `\textipxm{<text>}`/`\textipxg{<text>}`: The text-command version of
    the above.
  * `\CJKipxmfamily`/`\CJKipxgfamily`: Changes only the CJK family to
    `ipxm`/`ipxg`. (It is the same as `\CJKfamily{ipxm}` etc.)
  * `\textCJKipxm{<text>}`/`\textCJKipxg{<text>}`: The text-command
    version of the above.
  * `\ipxmsymbol{<Unicode-point>}`/`\ipxgsymbol{<Unicode-point>}`:
    Prints a CJK character with the given Unicode point using CJK family
    `ipxm`/`ipxg`. For example, `\ipxmsymbol{"2603}` has the same effect
    as `{\CJKfamily{ipxm}\Unicode{"26}{"03}}`.

When the CJK package is not loaded, or the commands are invoked outside
`CJK(*)` environments, the effect on CJK families are generally omitted.
Namely, `\ipxmfamily` will change the (sole, non-CJK) family to `ipxm`,
and `\CJKipxgfamily` will do nothing. There are however some exceptions
to the general rule, which are described in the following subsections.

### `\textCJKipxm`/`\textCJKipxg` commands

When the CJK package is loaded and `\textCJKipxm` is invoked outside
`CJK` environments, then the argument text will be automatically placed
in a temporary `CJK*` environment. The example:

    Japan (\textCJKipxm{日本})

has the same effect as:

    Japan (\begin{CJK*}{UTF8}{ipxm}日本\end{CJK*})

### `\ipxmsymbol`/`\ipxgsymbol` commands

These two commands can be used outside `CJK` environments and even
without the CJK package. In that case, the CJK characters are treated
like symbol characters. For example, if you need only to write a single
Japanese word “日本” in your document, then you can dispense with the
CJK package and write as follows:

    Japan (\ipxmsymbol{"65E5}\ipxmsymbol{"672C})

Revision History
----------------

  * Version 0.4a ‹2016/10/20›
      - Bug fix.
  * Version 0.4  ‹2016/10/01›
      - Converted from the version 003.01 of the IPAex Fonts.
      - Supported non-BMP characters.
      - Provided a LaTeX package.
  * Version 0.3b ‹2013/10/11›
      - Document correction.
  * Version 0.3a ‹2013/05/18›
      - (experimental) Set offset in vertical writing.
  * Version 0.3  ‹2013/05/08›
      - (experimental) Supported vertical writing.
  * Version 0.2a ‹2013/04/22›
      - Fixed spacing in some TFMs in OT1/T1/TS1 encodings.
  * Version 0.2  ‹2013/04/21›
      - First public version.

--------------------
Takayuki YATO (aka. "ZR")  
http://zrbabbler.sp.land.to/
