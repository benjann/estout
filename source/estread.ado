*! version 1.2.5 25jun2012
*! version 1.0.1 15may2007 (renamed from -estget- to -estread-)
*! version 1.0.0 29apr2005 Ben Jann (ETH Zurich)
prog define estread
    version 8.2
    gettoken fn comma : 0, parse(" ,")
    gettoken comma : comma, parse(" ,")
    if `"`comma'"'=="," | `"`comma'"'=="" {
        local 0 `"using `macval(0)'"'
    }
    syntax [anything] using [, id(varname) estsave Describe ]
    if c(stata_version)<9 | "`estsave'"!="" {
        estread_dta `macval(0)'
        exit
    }
    capt mata: mata drop ESTWRITE_FH
    capt mata: mata drop ESTWRITE_ESTS
    capt mata: mata drop ESTWRITE_ID
    capt n estread_mata `macval(0)'
    local rc = _rc
    if `rc' {
        capt mata: mata describe ESTWRITE_FH
        if _rc==0 {
            capt mata: estread_fclose(ESTWRITE_FH)
        }
    }
    capt mata: mata drop ESTWRITE_FH
    capt mata: mata drop ESTWRITE_ESTS
    capt mata: mata drop ESTWRITE_ID
    exit `rc'
end

prog define estread_dta, sortpreserve
    version 8.2
    syntax [anything] using [, id(varname) estsave Describe ]
    if `"`anything'"'=="_all" local anything "*"

    if "`describe'"!="" {
        local temp
        foreach var of local anything {
            local temp `"`temp'_ests_`var' "'
        }
        describe `temp' `using', varlist
        foreach var in `r(varlist)' {
            local name: subinstr local var "_ests_" ""
            local names "`names'`name' "
        }
        local names: list retok names
        ResetRNames `"`names'"'
        exit
    }

    if `"`anything'"'=="" local anything "*"
    qui describe `using', varlist
    foreach var in `r(varlist)' {
        if substr("`var'",1,6) == "_ests_" {
            local match 0
            foreach tmp of local anything {
                if match(`"`var'"',`"_ests_`tmp'"') local match 1
            }
            if `match'==0 continue
            confirm new var `var'
            local vars "`vars'`var' "
        }
    }
    local vars: list retok vars
    if `"`vars'"'=="" {
        di as err "no estimates to be restored"
        exit 111
    }
    capt which estsave
    if _rc {
        di as error "-estsave- by Michael Blasnik required; type {stata ssc install estsave}"
        error 499
    }
    if "`id'"!="" {
        local unique unique
        sort `id'
    }
    tempvar merge
    merge `id' `using', nolabel nonotes nokeep `unique' _merge(`merge') keep(`vars')
    drop `merge'
    tempname hcurrent
    _est hold `hcurrent', restore estsystem nullok
    local i 0
    foreach var of local vars {
        local name: subinstr local var "_ests_" ""
        qui replace `var' = 0 if `var'>=.
        qui estsave , from(`var') replace
        if "`name'"=="_active" {
            nobreak {
                _est unhold `hcurrent', not
                tempname hcurrent
                _est hold `hcurrent', restore estsystem nullok
                local name "."
            }
        }
        else est sto `name', title(`"`e(_estimates_title)'"')
        local names "`names'`name' "
    }
    drop `vars'
    _est unhold `hcurrent'
    est dir `names'
end

prog define estread_mata, sortpreserve
    version 9.2
    syntax [anything] using/ [, id(varname) estsave Describe ]
    if `"`anything'"'=="_all" local anything "*"
    local noster = (c(stata_version)<10) + (c(stata_version)<11)

    mata: ESTWRITE_FH = estread_file_read(ESTWRITE_ESTS=., ESTWRITE_ID=.) // sets local date
    capt mata: assert(ESTWRITE_ID==J(0,1,.))
    local hasid = (_rc!=0)

    if "`describe'"!="" {
        mata: estread_fclose(ESTWRITE_FH)
        mata: estread_estimates_dir(ESTWRITE_ESTS) // sets local names
        ResetRNames `"`names'"'
        exit
    }

    if "`id'"!="" {
        if `hasid'==0 {
            di as err "using file has no ID; id() not allowed"
            exit 198
        }
        isid `id'
        sort `id'
        capt confirm string variable `id'
        local idisstr = (_rc==0)
        tempname esample
        mata: ESTWRITE_ID = estread_estimates_mergeid(ESTWRITE_ID)
    }
    else mata: ESTWRITE_ID = (., .)
    mata: estread_estimates_info(ESTWRITE_ESTS) // sets locals n_est, n_active

    tempname hcurrent
    _est hold `hcurrent', restore estsystem nullok
    tempname bb VV
    forv i=1/`n_est' {
        mata: estread_get_name_status(*ESTWRITE_ESTS[`i']) // sets locals name and isster
        if `"`name'"'=="" {
                if `isster' & (`noster'<2) {
                    if `isster'==2 capt n mata: estread_get_skip11(ESTWRITE_FH)
                    else {
                        ereturn clear
                        capt n mata: estread_get_ster(ESTWRITE_FH)
                    }
                    if _rc {
                        di as err "something is wrong; could not recover estimation set"
                        mata: estread_fclose(ESTWRITE_FH)
                        exit _rc
                    }
                }
            continue
        }
        if `isster' {
            if `noster' {
                if `isster'==2 {
                    di as txt `"(`name' is in Stata 11 format; cannot restore)"'
                    if `noster'==1 mata: estread_get_skip11(ESTWRITE_FH)
                    continue
                }
                if `noster'==2 {
                    di as txt `"(`name' is in Stata 10 format; cannot restore)"'
                    continue
                }
            }
            ereturn clear
            if `isster'==2 capt n mata: estread_get_ster11(ESTWRITE_FH)
            else           capt n mata: estread_get_ster(ESTWRITE_FH)
            if _rc {
                di as err "something is wrong; could not recover estimation set"
                mata: estread_fclose(ESTWRITE_FH)
                exit _rc
            }
            mata: estread_get_esamp(*ESTWRITE_ESTS[`i'], ESTWRITE_ID)
            mata: estread_get_rest(*ESTWRITE_ESTS[`i'])
            if `"`esamp'"'!="" {
                local esampeho `"`e(_estimates_sample)'"'
                estimates esample: if `esample'
                capt drop `esample'
                EsampWhoReset `"`esampeho'"'
            }
            else EsampWhoReset
        }
        else {
            mata: estread_get_bV(*ESTWRITE_ESTS[`i'])
            mata: estread_get_esamp(*ESTWRITE_ESTS[`i'], ESTWRITE_ID)
            if `"`esamp'"'!="" {
                qui replace `esample' = 0 if `esample'>=.
            }
            eret post `b' `V', `esamp' `depname' `obs' `df_r'
            mata: estread_get_rest(*ESTWRITE_ESTS[`i'])
        }
        if "`name'"=="." {
            if `n_active'>1 {
                local name "_estread_`i'"
                estimates store `name' //_est hold `name', estimates varname(_est_`name')
            }
            else {
                _est unhold `hcurrent', not
                tempname hcurrent
                _est hold `hcurrent', restore estsystem nullok
            }
        }
        else est sto `name' //_est hold `name', estimates varname(_est_`name')
        local names "`names'`name' "
    }
    mata: estread_fclose(ESTWRITE_FH)
    _est unhold `hcurrent'
    if `"`names'"'!="" {
        est dir `names'
    }
    else {
        di as txt `"(no sets restored)"'
        ResetRNames
    }
