#ifndef _NONPOSIX_H
#define _NONPOSIX_H

#ifdef _WIN32

#include <sys/stat.h>
#include <stdio.h>
#include <direct.h>
#include <fcntl.h>

#define _stat	_stati64
#define stat	_stati64
#define _fstat	_fstati64
#define fstat	_fstati64
#define off_t	__int64
#define	lseek       _lseeki64
#define	lseek64     _lseeki64
#define	tell        _telli64
#define	tell64      _telli64

#ifndef _S_IFSOCK
#define  _S_IFSOCK       0xC000    /* socket */
#define  _S_ISSOCK(m)    (((m) & _S_IFMT) == _S_IFSOCK)
#define __S_IFSOCK       _S_IFSOCK
#define   S_IFSOCK       _S_IFSOCK
#define   S_ISSOCK(m)   _S_ISSOCK(m)
#endif /* _S_IFSOCK  */

#ifdef __MINGW32__
# define fseek      fseeko64
# define fseeko     fseeko64
# define ftell      ftello64
# define ftello     ftello64
# define ftell64    ftello64
# define HAVE_FSEEKO 1
#endif

#ifndef O_NONBLOCK
#define O_NONBLOCK 0
#endif

#define NULL_DEVICE "NUL"
#define TTY_DEVICE "CON"

#define mkdir(name, mode) ((_mkdir) (name))
#define rename(old,new) w32_rename(old,new)

#ifndef HAVE_DOS_FILE_NAMES
# define HAVE_DOS_FILE_NAMES 0
#endif

#ifndef filename_char_eq
# define filename_char_eq(c1,c2)  ((c1) == (c2))
#else
# include <ctype.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

extern int w32_rename (const char *old, const char *new);

#ifdef __cplusplus
}
#endif

#endif /* _WIN32 */

#endif /* _NONPOSIX_H */
