set -a # export all vars
# set -x # debug

libname=tjr_btree
Libname=Tjr_btree

root=$(realpath $(dirname $BASH_SOURCE))/../..

 # if using nix, this may not be present
test -f $root/config.sh && source $root/config.sh

PKGS1="num,yojson,ppx_deriving_yojson,batteries,extunix,extlib"
PKGS="-package num,yojson,ppx_deriving_yojson,batteries,extunix,extlib"

SYNTAX="" # "-syntax camlp4o" # simplify: use for every file
FLGS="-g -thread"
FOR_PACK="-for-pack $Libname"

    # 8~"pattern-matching is not exhaustive"; 
    # 11~"this match case is unused";
    # 26~"unused variable s2"
    # 40~It is not visible in the current scope, and will not be selected if the type becomes unknown.
WARN="-w @f@p@u@s@40-8-11-26-40"

    # these include syntax, so should work on all files; may be
    # overridden in ocamlc.sh
  ocamlc="$DISABLE_BYTE ocamlfind ocamlc              $FLGS $FOR_PACK $WARN $PKGS $SYNTAX"
ocamlopt="$DISABLE_NTVE ocamlfind ocamlopt -bin-annot $FLGS $FOR_PACK $WARN $PKGS $SYNTAX"
ocamldep="ocamlfind ocamldep $PKGS"

# mls ----------------------------------------

mls=`test -e _depend/n_doc && cat _depend/*`

cmos="${mls//.ml/.cmo}"
cmxs="${mls//.ml/.cmx}"

natives="main.native test_main.native simple_example.native"

bytes="test_main.byte"

bcd=`echo {ad,ag,b,c,d,e,f,g,h,i,j,n}_*`
bcd_mls=`ls {ad,ag,b,c,d,e,f,g,h,i,j,n}_*/*.ml`


# cma,cmxa -------------------------------------------------------------

function mk_cma() {
	$DISABLE_BYTE ocamlfind ocamlc -pack -o $libname.cmo $cmos
  $DISABLE_BYTE ocamlfind ocamlc -g -a -o $libname.cma $libname.cmo
}

function mk_cmxa() {
	$DISABLE_NTVE ocamlfind ocamlopt -pack -o $libname.cmx $cmxs
  $DISABLE_NTVE ocamlfind ocamlopt -g -a -o $libname.cmxa $libname.cmx
}


# depend ----------------------------------------

function mk_depend() {
    mkdir -p _depend
    for f in ${bcd}; do
    # for f in {b,c}_* d_core; do
        (cd $f && ocamldep -one-line -sort *.ml > ../_depend/$f)
    done
}



# links ----------------------------------------

function init() {
    link_files="${bcd_mls}"
}

function mk_links() {
    echo "mk_links..."
    init
    ln -s $link_files .
}


function rm_links() {
    echo "rm_links..."
    init
    for f in $link_files; do rm -f `basename $f`; done
}


# mlis ----------------------------------------

function mk_mlis() {
    echo "mk_mlis..."
    for f in $mls; do $ocamlc -i $f > tmp/${f/.ml/.mli}; done
}



# meta ----------------------------------------

function mk_meta() {
local gv=`git rev-parse HEAD`
local d=`date`
cat >META <<EOF
name="$libname"
description="Pure functional B-tree implementation"
version="$d $gv"
requires="$PKGS1"
archive(byte)="$libname.cma"
archive(native)="$libname.cmxa"
EOF

}


# codetags ----------------------------------------

function mk_codetags() {
    init # link_files
    for f in XXX TODO FIXME NOTE QQQ; do     # order of severity
        grep --line-number $f $link_files || true; 
    done
}


# doc ----------------------------------------------------

function mk_doc() {
    ocamlfind ocamldoc $PKGS $WARN -html `cat _depend/*`
}


# ocamlfind install, remove, reinstall --------------------

function install() {
	  ocamlfind install $libname META $libname.{cmi,cma,cmxa,a}
}

function remove() {
    ocamlfind remove $libname
}


# # new_bak ----------------------------------------
# 
# function new_bak() {
#     local n=1 
#     while [ -f "$1.bak.$n" ]; do ((++n)); done
#     echo "$1.bak.$n"
# }

