;;; gmail-encoding.el ---

;; Copyright (c) 2014 Chris Done. All rights reserved.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(defun gmail-encoding-decode-html (string)
  "Decode HTML-encoded string."
  (gmail-encoding-decode-numbered-entities
   (gmail-encoding-decode-named-entities string)))

(defun gmail-encoding-decode-numbered-entities (string)
  "Convert escapes like '&#955;' to Unicode like 'λ'.
Operates on the active region or the whole buffer."
  (with-temp-buffer
    (insert string)
    (let ((start (point-min))
          (end (point-max)))
      (replace-regexp-in-string
       "&#[0-9]*;"
       (lambda (match)
         (format "%c" (string-to-number (substring match 2 -1))))
       (filter-buffer-substring start end t)))))

(defun gmail-encoding-decode-named-entities (string)
  "Decode named HTML entities."
  (let* ((plist '(Aacute "Á" aacute "á" Acirc "Â" acirc "â" acute "´" AElig "Æ" aelig "æ" Agrave "À" agrave "à" alefsym "ℵ" Alpha "Α" alpha "α" amp "&" and "∧" ang "∠" apos "'" aring "å" Aring "Å" asymp "≈" atilde "ã" Atilde "Ã" auml "ä" Auml "Ä" bdquo "„" Beta "Β" beta "β" brvbar "¦" bull "•" cap "∩" ccedil "ç" Ccedil "Ç" cedil "¸" cent "¢" Chi "Χ" chi "χ" circ "ˆ" clubs "♣" cong "≅" copy "©" crarr "↵" cup "∪" curren "¤" Dagger "‡" dagger "†" darr "↓" dArr "⇓" deg "°" Delta "Δ" delta "δ" diams "♦" divide "÷" eacute "é" Eacute "É" ecirc "ê" Ecirc "Ê" egrave "è" Egrave "È" empty "∅" emsp " " ensp " " Epsilon "Ε" epsilon "ε" equiv "≡" Eta "Η" eta "η" eth "ð" ETH "Ð" euml "ë" Euml "Ë" euro "€" exist "∃" fnof "ƒ" forall "∀" frac12 "½" frac14 "¼" frac34 "¾" frasl "⁄" Gamma "Γ" gamma "γ" ge "≥" gt ">" harr "↔" hArr "⇔" hearts "♥" hellip "…" iacute "í" Iacute "Í" icirc "î" Icirc "Î" iexcl "¡" igrave "ì" Igrave "Ì" image "ℑ" infin "∞" int "∫" Iota "Ι" iota "ι" iquest "¿" isin "∈" iuml "ï" Iuml "Ï" Kappa "Κ" kappa "κ" Lambda "Λ" lambda "λ" lang "〈" laquo "«" larr "←" lArr "⇐" lceil "⌈" ldquo "“" le "≤" lfloor "⌊" lowast "∗" loz "◊" lrm "" lsaquo "‹" lsquo "‘" lt "<" macr "¯" mdash "—" micro "µ" middot "·" minus "−" Mu "Μ" mu "μ" nabla "∇" nbsp "" ndash "–" ne "≠" ni "∋" not "¬" notin "∉" nsub "⊄" ntilde "ñ" Ntilde "Ñ" Nu "Ν" nu "ν" oacute "ó" Oacute "Ó" ocirc "ô" Ocirc "Ô" OElig "Œ" oelig "œ" ograve "ò" Ograve "Ò" oline "‾" omega "ω" Omega "Ω" Omicron "Ο" omicron "ο" oplus "⊕" or "∨" ordf "ª" ordm "º" oslash "ø" Oslash "Ø" otilde "õ" Otilde "Õ" otimes "⊗" ouml "ö" Ouml "Ö" para "¶" part "∂" permil "‰" perp "⊥" Phi "Φ" phi "φ" Pi "Π" pi "π" piv "ϖ" plusmn "±" pound "£" Prime "″" prime "′" prod "∏" prop "∝" Psi "Ψ" psi "ψ" quot "\"" radic "√" rang "〉" raquo "»" rarr "→" rArr "⇒" rceil "⌉" rdquo "”" real "ℜ" reg "®" rfloor "⌋" Rho "Ρ" rho "ρ" rlm "" rsaquo "›" rsquo "’" sbquo "‚" scaron "š" Scaron "Š" sdot "⋅" sect "§" shy "" Sigma "Σ" sigma "σ" sigmaf "ς" sim "∼" spades "♠" sub "⊂" sube "⊆" sum "∑" sup "⊃" sup1 "¹" sup2 "²" sup3 "³" supe "⊇" szlig "ß" Tau "Τ" tau "τ" there4 "∴" Theta "Θ" theta "θ" thetasym "ϑ" thinsp " " thorn "þ" THORN "Þ" tilde "˜" times "×" trade "™" uacute "ú" Uacute "Ú" uarr "↑" uArr "⇑" ucirc "û" Ucirc "Û" ugrave "ù" Ugrave "Ù" uml "¨" upsih "ϒ" Upsilon "Υ" upsilon "υ" uuml "ü" Uuml "Ü" weierp "℘" Xi "Ξ" xi "ξ" yacute "ý" Yacute "Ý" yen "¥" yuml "ÿ" Yuml "Ÿ" Zeta "Ζ" zeta "ζ" zwj "" zwnj ""))
         (get-function (lambda (s) (or (plist-get plist (intern (substring s 1 -1))) s))))
    (replace-regexp-in-string "&[^; ]*;" get-function string)))

