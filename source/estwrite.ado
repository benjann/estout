*! version 1.2.4 04sep2009
*! version 1.0.1 15may2007 (renamed from -eststo- to -estwrite-; -append- added)
*! version 1.0.0 29apr2005 Ben Jann (ETH Zurich)
prog define estwrite
    version 8.2
    gettoken fn comma : 0, parse(" ,")
    gettoken comma : comma, parse(" ,")
    if `"`comma'"'=="," | `"`comma'"'=="" {
        local 0 `"using `macval(0)'"'
    }
    syntax [anything] using/ [, Replace Append Label(str) id(varname) alt estsave ]
    if c(stata_version)<9 | "`estsave'"!="" {
         estwrite_dta `macval(0)'
         exit
    }
    capt mata: mata drop ESTWRITE_FH
    capt mata: mata drop ESTWRITE_ESTS
    capt mata: mata drop ESTWRITE_ID
    capt mata: mata drop ESTWRITE_STER
    capt n estwrite_mata `macval(0)'
    local rc = _rc
    if `rc' {
        capt mata: mata describe ESTWRITE_FH
        if _rc==0 {
            capt mata: estwrite_fclose(ESTWRITE_FH)
        }
    }
    capt mata: mata drop ESTWRITE_FH
    capt mata: mata drop ESTWRITE_ESTS
    capt mata: mata drop ESTWRITE_ID
    capt mata: mata drop ESTWRITE_STER
    exit `rc'
end

prog define estwrite_dta, rclass
    version 8.2
    syntax [anything] using/ [, Replace Append Label(str) id(varname) estsave ]
    capt which estsave
    if _rc {
        di as error "-estsave- by Michael Blasnik required; type {stata ssc install estsave}"
        error 499
    }
    if "`append'"!=""&"`replace'"!="" {
        di as err "only one of replace and append allowed"
        exit 198
    }
    if "`id'"!="" {
        isid `id'
    }
//    est_expand `"`anything'"' , default(.)
    Est_Expand `"`anything'"'
    local names `r(names)'
    tempname hcurrent
    _est hold `hcurrent', restore estsystem nullok
    preserve
    foreach name of local names {
        nobreak {
            if "`name'"=="." {
                _est unhold `hcurrent'
                local name2 _active
            }
            else {
                qui est restore `name'
                local name2 `name'
            }
            local varabbrev `c(varabbrev)'
            set varabbrev off
            capt noisily break {
                capt n estsave , gen(_ests_`name2') replace
            }
            set varabbrev `varabbrev'
            local keep "`keep'_ests_`name2' "
            if "`name'"=="." _est hold `hcurrent', restore estsystem nullok
            else est sto `name', title(`"`e(_estimates_title)'"')
            if _rc exit _rc
        }
    }
    keep `id' `keep'
    if "`id'"=="" qui keep if 0
    else sort `id'
    label data `"`label'"'
    qui notes drop _all
    if "`append'"!="" {
        if "`id'"!="" local unique ", unique"
        else local unique
        capt merge `id' using `"`using'"' `unique'
        if _rc==601 {
            di as txt `"(note: file `using' not found)"'
        }
        else if _rc {
            merge `id' using `"`using'"' `unique' // => error
        }
        else {
            move `keep' _merge
            drop _merge
            if "`id'"!="" sort `id'
            local replace replace
        }
    }
    save `"`using'"', `replace'
    ret local names "`names'"
end

prog define estwrite_mata, sortpreserve
    version 9.2
    syntax [anything] using/ [, Replace Append Label(str) id(varname) alt ] // label() not used
    if c(stata_version)<10  local alt alt
    local ster = ("`alt'"=="")
    if "`append'"!=""&"`replace'"!="" {
        di as err "only one of replace and append allowed"
        exit 198
    }
    if "`append'"!="" local replace replace
    if "`id'"!="" {
        isid `id'
        sort `id'
        tempname esample
    }
    //est_expand `"`anything'"' , default(.)
    Est_Expand `"`anything'"'
    local names `r(names)'
    tempname hcurrent
    _est hold `hcurrent', restore estsystem nullok
    if "`append'"!="" | "`replace'"=="" {
        mata: estwrite_file_exists() // resets local append if file not found
    }
    if "`append'"!="" {
        local savemsg "appending"
        mata: ESTWRITE_STER = estwrite_file_read(ESTWRITE_ESTS=., ESTWRITE_ID=.)
        if "`id'"!="" {
            capt mata: assert(ESTWRITE_ID==J(0,1,.))
            if _rc==0 {
                di as err "using file has no ID; id() not allowed"
                exit 198
            }
            capt mata: assert(ESTWRITE_ID== ///
                (st_isstrvar("`id'") ? st_sdata(.,"`id'") : st_data(.,"`id'")))
            if _rc {
                di as err "id() differs from ID in using file"
                exit 499
            }
        }
        else {
            capt mata: assert(ESTWRITE_ID==J(0,1,.))
            if _rc!=0 {
                di as err "using file has ID; must specify id()"
                exit 198
            }
        }
        mata: st_local("i",strofreal(rows(ESTWRITE_ESTS)))
        mata: ESTWRITE_ESTS = ESTWRITE_ESTS \ estwrite_estimates_init()
    }
    else {
        local savemsg "saving"
        mata: ESTWRITE_ESTS = estwrite_estimates_init()
        mata: ESTWRITE_ID = J(0,1,.)
        local i 0
    }
    foreach name of local names {
        nobreak {   // 1st cycle: get estimtates info (ESTWRITE_ESTS, ESTWRITE_ID)
            if "`name'"=="." {
                _est unhold `hcurrent'
                di as txt "(`savemsg' active estimates)"
            }
            else {
                capt confirm new var _est_`name' // fix e(sample)
                if _rc qui replace _est_`name' = 0 if _est_`name' >=.
                _est unhold `name'
                di as txt "(`savemsg' `name')"
            }
            capt noisily break {
                if "`id'"!="" {
                    local hasesample: e(functions)
                    local hasesample: list posof "sample" in hasesample
                    if `hasesample' {
                        qui gen byte `esample' = e(sample)
                    }
                }
                mata: ESTWRITE_ESTS[`++i'] = &(estwrite_estimates_get(`ster'))
                if "`id'"!="" {
                    capture drop `esample'
                }
            }
            if "`name'"=="." _est hold `hcurrent', restore estsystem nullok
            else _est hold `name', estimates varname(_est_`name')
            if _rc exit _rc
        }
    }
    if "`id'"!="" & "`append'"=="" {
        mata: ESTWRITE_ID = st_isstrvar("`id'") ? st_sdata(.,"`id'") : st_data(.,"`id'")
    }
    mata: ESTWRITE_FH = estwrite_file_init(ESTWRITE_ESTS, ESTWRITE_ID)
    if "`append'"!="" {
        mata: estwrite_appendster(ESTWRITE_FH, ESTWRITE_STER)
    }
    if `ster' {   // 2nd cycle: add estimation sets to file
        foreach name of local names {
            nobreak {
                if "`name'"=="." {
                    _est unhold `hcurrent'
                }
                else {
                    _est unhold `name'
                }
                capt n mata: estwrite_appendcurrent(ESTWRITE_FH)
                if _rc {
                    mata: estwrite_writeerror(ESTWRITE_FH)
                }
                if "`name'"=="." _est hold `hcurrent', restore estsystem nullok
                else _est hold `name', estimates varname(_est_`name')
                if _rc exit _rc
            }
        }
    }
    mata: estwrite_fclose(ESTWRITE_FH)
end

program Est_Expand
    args anything
    if `"`anything'"'=="" local anything "."
    capt est_expand `"`anything'"'
    if _rc {
        if _rc==301 {  // add e(cmd)="." to current estimates if undefined
            if `:list posof "." in anything' & `"`e(cmd)'"'=="" {
                if `"`: e(scalars)'`: e(macros)'`: e(matrices)'`: e(functions)'"'!="" {
                    AddCmdToE "."
                }
            }
        }
        est_expand `"`anything'"'
    }
