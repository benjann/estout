# estout

The **estout** package provides tools for making regression tables in [Stata](http://www.stata.com). The package currently contains the following programs:

1. **esttab**: Command to produce publication-style regression tables that display nicely in Stata's results window or, optionally, are exported to various formats such as CSV, RTF, HTML, or LaTeX. **esttab** is a user-friendly wrapper for the **estout** command.

2. **estout**: Generic program to compile a table of coefficients, "significance stars", summary statistics, standard errors, t- or z-statistics, p-values, confidence intervals, or other statistics for one or more models previously fitted and stored. The table is displayed in the results window or written to a text file for use with, e.g., spreadsheets or LaTeX.

3. **eststo**: Utility to store estimation results for later tabulation. **eststo** is an alternative to official Stata's **estimates store**. Main advantages of **eststo** over **estimates store** are that the user does not have to provide a name for the stored estimation set and that **eststo** may be used as a prefix command.

4. **estadd**: Program to add extra results to the returns of an estimation command. This is useful to make the the results available for tabulation.

5. **estpost**: Program to prepare results from commands such as **summarize**, **tabulate**, or **correlate** for tabulation by **esttab** or **estout**.

To install the `estout` package from the SSC Archive, type

    . ssc install estout, replace

in Stata. Stata version 8.2 or newer is required.

---

Installation from GitHub:

    . net install estout, replace from(https://raw.githubusercontent.com/benjann/estout/master/)

---

Main changes:

    26apr2022
    estout.ado (3.31)
    - when writing RTF format, the horizontal rule between table header and table
      body was missing if the table body contained only a single physical row; this
      is fixed 

    25mar2022
    estout.ado (3.30)
    - estout now internally renames unnamed equations to "__" (rather than Stata's
      default "_"); this fixes a number of issues (e.g. the issues addressed in 
      v3.25 and v3.26 using a different approach) and it also gives the user more
      control when addressing coefficients in options such as keep(), drop(),
      rename() etc.; specifying "_:coef" (or "__:coef") now specifically refers
      to "coef" in unnamed equations; in the old behavior "_:coef" addressed
      "coef" in any equation (i.e. same as specifying "coef" without "_:") and there
      was no possibility to address "coef" in unnamed equations only
    - rename() did not work with names containing spaces; this is fixed
    - refcat() did not work with names containing spaces; this is fixed
    - -unstack- produced erroneous results if equations were not in order; this
      could happen if order() was used in a way such that the coefficients
      from an equation were divided into multiple sets interrupted by other
      equations; the problem is now fixed by enforcing ordered equations in case
      of -unstack-
    - when using -unstack-, models for which the first element of cells() was
      not available were suppressed; this is fixed

    24mar2022
    estout.ado (3.29)
    - the unicode translator introduced in 3.27 chopped lines after 200 characters;
      this is fixed
    - blanks in coefficient names lead to erroneous results when more than one
      model was tabulated; this is fixed (Stata 11 or newer only)

    24mar2022
    estout.ado (3.27)
    - in Stata 14 or newer, a subroutine is now called that escapes non-ASCII
      characters if the output format is RTF (the characters are translated
      to \u#?, where # is the base 10 character code); option -nortfencode-
      prevents this behavior

    22mar2022
    estout.ado (3.26)
    - now using a different approach to fix the order()/unstack issue; this also
      fixes the second issue in https://github.com/benjann/estout/issues/33

    21mar2022
    estout.ado (3.25)
    - order() together with -unstack- lead to erroneous arrangement of the table
      if there were unnamed equations; this is fixed
      (see https://github.com/benjann/estout/issues/33)

    19may2021
    esttab.ado (2.1.0)
    - added support for (Multi)Markdown through option -md- or -mmd- (or file suffix
      .md or .mmd); md and mmd are synonyms; the changes are based on the suggestions
      made by Emanuele Bardelli (see https://github.com/benjann/estout/pull/24)
    
    estpost.ado (1.2.1)
    - pweights and iweights are now allowed by -estpost gtabstat-; proposed by 
      Kye Lippold (see https://github.com/benjann/estout/pull/27)
    
    30apr2021
    estout.ado (3.24)
    - the value of the previous statistic was reported instead of missing, if the
      model p-value was requested, but the model contained no (nonmissing) F or 
      chi2 value; this is fixed
    - the last format was used for all CIs if multiple formats were specified in 
      cells(ci(fmt())); this is fixed
    
    17apr2020
    - installation files added to GitHub distribution
    
    08aug2019
    estout.ado (3.23) and estadd.ado (2.3.5)
    - changes from 07aug2019 undone because StataCorp will change Stata 16
    
    07aug2019
    estout.ado (3.24) and estadd.ado (2.3.6)
    - Stata 16 introduced support for abbreviations in colnumb()/rownumb(); this
      new feature could cause problems in estout and in some estadd functions; 
      estout and the relevant estadd functions now include code to enforce old
      behavior of colnumb()/rownumb()
    
    13jun2019
    estpost.ado (1.2.0)
    - estpost gtabstat added by Mauricio Caceres Bravo
    
    31may2019
    estout.ado (3.23)
    - estout crashed if a coefficient name contained an apostroph ('); this is fixed
    - style() caused error if used with -estout matrix()-; this is fixed (thanks to 
      Daniel Bela)
    - indicate() did not work correctly if there were repeated models; this is fixed
    
    01mar2019
    estpost.ado (1.1.9):
    - -svy:tab-: e(lb) and e(ub) were missing in cases where -svy- did not 
      provide e(df_r); this is fixed
    - computation of p-values and CIs failed if degrees of freedom were larger than 
      2e17 (or lager than 1e12 in Stata versions < 10) (can happen with -mi 
      estimate-); this is fixed
    - @span in the erepeat() suboption returned wrong result if labcol2() was
      specified; this is fixed
    - element-specific drop()/keep() did not work as expected if coefficient names 
      contained spaces; this is fixed
    
    06feb2016
    estout.ado (3.20)
    - if estout is called without without namelist and the active results are not
      among the estimates stored by eststo, estout now displays a note (suggested 
      by Nils Enevoldsen)
    estadd.ado (2.3.5)
    - the 28jan2016 update of Stata 14 broke estadd.ado; this is fixed
      (the update caused estadd to remove e(_estimates_name) from the active 
      estimates; a consequence of this was that results were no longer added to the
      stored copy of the estimates if estadd was applied more than once)
    esttab.ado (2.0.9)
    - when tabulating a matrix with more than one column in tex format, only one 
      column was defined in the tabular environment; this is fixed
    - the alignment() option now allows multiple-column shorthand when tabulating 
      a matrix in tex format; for example, type alignment(*{5}{l}) if the matrix 
      has 5 columns that should all be left aligned
    - the definition of the tabular environment in tex format did not always 
      contain the correct number of columns if the cells() option was used; this
      is improved
    
    16jun2015
    estadd.ado (2.3.4)
    - -estadd local- now uses macval() to suppress macro expansion (only when 
      applied to active estimates and not for the display of the results)
    estpost.ado (1.1.8)
    - now uses macval() to suppress macro expansion in labels; affects subcommands
      -tabstat-, -tabulate-, -svy:tabulate-, and -stci-
    - subcommands -tabstat-, -tabulate-, -svy:tabulate- and -stci- now have an 
      -elabels- option to enforce saving labels in e()
    - subcommand -tabstat- now uses the actual by() values (instead of 1, 2, 3, ...)
      if a numeric by() variable is specified and labels are saved in e(labels)
    
    02jun2015:
    estout.ado (3.19)
    - estout now supports Unicode in Stata 14
    esttab.ado (2.0.8)
    - added option -[no]float- to suppress/enforce table float environment in LaTeX
    
    20mar2015:
    estout.ado (3.18)
    - cell contents longer than 245 characters was chopped off by -file write- when 
      writing the table cells; this is fixed
    - computation of p-values and CIs from -mi- failed for coefficients for which 
      e(df_mi) was missing; this is fixed (using normal approximation)
    esttab.ado (2.0.7)
    - added option fonttbl() to set font table in RTF
    
    02jun2014:
    estout.ado (3.17)
    - estout now compiles labels for levels of factor variables and interactions
    - new option -interaction()- to specify delimiter for interactions
    - new options -[no]omitted- and -[no]baselevels- to specify whether 
      omitted coefficients and base levels are included; the default is
      to include these coefficients
    - the "o." and "b." flags are now removed from coefficient names
    - estout no longer returns error if models use different base levels
    esttab.ado (2.0.6)
    - defaults for interaction() added
    estout_mystyle.def
    - entries for -omitted-, -baselevels- and -interaction- added
    
    30may2014
    esttab.hlp:
    - clarified that explicit output format option will override format inferred 
      from file suffix
    
    30may2014
    estout.ado (3.16)
    - estout now picks up e(df_mi) for the computation of confidence intervals and 
      p-values after -mi estimate, post-
    - estout crashed on models with equation names containing "."; this is fixed
    - estout now works on Small Stata
    - estout no longer breaks on wide rtf tables
    estadd (2.3.3)
    - the -outcome()- and -split- options in -estadd prchange- did no longer work; 
      this is fixed
    estpost (1.1.6)
    - -estpost correlate- did not work in Stata 8; this is fixed
    
    10oct2009
    estadd (2.3.1)
    - -estadd margins- added
    - -adapt- option of -estadd listcoef- discontinued
    estpost (1.1.5)
    - -estpost margins- added
    - -estpost svy: tab- now correctly returns the subpopulation number of
       observations in e(obs) if -subpop()- is specified.
       
    06aug2009
    estout (3.13):
    - estout no longer chokes on factor variables in Stata 11
    
    09apr2009
    estpost (1.1.3):
    - -estpost tabstat- now allows -columns(stats)-
    
    25mar2009
    estadd (2.2.8):
    - support for -prvalue- and -asprvalue- from SPost added
    - -estadd prchange- now adds outcome-specific results and average results
      by default; new -avg- option to store only average result and -noavg- to
      omit the average results; -adapt- option that was used in earlier
      versions to add the outcome-specific results discontinued
    
    11mar2009
    estout (3.12):
    - "z" can now be used as a synonym for "t" in cells()
    - cells(t(abs)) returned error; this is fixed
    esttab (2.0.5):
    - option -z[(fmt)]- added (z statistics)
    estadd (2.2.4):
    - improved formulas for coxsnell and nagelkerke (old formulas likely returned
      1 in large datasets)
    estpost (1.1.2):
    - -estpost tabstat- displayed wrong results (in each column the results
      from the last column were displayed; returned results were not affected);
      this is fixed
      
    24feb2009
    estpost (1.1.1):
    - -estpost tabstat, statistics(semean)- crashed in some situations; this is
      fixed (thanks to Matthew Fiedler for reporting the bug)
    - -estpost tabstat- now uses label "semean" instead of "se(mean)"
    - -estpost tabstat- could crash if variables or statistics were repeated;
      this is fixed
    
    16feb2009
    esttab (2.0.4)
    - -longtable- option added

    10feb2009
    estout (3.11):
    - -order()- now adds extra table rows for elements not found in the table
    - r(coefs) now respects -order()-, -keep()-, and -drop()-
    
    21jan2009
    estout (3.10):
    - missing values (except .y and .z) in table cells are now treated like
      any other values
    estadd (2.2.3):
    - -estadd local- returned error if the specified string contained
      certain special characters; this is fixed
    estpost (1.1.0):
    - support for -svy: tabulate- added
    - string variables are now allowed with -estpost tabulate-
    - -estpost tabulate- returned a wrong e(sample) in some situations; this is
      fixed
    
    08jan2009
    estout (3.09):
    - options in estout.hlp are now fully linked
    - no longer wrapper for -estimates table-; now incorporates code from
      est_table.ado; still uses "undocumented" -mat_capp-
      => can now tabulate models that do not contain any coefs (e.g. stcox
         without predictors)
      => name space for coefficients is no longer restricted to names in e(b)
      => can now tabulate estimates without e(b) or e(V) (e.g. -factor-)
      => rule for merging e()-vectors: coefficients from e()'s without
         equations are merged into existing equations (without expanding the
         name space) if at least one e() does not contain equation "_" and
         no e() contains equation "_" along with other equations (and e(b)
         does not contain equation "_"); else: match by equation and expand
         name space if necessary
      => returns results in r() (r(coefs), r(stats), r(cmdline), etc.)
      => new rename() option to rename/match coefficients
      => el[#] and el[rowname] or el["rowname"] now possible to choose row of
         e(el) to be tabulated (support for el_# syntax discontinued)
      => cells(): new -transpose- suboption in -cells()-
      => new 'var' element (variance) available in -cells()-
      => existing e(se), e(var), e(t), e(p), e(ci_l), e(ci_u) now take precedence
         over internal computations (unless -margin- applies to model)
    - -estout matrix()-, -estout e()-, and -estout r()- now available to tabulate
      a matrix
    - new eqlabels(,merge) option => merge eqlabel into varlabel
    - mutiple values may now be specified in modelwidth()
    - cells(): parentheses can now be used to bind statistics in a row
    - -nolabel- option in refcat() added
    - an individual model can now be included multiple times in a table
    - now uses abs() in formula to derive SEs of transformed coefficients
    - now adds e(cmd)="." to current estimates if undefined (so that results
      without e(cmd) can be tabulated)
    - no longer error if all coefs dropped
    - fmt() can now be abbreviated as f()
    - "\\" was not preserved in model titles taken from label of depvar; this
      is fixed
    - @rtfrowdef now generally available (undocumented)
    - fixed parsing of -cells- from defaults files
    - fixed bug related to cells(ci(star))
    - @modelwidth variable now available in par() suboption in cells()
      (undocumented)
    - repeated elements in cells() now have their own set of suboptions
    - coefficients containing blanks now allowed
    - fixed alignment bug related to statistics with stars and pattern()
    - in wide mode, empty columns in equations (due to keep/drop cell-subopts)
      are now suppressed
    esttab (2.0.3)
     - -esttab matrix()-, -esttab e()-, and -esttab r()- now supported
     - no longer returns r(estout) since -estout- now returns r(cmdline)
     - -note()- now replaces the standard note
     - @starlegend is no longer default if user specifies -cells()-
     - -gaps- is no longer default if user specifies -cells()-
    eststo (1.1.0)
     - new -prefix()- option
    estadd (2.2.2)
    - support for -prvalue- and -asprvalue- from SPost added (not documented yet)
    - -estadd prchange- returns results differently; -add(all)- no longer
      supported; -add()- renamed to -pattern()-; type of main results now
      returned in e(pattern)
    - now allows break key in subroutines
    estpost (1.0.0)
     - new -estpost- command added to package
    
    09apr2008
    estout (2.86)
    - user parameter statistics in cells() were suppressed under some
      circumstances if the -equations()- option was specified. This is fixed.
    eststo (1.0.9)
    - the -nocopy- option did not work. This is fixed.
    - parsing in -addscalars()- has been improved (now binds parentheses/brackets
      and allows quotes)
    - the -noesample- option returned error if a variable with the same name
      as the estimation set existed in the dataset. This is fixed.
    
    18feb2008
    estout (2.85)
    - output is now suppressed if -using- is specified
    - new -[no]outfilenoteoff- option (undocumented)
    - -style(smcl)- is now default unless -using- is specified
    - new -[no]smclrules-, -[no]smclmidrules-, -[no]smcleqrule- options
      (undocumented)
    - new -note()- option (works like -title()-)
    - model label row is now suppressed if only the active (unstored) model
      is tabulated
    - -varlist()- now takes precedence over the labels generated
      by -eqlabels(none)-
    - bug fixed related to the -vacant()- and -unstack-
    - -se- was sometimes printed as "0" and sometimes as "." if the variance was
      zero; it is now always printed as "."
    esttab (1.4.0)
    - user provided significance symbols (-star()-) are now formatted
      depending on mode
    - -addnotes()- is now printed before -legend-; -note()- added
    eststo (1.0.7)
    - -eststo drop- now allows wildcards
    - -eststo dir- now shows list of stored estimates
    estadd (2.1.4)
    - new -quietly- option
    - SPost subcommands added (-fitstat-, -listcoef-, -prchange-, -brant-,
      and -mlogtest-)
    - -estadd- now passes through the caller version
    - lists of added results are now printed (unless colon syntax is used)
    - output was not suppressed in colon syntax if only one name was
      specified; this is fixed
    
    29oct2007
    esttab (1.3.8)
    - -title()- and @hline were printed on the same line in -fixed- mode;
      this is fixed
    
    27sep2007
    estout (2.79)
    - "&" can now be used in -cells()- to join parameter statistics together
      in one cell
    - repetitions of elements in -cells()- are now possible
    - "." can be used in -cells()- to insert empty cells
    - -fmt()- now allows "%g" and "g" for "%9.0g" and "a" for "a3"; invalid
      formats (i.e. if not starting with "%") now return error
    - e()-matrices with multiple rows can now be addressed using name_# in
      -cells()-
    - new -topfile()- and -bottomfile()- options
    - new -labcol2()- option
    - bug related to -extracols()- and -mgroups()- fixed
    - -abbrev- does no longer erase "." anymore
    esttab (1.3.7)
    - new -oncell- option
    estadd (2.1.0)
    - -estadd matrix- now also accepts matrix expressions
      (e.g. estadd matrix M = A*2)
    - -estadd matrix- can now be used as -estadd matrix matname- or
      -estadd matrix r(matname)- (adds e(matname))
    - -estadd scalar- can now be used as -estadd scalar scalarname- or
      -estadd scalar r(scalarname)- (adds e(scalarname))
    - -estadd r(name)- now adds, depending on the nature of r(name), scalar or
       matrix e(name)
    - -copy- option in -estadd matrix- discontinued
    - "invalid subcommand" error message added
    eststo (1.0.6)
    - now sets e(cmd) to "." if undefined
    
    30aug2007
    estout (2.73)
    - the -relax- suboption in options such as -drop()-, -keep()-, etc. is now
      documented
    - -mlabels()- now has a -[no]title- option
    - -eqlabels("",none)- did not work as advertised; this is fixed
    - the -none- label suboption can now be specified without comma
      (e.g. -eqlabels(none)- instead of -eqlabels(,none)-)
    - new options: -starkeep()-, -stardrop()-
    - the text specified in -prehead()- etc. and in the -begin()- and -end()-
      label suboptions is now printed on a single line if it does not contain
      double quotes
    - tab characters in defaults files are now allowed
    - empty table rows did not display correctly in older RTF readers; this is
      fixed
    esttab (1.3.5)
    - -mtitles[()]- now uses estimates titles (if defined) even if -label-
      is not specified
    - -addnotes()- now prints just one line if the string does not contains
      double quotes
    eststo (1.0.5), _eststo(1.0.3)
    - the caller version is now passed through
    estadd (2.0.8)
    - most functions now support variables with time-series operators
    
    08aug2007:
    estout (2.70)
    - inclusion of string e()-macros is now possible in the -stats()- option
    - Stata 10 uses "e(estimates_title)" instead of "e(_estimates_title)"; this
      is now recognized
    - -elist()- and -blist()- in -varlabels()- can now write multiple lines
    - some bugs fixed
    esttab (1.3.4)
    - -cells(none)- now produces better tables
    - not all -estout- options were always passed through correctly; this is
      fixed
    
    30may2007:
    esttab (1.3.2)
    - bug fixed related to equation lines in -fixed- mode
    - the -plain- option does not suppress the column labels anymore
    
    22may2007:
    estout (2.64)
    - "too many literals" bug fixed
    - new -wrap- option
    - the -stats()- option now has a -layout()- and a -pchar()- suboption
    - first element in -cells()- now sets the default display format (in earlier
      versions, the default format was set by the -b- element)
    - the -nofirst- and -nolast- suboptions in -varlabels()- now apply
      equationwise
    - new @rtfrowdefbrdrt and @rtfrowdefbrdrb variables (undocumented)
    - the label_subopts -elist()-, -blist()-, -begin()-, -end()- now also support
      the @M, @E, @width, @hline, and @rtfemptyrow (undocumented) variables
    - new -[no]first- label_subopt
    - new -replace- label_subopt to overwrite -begin()- and -end()-
    esttab (1.3.0)
    - -esta- renamed to -esttab-
    - lines between equations are now supported; new -noeqlines- option
    eststo (1.0.4)
    - -esto- renamed to -eststo-
    
    13apr2007:
    estout (2.58)
    - robust parsing of cells() if there are spaced between elements and their
      options
    - new -cells()- suboption called -pvalue()-
    esto (1.0.3)
    - -by- prefix command now supported
    - new -missing- option to be used with by prefix
    
    16mar2007:
    estout (2.56)
    - bug fixed related to -cells(..(drop()))- with -unstack-
    - new elements for -cells()- called -_star-, -_sign-, and -_sigsign-
    - bug fixed related to -transform()-
    - new -[no]asis- option (undocumented)
    - new -[no]smcltags- option (undocumented)
    - -style(smcl)- now includes horizontal lines
    - new -cells()- suboption called -vacant()-
    - -prefix()- and -suffix()- in -varlabels() now also applies to
      -refcat()- and -indicate()-
    - bug fixed related to spaces in -mlogit- equations
    esta (1.2.6)
    - improved smcl mode
    - LaTeX column specifiers are now compiled if -cells()- is
      specified (-stardetach- not supported)
    - column labels are now printed if -cells()- is specified
    estadd (2.0.6)
    - e(_estimates_name) is now backed up in e(_estadd_estimates_name) while
      working on the estimates set
    
    23feb2007:
    estout (2.50)
    - new @width variable
    - prefix() and suffix() are now added to labels *after* abbreviation
    esta (1.2.4)
    - new -smcl- mode; -smcl- is the new default
    - bug fixed related to leading spaces in labels in -scalars()- labels
      (length of the labels is now restricted to 80 or 244, depending on
      Stata flavor)
    
    04feb2007:
    estout (2.49)
    - new -dropped()- option
    esta
    - ** was used instead of *** for p<0.001 in -rtf- mode; this is fixed
    
    04jan2007:
    estout, estadd, esta, and esto are one package now
    estout (2.48)
    - rtf support added (undocumented: @rftrowdef and @rtfrowdefbrdr in
      begin(); @rftemptyrow in varlabels(,end()))
    - drop()/keep()/order() etc. now have a -relax- option (undocumented)
    - -starlevels()- now has -label()- and -delimiter()- suboptions
      (undocumented)
    esta (1.2.0)
    - -append- implemented for -tex-, -rft-, and -html-
    - improved -rtf- compatibility
    - -page(packages)- now adds "\usepackage{packages}" to LaTeX documents
    - -csv- mode now uses comma; new -scsv- mode (semi-colon separated)
    - default file extensions implemented (.txt, .csv, .rtf, .tex)
    - italics implemented for -rft-, -tex-, -html- in labels such as "R^2"
    - bug fixed related dropping constant (usage of -drop(_cons, relax)-)
    - symbols and thresholds may now be specified in -stars()-
    estadd (2.0.5)
    - r()'s are now always restored
    - bug fixed related to e(_estimates_name)
    - estadd now also works if current estimates do not contain e(cmd) or,
      in fact, are completely empty
    
    30nov2006:
    estout (2.45)
    - usage of * and ? wildcards in -drop()-, -keep()-, etc. now independent
      from the variable names in the active dataset
    - * and ? wildcards now allowed in equation names in -drop()-, -keep()-, etc.
    - bug fixed related to @hline>400
    esta (1.1.4)
    - new -rtf- mode
    - bug fixed related to -nodepvar- in -tex- mode
    - r(cmd) renamed to r(estout)
    - -nogaps- now default for -not-
    - bug fixed related to notes
    - new -main()- option
    esto (1.0.1)
    - does not drop e(sample) by default
    - new -_esto- command
    estadd (2.0.2)
    - bug fixed related to "GetRidof_estimates_name"
    - new -lrtest- subcommand
    
    16nov2006:
    estout (2.43)
    - bug fixed related to -eqlabels()- and -mlabels()-, if less labels than
      equations/models were specified
    - -est tab ..., equations(main=1)- is now used if models have
      different first equations (unless -unstack- or -equations()- is
      specified).
    - new -transform()- option
    - new -refcat()- option
    - new -indicate()- option
    - bug fixed related to -noabbrev- in -style(fixed)-
    
    04nov2006:
    estout (2.37)
    - new -order()- option; -keep()- does not change order
    - * and ? wildcards now allowed in -keep()-, -drop()-, etc.
    - new -extracols()- option
    - $esto is only used if the inicated estimates are available
    - bug fixed related to column delimiter in -style(fixed)-
    - bug fixed related to repeated equations
    - "equation:_cons" is now replaced with equation label if
      -eqlabels(,none)- is specified and "_cons" is only parameter in equation
    esta (1.1.0)
    - new -width()- option
    - note "(output written to ...)" added
    - -notype- is now default if -using- is specified
    - new -align()- option
    - new -fragment- option
    - new -noisily- option
    - new -csv-, -tex-, -tab-, -html-, and -booktabs- options
    - file suffix now determines mode
    
    21oct2006:
    estout (2.35)
    - -tab-, -fixed-, -tex-, -html- now internal styles; -estout_mystyle.def-
      provided
    - "estoutdef.ado" deleted from package
    - *.style renamed back to *.def
    - @E variable added (total number of equations)
    - bug fixed related to abbreviation and -numbers-
    - @span now supported in label_subopts -begin()- and -end()-
    
    21sep2006:
    estout (2.31)
    - changed default value for -discrete()-
    - e(sample) is now fixed if observations have been added to dataset
    - labels_subopts -end()- und -begin()- now feature multi-line strings
    - new -numbers- option
    - new -a#- display format (adaptive format)
    - new -#- display format (fixed format)
    - -varwidth()- now depends on -labels- with -style(fixed)-
    - global macro -$esto- now recognized
    - *.def renamed to *.style
    estadd (2.0.0)
    - new syntax: -estadd subcommand, opts: estimates-
    - subcommands now included in "estadd.ado"
    - new -local-, -matrix-, and -scalar- subcommands
    - -estadd_plus- package now incorporated into -estadd-
    esta (1.0.0) released on SSC
    esto (1.0.0) released on SSC
    
    12jun2006:
    estout (2.21)
    - new @hline variable and -hlinechar()- option
    
    02jan2006:
    estout
    - bug fixed related to Stata 9.1 and e(estimates_title)
    
    02dec2005:
    estout (2.18)
    - internal default values added
    - bugs fixed related to the 503 character limit of the -:word of-
      function
    
    08jun2005:
    estadd/estadd_plus
    - subcommands are now named "estadd_subcmd" (old: "_estadd_subcmd")
    - now also applies to the stored copy of the active estimates in any case
    
    13may2005:
    estout
    - equation name now allowed in -varlabels()
    - speed improvements
    estadd (1.0.5)
    - estadd is separate package now
    - new simplified alternative syntax for use with active estimates
    - new -replace- option; changed default: overwriting not permitted
    - all subcommands as separate ado files
    estadd_plus:
    - new subcommand called  -pcorr-
    
    15apr2005:
    estadd (1.0.3)
    - support for e(subpop) added
    - estadd_plus released on SSC; contains -summ-, -vif-, -ebsd-, -coxsnell-,
      and -nagelkerke- subcommands
    
    22mar2005:
    estout (2.15)
    - new introductory "estout_intro.hlp"
    
    14feb2005:
    estout (2.15)
    - invalid suboptions in -cells()- now cause error
    
    04feb2005:
    estout (2.14)
    - improved handling of labels for time-series variables
    
    28jan2005:
    estadd (1.0.2)
    - new -summ- subcommand
    
    30nov2004:
    estout (2.13)
    - new naming convention for defaults files
    - new "fixed" style
    - new -style()- option; replaces -defaults()-
    - multiple formats may now be specified for parameter statistics
    - last format in -stats(,fmt())- is now used for remaining stats
    - "(dropped)" was not displayed with all models; fixed
    - empty "significance symbols" now possible
    - valid range for starlevels now (0,1]
    - new estadd command; support for subcommands canceled
    - -stdev- subcommand renamed to -sd-
    
    11aug2004:
    estout (2.05)
    - bug fixed related to drop()/keep() in -cells()- and -unstack-
    - support for -mfx- with multiple equation models; new meqs() option
    
    04aug2004:
    estout (2.04)
    - new -mgroups()- option
    - new -blist()-/-elist()- suboptions in -varlabels()-
    - new -substitute()- option
    - bug fixed related to typing special characters
    - support for -mfx- added (single equation models only)
    - bug fixed related to model labels
    - // and /// comments now supported in defaults files
    - new -erpeat()- suboption in mlabels(), eqlabels(), and collabels()
    
    27jul2004:
    estout (2.00)
    - new syntax: -cells()- now determines the table contents
    - new -beta-, -mean-, and -stddev- subcommands
    - confidence intervals
    - summary statistics for each equation in -reg3-, -sureg-, and -mvreg-
      (if -unstack- specified)
    - new -varlabels()- and -mlabels()- options
    - labels_subopts: prefix()/suffix(), begin()/end(), none
    - -unstack- equations
    - overall-p-value
    - introduction of @variables
    - introduction of defaults files
    - new -dmarker()- , -msign()-, and -nolz- options
    - ... and many other changes
    estout v1 now available as estout1
    
    12jun2004:
    estout (1.02) released on SSC