(defun gmail-encoding-decode-base64 (string.)
  "Decode a base64-encoded email and strip off DOS newlines."
  (decode-coding-string
   (let ((string (replace-regexp-in-string
                  "_" "/"
                  (replace-regexp-in-string "-" "+" string.))))
     (replace-regexp-in-string
      "\r" ""
      (condition-case error
          (base64-decode-string string)
        (error
         (catch 'done
           (when (string-match
                  "\\([A-Za-z0-9+/ \t\r\n]+\\)=*" string)
             (let ((tail (substring string (match-end 0)))
                   (string (match-string 1 string)))
               (dotimes (i 3)
                 (condition-case nil
                     (progn
                       (setq string (base64-decode-string string))
                       (throw 'done (concat string tail)))
                   (error))
                 (setq string (concat string "=")))))
           (signal (car error) (cdr error)))))))
   'utf-8 t))

(defconst gmail-encoding-number-to-string-approx-suffixes
  '("k" "M" "G" "T" "P" "E" "Z" "Y"))
(defun gmail-encoding-number-to-string-approx-suffix (n &optional binary)
  "Return an approximate decimal representation of NUMBER as a string,
followed by a multiplier suffix (k, M, G, T, P, E, Z, Y). The representation
is at most 5 characters long for numbers between 0 and 10^19-5*10^16.
Uses a minus sign if negative.
NUMBER may be an integer or a floating point number.
If the optional argument BINARY is non-nil, use 1024 instead of 1000 as
the base multiplier."
  (if (zerop n)
      "0"
    (let ((sign "")
          (b (if binary 1024 1000))
          (suffix "")
          (bigger-suffixes gmail-encoding-number-to-string-approx-suffixes))
      (if (< n 0)
          (setq n (- n)
                sign "-"))
      (while (and (>= n 9999.5) (consp bigger-suffixes))
        (setq n (/ n b) ; TODO: this is rounding down; nearest would be better
              suffix (car bigger-suffixes)
              bigger-suffixes (cdr bigger-suffixes)))
      (concat sign
              (if (integerp n)
                  (int-to-string n)
                (number-to-string (floor n)))
              suffix))))

(defun gmail-encoding-html->plain (html)
  "Strip out the tags from the given HTML.

Forgive me for my sins"
  (replace-regexp-in-string
   "\\(^ \\|\u00A0\\)" ""
   (replace-regexp-in-string
    "[ ]+" " "
    (gmail-encoding-decode-html
     (replace-regexp-in-string
      "\\(<.*?>\\)" ""
      (replace-regexp-in-string
       "<\\(br\\|p\\).*?>" "\n"
       (replace-regexp-in-string "\n" " " html)))))))

(provide 'gmail-encoding)
