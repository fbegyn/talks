.PHONY: fmt
fmt:
	nix develop -c alejandra *.nix

%.pdf: always
	nix develop -c pandoc --template src/beamer.pandoc -H src/theme.tex -st beamer $*.md -o $*.pdf


.PHONY: always
always:
