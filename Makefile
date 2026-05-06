RSCRIPT ?= Rscript
PANDOC ?= pandoc
LATEXMK ?= latexmk

.PHONY: deps-check results figures manuscript inventory all

deps-check:
	$(RSCRIPT) R/check_dependencies.R

results:
	$(RSCRIPT) R/simulations/ertb_baseline.R 5000
	$(RSCRIPT) R/simulations/erte_baseline_tables.R 2000
	$(RSCRIPT) R/simulations/erte_tuning_sensitivity.R 1000
	$(RSCRIPT) R/simulations/wager_policy_comparison.R 5000
	$(RSCRIPT) R/simulations/ertc_wager_policy.R 1000
	$(RSCRIPT) R/simulations/wager_asymmetry_binary.R 1000

figures:
	$(RSCRIPT) R/simulations/manuscript_trajectory_examples.R
	$(RSCRIPT) R/simulations/wager_policy_figures.R

manuscript:
	cd manuscript && $(PANDOC) e-RT_v9.tex -f latex -t gfm --citeproc --bibliography=references.bib --wrap=none -o e-RT_v9.md
	cd manuscript && $(LATEXMK) -pdf -interaction=nonstopmode -halt-on-error e-RT_v9.tex

inventory:
	$(RSCRIPT) R/check_inventory.R

all: deps-check results figures manuscript inventory
