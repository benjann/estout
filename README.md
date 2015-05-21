# estout
Stata module to make regression tables

The estout package provides tools for making regression tables in Stata (www.stata.com). The package currently contains the following programs.

esttab: Command to produce publication-style regression tables that display nicely in Stata's results window or, optionally, are exported to various formats such as CSV, RTF, HTML, or LaTeX. esttab is a user-friendly wrapper for the estout command.

estout: Generic program to compile a table of coefficients, "significance stars", summary statistics, standard errors, t- or z-statistics, p-values, confidence intervals, or other statistics for one or more models previously fitted and stored. The table is displayed in the results window or written to a text file for use with, e.g., spreadsheets or LaTeX.

eststo: Utility to store estimation results for later tabulation. eststo is an alternative to official Stata's estimates store. Main advantages of eststo over estimates store are that the user does not have to provide a name for the stored estimation set and that eststo may be used as a prefix command.

estadd: Program to add extra results to the returns of an estimation command. This is useful to make the the results available for tabulation.

estpost: Program to prepare results from commands such as summarize, tabulate, or correlate for tabulation by esttab or estout.

To install the estout package, type

. ssc install estout, replace

in Stata.

Compatibility: estout requires Stata 8.2 or newer. 