end
prog AddCmdToE, eclass
    ereturn local cmd `0'
end


if c(stata_version)<9 exit

local   ESTWRITE_SUFFIX     `"".sters""'
local   ESTWRITE_SIGNATURE  `""*! Stata estimation sets written by estwrite.ado v. 1.0""'
local   ESTWRITE_DATETIME   `""*! Date " + c("current_date") + " " + c("current_time")"'
local   ESTWRITE_ENDHEADER  `""*! <end_of_header>""'

version 9.2
mata:
mata set matastrict on

struct estwrite_fh {
    string scalar   fn, fn2
    real scalar     fh, fh2
}

struct estwrite_estimates
{
    string scalar                       name
    real scalar                         isster
    string colvector                    macnms, scanms, matnms

    string colvector                    macros
    real colvector                      scalars
    pointer (real matrix)   colvector   matrices
    pointer (string matrix) colvector   matrown, matcoln
    real colvector                      sample
}

void estwrite_file_exists()
{
    string scalar   fn

    fn = st_local("using")
    if (pathsuffix(fn)=="") fn = fn + `ESTWRITE_SUFFIX'
    if (fileexists(fn)==0) {
        if (st_local("append")!="") {
            printf("{txt}(note: file %s not found)\n", fn)
            st_local("append", "")
        }
    }
    else {
        if (st_local("replace")=="") {
            errprintf("file %s already exists\n", fn)
            exit(602)
        }
    }
}