end

prog EsampWhoReset, eclass
    eret local _estimates_sample `0'
end

prog ResetRNames, rclass
    ret local names `0'
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

struct estwrite_fh scalar estread_file_read(ests, id)
{
    struct estwrite_fh scalar f
    string scalar date
    /* ------------------------------------------------------------ */
    f.fn = st_local("using")
    if (pathsuffix(f.fn)=="") f.fn = f.fn + `ESTWRITE_SUFFIX'
    if (!fileexists(f.fn)) {
        errprintf("file %s not found\n", f.fn)
        //rmexternal("ESTWRITE_FH")
        exit(601)
    }
    if ((f.fh = _fopen(f.fn, "r"))<0) {
        errprintf("file %s could not be opened for input", f.fn)
        //rmexternal("ESTWRITE_FH")
        exit(603)
    }
    /* ------------------------------------------------------------ */
    if (fget(f.fh) != `ESTWRITE_SIGNATURE') {
        errprintf("file %s not estwrite format\n", f.fn)
        (void) _fclose(f.fh)
        //rmexternal("ESTWRITE_FH")
        exit(610)
    }
    if ((date=_fget(f.fh))==J(0,0,""))     estread_readerror(f)  // date
    if (_fget(f.fh)==J(0,0,""))     estread_readerror(f)  // end of header
    if ((ests = _fgetmatrix(f.fh))==J(0, 0, .))   estread_readerror(f)
    if ((id = _fgetmatrix(f.fh))==J(0, 0, .))     estread_readerror(f)
    /* ------------------------------------------------------------ */
    f.fn2 = st_tempfilename() // used by estread_get_ster11()
    st_local("date", substr(date,9,.))
    return(f)
}

