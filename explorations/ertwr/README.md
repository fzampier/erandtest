# e-RTwr Exploration

This folder parks the former e-RTwr material removed from the active V8
manuscript.

The current prototype is a sequential pairwise win/loss e-process. It forms
disjoint or predictably selected treatment-control pairs and updates wealth from
the pairwise outcome sign. That may be useful, but it is not the same conceptual
object as the active e-RT methods, which bet on randomized assignment before
using the assignment in the current update.

The material here is retained for future work on pairwise/GPC endpoints. A
future e-RT-compatible version should likely reformulate the problem as a true
randomization test: form pairs predictably, observe pair outcomes, determine the
clinically preferred member, and then bet whether that member was randomized to
treatment.

These scripts and results are not part of `make all` and do not support active
claims in `manuscript/e-RT_v8.tex`.
