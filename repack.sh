function patch_prefix ()
{
  #hack needed for openssl which generates paths like "z:/build/dir/..."
  OUT2=`echo "$OUT"| sed -e "s,^/\([a-zA-Z]\)/,\1:/,"`
  #echo "patch_prefix (OUT=$OUT OUT2=$OUT2)"
  for F in $@; do
    echo "gonna patch.prefix $F"
    if [ -e $F ] ; then
      if [ ! -e $F.backup ] ; then cp $F $F.backup; fi
      #echo "patch_prefix (sed $F.backup > $F)"
      sed -e "s,$OUT2,/mingw,gi" \
          -e "s,c:.Windows.System32.\([^\.]*\).dll,-l\1,gi" \
	  -e "s,$OUT,/mingw,gi" $F.backup > $F
    fi 
  done
}

PKGLISTNAME=$1
DLLSUFFIX=$2

CURDIR=`pwd`
WRKDIR=$CURDIR/_$PKGLISTNAME$DLLSUFFIX.src
OUTZIP=$CURDIR/_$PKGLISTNAME$DLLSUFFIX.patched
OUTTMP=$CURDIR/_$PKGLISTNAME$DLLSUFFIX.tmp
OUT=$CURDIR/_$PKGLISTNAME$DLLSUFFIX

if [ ! -d $OUT ]    ; then echo "dir '$OUT' not found!" && exit    ; fi
if [ ! -d $WRKDIR ] ; then echo "dir '$WRKDIR' not found!" && exit ; fi

echo "### creating a copy for patching"
rm -rf $OUTTMP
cp -r $OUT $OUTTMP

cd $OUTTMP
strip -S bin/*.dll 2>/dev/null
strip -S bin/*.exe 2>/dev/null
#ugly hack handling prefixes like 'z:/path/to/prefix/dir'
OUT2=`echo "$OUT"| sed -e "s!^/\([a-zA-Z]\)/!\1:/!"`
L=`find . -type f \( -name "*.la" -o -name "*.pc" -o -name "*.sh" -o -name "*-config" \) | xargs grep -l -i -e "$OUT" -e "$OUT2"`
patch_prefix $L
rm -f $OUTZIP/out_all_results.txt
for PACK in $OUT/*.list
do
  PACK=`basename $PACK|sed s/\.list//`
  echo "processing PACK='$PACK'"
  rm -f $OUTZIP/out_$PACK.zip
  touch `cat $OUT/$PACK.list`
  zip -q -9 $OUTZIP/out_$PACK.zip -@ < $OUT/$PACK.list  
  echo "$PACK" >> $OUTZIP/out_all_results.txt
  grep "^\#\#\#" $PACK.build.log >> $OUTZIP/out_all_results.txt
done
cd ..

#rm -rf $OUTTMP

./pack.pl $WRKDIR

echo "###### [`date +%T`] PACKING FINISHED"