void estread_readerror(struct estwrite_fh scalar f)
{
    real scalar status

    status = fstatus(f.fh)
    if (status>=0) return
    (void) _fclose(f.fh)
    if (status==-1) {
        errprintf("%s: unexpected end of file", f.fn)
        //rmexternal("ESTWRITE_FH")
        exit(692)
    }
    //rmexternal("ESTWRITE_FH")
    exit(error(status))
}

void estread_fclose(struct estwrite_fh scalar f)
{
    (void) _fclose(f.fh)
}

void estread_estimates_dir(
    pointer(struct estwrite_estimates scalar) colvector e
    )
{
    string scalar       names, w
    string matrix       res
    string rowvector    match
    real scalar         i, j, hasid, l


    hasid = (st_local("hasid")=="1")
    match = tokens(st_local("anything"))
    if (cols(match)==0) match = "*"
    res = J(rows(e),3,"")
    j = 0
    for (i=1; i<=rows(e); i++) {
        if (any(strmatch((*e[i]).name, match))) {
            res[++j,1] = (*e[i]).name
            res[j,2] = ((*e[i]).isster==0 ? "Stata 9" :
                       ((*e[i]).isster==1 ? "Stata 10" : "Stata 11"))
            res[j,3] = (hasid & rows((*e[i]).sample)>0 ? "yes" : "no")
            names = names + (i==1 ? "" : " ") + res[j,1]
        }
    }
    if (j==0) res = J(0,3,"")
    else if (j<i) res = res[|1,1 \ j,.|]
    l = min(( max(( max(strlen(res[,1])) ,10)) , 30))
    w = strofreal(l+2+9+1+9)
    printf("\n%"+w+"s\n", st_local("date"))
    //if (rows(res)>0) {
        display("{txt}{hline "+w+"}")
        printf("{txt}%-"+strofreal(l)+"s  format    e(sample)\n", "name")
        display("{txt}{hline "+w+"}")
        for (i=1; i<=rows(res); i++) {
            printf("{res}%-"+strofreal(l)+"s  {txt}%-9s %~9s\n",
                res[i,1], res[i,2], res[i,3])
        }
        display("{txt}{hline "+w+"}")
    //}
    st_local("names", names)
}

void estread_estimates_info(
    pointer(struct estwrite_estimates scalar) colvector e
    )
{
    real scalar     i, nactive

    nactive = 0
    for (i=1; i<=rows(e); i++) {
        nactive = nactive + ((*e[i]).name==".")
    }
    st_local("n_active", strofreal(nactive))
    st_local("n_est", strofreal(rows(e)))
}

real matrix estread_estimates_mergeid(transmorphic colvector id)
{
    transmorphic colvector  id0
    real scalar             idvar, i, i0, j
    real matrix             p

    idvar = st_varindex(st_local("id"))
    if (st_isstrvar(idvar)) st_sview(id0,.,idvar)
    else                    st_view(id0,.,idvar)

    if (eltype(id0)!=eltype(id)) {
        if (isstring(id)) display("{err}string ID in using file; id() must be string{txt}")
        else              display("{err}numeric ID in using file; id() must be numeric{txt}")
        exit(109)
    }

    if (id0==id) {
        return((., .))
    }

    p = J(min((rows(id0),rows(id))), 2, .)
    j = 0
    i0 = 1
    for (i=1; i<=rows(id); i++) {
        if (id[i]<id0[i0]) continue
        while (id[i]>id0[i0] & i0<rows(id0)) i0++
        if (id[i]==id0[i0]) {
            p[++j,] = i0, i
        }
    }
    if (j<rows(p)) {
        if (j>0) p = p[| 1,1 \ j,.|]
        else     p = J(0,2,.)
    }
    if (j<rows(id))  printf("{txt}(%g unmatched observation"
        + ((rows(id)-j)==1 ? "" : "s") + " in using file; observation"
        + ((rows(id)-j)==1 ? "" : "s") + " discarded)\n",rows(id)-j)
    if (j<rows(id0)) printf("{txt}(%g unmatched observation"
        + ((rows(id0)-j)==1 ? "" : "s")
        + " in master data; e(sample) set to zero)\n",rows(id0)-j)
    return(p)
}