string scalar estwrite_file_read(ests, id)
{
    string scalar   fn, ster
    real scalar     fh, a, b
    /* ------------------------------------------------------------ */
    fn = st_local("using")
    if (pathsuffix(fn)=="") fn = fn + `ESTWRITE_SUFFIX'
    if (!fileexists(fn)) {
        errprintf("file %s not found\n", fn)
        exit(601)
    }
    if ((fh = _fopen(fn, "r"))<0) {
        errprintf("file %s could not be opened for input\n", fn)
        exit(603)
    }
    /* ------------------------------------------------------------ */
    if (fget(fh) != `ESTWRITE_SIGNATURE') {
        errprintf("file %s not estwrite format\n", fn)
        (void) _fclose(fh)
        exit(610)
    }
    if (_fget(fh)==J(0,0,""))     estwrite_readerror(fh, fn)  // date
    if (_fget(fh)==J(0,0,""))     estwrite_readerror(fh, fn)  // end of header
    if ((ests = _fgetmatrix(fh))==J(0, 0, .))   estwrite_readerror(fh, fn)
    if ((id = _fgetmatrix(fh))==J(0, 0, .))     estwrite_readerror(fh, fn)
    /* ------------------------------------------------------------ */
    if ((a = _ftell(fh))<0)     estwrite_readerror(fh, fn)
    if (_fseek(fh, 0, 1)<0)     estwrite_readerror(fh, fn)
    if ((b = _ftell(fh))<0)     estwrite_readerror(fh, fn)
    if (_fseek(fh, a, -1)<0)    estwrite_readerror(fh, fn)
    if ((ster = _fread(fh, b-a))==J(0,0,"")) estwrite_readerror(fh, fn)
    /* ------------------------------------------------------------ */
    (void) _fclose(fh)
    return(ster)
}

void estwrite_readerror(fh, fn)
{
    real scalar status

    status = fstatus(fh)
    if (status>=0) return
    (void) _fclose(fh)
    if (status==-1) {
        errprintf("%s: unexpected end of file\n", fn)
        exit(692)
    }
    exit(error(status))
}

pointer(struct estwrite_estimates scalar) colvector estwrite_estimates_init()
{
    pointer(struct estwrite_estimates scalar) colvector e

    e = J(cols(tokens(st_local("names"))), 1, NULL)
    return(e)
}

