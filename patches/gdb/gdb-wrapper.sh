mkdir -p $BUILDS_DIR/gdb-wrapper
cd $BUILDS_DIR/gdb-wrapper

$HOST-gcc ${COMMON_CFLAGS} -U_DEBUG -o gdb.exe ${SOURCES_DIR}/gdb-wrapper/gdb-wrapper.c || { die "cannot build gdb-wrapper.exe"; }

	echo -n "--> installing..."
	[[ ! -f $PREFIX/bin/gdborig.exe ]] && {
		mv $PREFIX/bin/gdb.exe $PREFIX/bin/gdborig.exe
	}
    
cp -f gdb.exe $PREFIX/bin || die "Cannot copy gdb.exe to $PREFIX/bin"