void estread_get_ster(struct estwrite_fh scalar f)
{
    if (stataversion()<1100)    __st_estimatesuse_wrk(f.fh, f.fn)
    else                        __st_estimatesuse_wrk(f.fh, f.fn, 1)
}

void estread_get_ster11(struct estwrite_fh scalar f)
{
    real scalar     l

    if (fileexists(f.fn2)) unlink(f.fn2)
    f.fh2 = fopen(f.fn2, "rw")
    l = fgetmatrix(f.fh)
    fwrite(f.fh2, fread(f.fh, l))
    fseek(f.fh2, 0, -1)
    __st_estimatesuse_wrk(f.fh2, f.fn2, 1)
    fclose(f.fh2)
}

void estread_get_skip11(struct estwrite_fh scalar f)
{
    real scalar     l

    l = fgetmatrix(f.fh)
    fseek(f.fh, l, 0)
}


void estread_get_name_status(struct estwrite_estimates scalar e)
{
    string rowvector    match

    match = tokens(st_local("anything"))
    if (cols(match)==0) match = "*"
    if (any(strmatch(e.name, match))) st_local("name",e.name)
    else                              st_local("name", "")
    st_local("isster", strofreal(e.isster))
}

void estread_get_esamp(struct estwrite_estimates scalar e, real matrix id)
{
    if (st_local("id")!="" & st_local("hasid")=="1" & rows(e.sample)>0) {
        st_store(id[,1], st_addvar("byte", st_local("esample")), e.sample[id[,2]])
        st_local("esamp","esample("+st_local("esample")+")")
    }
    else st_local("esamp","")
}

void estread_get_bV(struct estwrite_estimates scalar e)
{
    real colvector  p
    real scalar     hasb, hasV

    // depname
    if (rows(e.macnms)>0) {
        p = estread_which(e.macnms:=="e(depvar)")
        if (rows(p)>0) {
            st_local("depname","depname(" + tokens(e.macros[p])[1] + ")")
        }
        else st_local("depname","")
    }

    if (rows(e.scanms)>0) {
        // obs
        p = estread_which(e.scanms:=="e(N)")
        if (rows(p)>0) {
            st_local("obs","obs(" + strofreal(e.scalars[p]) + ")")
        }
        else st_local("obs","")

        // df_r
        p = estread_which(e.scanms:=="e(df_r)")
        if (rows(p)>0) {
            st_local("df_r","dof(" + strofreal(e.scalars[p]) + ")")
        }
        else st_local("df_r","")
    }

    // b and V
    hasb = hasV = 0
    if (rows(e.matnms)>0) {
        p = estread_which(e.matnms:=="e(b)")
        if (rows(p)>0) {
            // b
            if ((rows(*e.matrices[p]) * cols(e.matrices[p]))>0) {
                hasb = 1
                st_local("b",st_local("bb"))
                st_matrix(st_local("b"),*e.matrices[p])
                st_matrixrowstripe(st_local("b"), *e.matrown[p])
                st_matrixcolstripe(st_local("b"), *e.matcoln[p])

                // V
                p = estread_which(e.matnms:=="e(V)")
                if (rows(p)>0) {
                    if ((rows(*e.matrices[p]) * cols(e.matrices[p]))>0) {
                        hasV = 1
                        st_local("V",st_local("VV"))
                        st_matrix(st_local("V"), *e.matrices[p])
                        st_matrixrowstripe(st_local("V"), *e.matrown[p])
                        st_matrixcolstripe(st_local("V"), *e.matcoln[p])
                    }
                }
            }
        }
    }
    if (hasb==0) st_local("b","")
    if (hasV==0) st_local("V","")
}

void estread_get_rest(struct estwrite_estimates scalar e)
{
    real scalar i

    for (i=1; i<=rows(e.macnms); i++) {
        st_global(e.macnms[i], e.macros[i])
    }

    for (i=1; i<=rows(e.scanms); i++) {
        if (e.scanms[i]=="e(N)" | e.scanms[i]=="e(df_r)") continue
        st_numscalar(e.scanms[i], e.scalars[i])
    }

    for (i=1; i<=rows(e.matnms); i++) {
        if (e.matnms[i]=="e(b)" | e.matnms[i]=="e(V)") continue
        st_matrix(e.matnms[i], *e.matrices[i])
        st_matrixrowstripe(e.matnms[i], *e.matrown[i])
        st_matrixcolstripe(e.matnms[i], *e.matcoln[i])
    }
}

real matrix estread_which(real colvector I)
{
        return(select(1::rows(I), I))
}

end