struct estwrite_estimates scalar estwrite_estimates_get(real scalar ster)
{
    struct estwrite_estimates scalar    e
    real scalar                         i
    string scalar                       pattern
    /* ------------------------------------------------------------ */
    e.isster = ster
    if (e.isster==0)
        pattern = "*"      // get all e()-results
    else {
        pattern = "_*"     // -estimates save- omits e()'s that start with "_"
        e.isster = e.isster + (stataversion()>=1100)  // e.isster = 2 in Stata 11
    }
    e.name   = st_local("name")
    e.macnms = st_dir("e()", "macro", pattern, 1)
    e.scanms = st_dir("e()", "numscalar", pattern, 1)
    e.matnms = st_dir("e()", "matrix", pattern, 1)
    /* ------------------------------------------------------------ */
    e.macros = J(rows(e.macnms),1,"")
    for (i=1; i<=rows(e.macnms); i++) {
        e.macros[i] = st_global(e.macnms[i])
    }
    /* ------------------------------------------------------------ */
    e.scalars = J(rows(e.scanms),1,.)
    for (i=1; i<=rows(e.scanms); i++) {
        e.scalars[i] = st_numscalar(e.scanms[i])
    }
    /* ------------------------------------------------------------ */
    e.matrown  = J(rows(e.matnms),1,NULL)
    e.matcoln  = J(rows(e.matnms),1,NULL)
    e.matrices = J(rows(e.matnms),1,NULL)
    for (i=1; i<=rows(e.matnms); i++) {
        e.matrown[i]  = &(st_matrixrowstripe(e.matnms[i]))
        e.matcoln[i]  = &(st_matrixcolstripe(e.matnms[i]))
        e.matrices[i] = &(st_matrix(e.matnms[i]))
    }
    /* ------------------------------------------------------------ */
    if (st_local("id")!="" & st_local("hasesample")=="1") {
        e.sample = st_data(.,st_local("esample"))
    }
    /* ------------------------------------------------------------ */
    return(e)
}

struct estwrite_fh scalar estwrite_file_init(estimates, id)
{
    struct estwrite_fh scalar f
    real scalar replace

    /* ------------------------------------------------------------ */
    f.fn    = st_local("using")
    replace = (st_local("replace")!="")
    if (pathsuffix(f.fn)=="") f.fn = f.fn + `ESTWRITE_SUFFIX'
    if (replace==0) {
        if (fileexists(f.fn)) {
            errprintf("file %s already exists\n", f.fn)
            //rmexternal("ESTWRITE_FH")
            exit(602)
        }
    }
    else {
        if (_unlink(f.fn)<0) {
            errprintf("file %s could not be replaced\n", f.fn)
            //rmexternal("ESTWRITE_FH")
            exit(693)
        }
    }
    /* ------------------------------------------------------------ */
    if ((f.fh = _fopen(f.fn, "w"))<0) {
        errprintf("file %s could not be opened for output\n", f.fn)
        //rmexternal("ESTWRITE_FH")
        exit(603)
    }
    if (_fput(f.fh, `ESTWRITE_SIGNATURE')<0)  estwrite_writeerror(f)
    if (_fput(f.fh, `ESTWRITE_DATETIME')<0)   estwrite_writeerror(f)
    if (_fput(f.fh, `ESTWRITE_ENDHEADER')<0)  estwrite_writeerror(f)
    if (_fputmatrix(f.fh, estimates)<0)       estwrite_writeerror(f)
    if (_fputmatrix(f.fh, id)<0)              estwrite_writeerror(f)
    /* ------------------------------------------------------------ */
    f.fn2 = st_tempfilename() // used by estwrite_appendcurrent()
    return(f)
}

void estwrite_writeerror(struct estwrite_fh scalar f)
{
    errprintf("error writing file %s\n", f.fn)
    (void) _fclose(f.fh)
    (void) _unlink(f.fn)
    //rmexternal("ESTWRITE_FH")
    exit(693)
}

void estwrite_appendster(struct estwrite_fh scalar f, string scalar ster)
{
    if (_fwrite(f.fh, ster)<0)  estwrite_writeerror(f)
}

void estwrite_appendcurrent(struct estwrite_fh scalar f)
{
    real scalar     l

    if (stataversion()<1100)    __st_estimatessave_wrk(f.fh)
    else {
        if (fileexists(f.fn2)) unlink(f.fn2)
        f.fh2 = fopen(f.fn2, "rw")
        __st_estimatessave_wrk(f.fh2, f.fn2)
        l = ftell(f.fh2)
        fputmatrix(f.fh, l)
        fseek(f.fh2, 0, -1)
        fwrite(f.fh, fread(f.fh2, l))
        fclose(f.fh2)
    }
}

void estwrite_fclose(struct estwrite_fh scalar f)
{
    printf("{txt}(file %s saved)\n", f.fn)
    (void) _fclose(f.fh)
}

end
