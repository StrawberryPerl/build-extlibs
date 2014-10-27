/* flatfile.c - Import/export a GDBM database. */

/* This file is part of GDBM, the GNU data base manager.
   Copyright (C) 2007, 2011 Free Software Foundation, Inc.

   GDBM is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3, or (at your option)
   any later version.

   GDBM is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with GDBM. If not, see <http://www.gnu.org/licenses/>.   */

#ifndef _GDBMEXPORT_

/* Include system configuration before all else. */
#include "autoconf.h"
#if _WIN32
#include <winsock.h>
#else
#include <arpa/inet.h>
#endif

#include "gdbmdefs.h"
#include "gdbm.h"

#endif

int
gdbm_export (GDBM_FILE dbf, const char *exportfile, int flags, int mode)
{
  int nfd, size;
  datum key, nextkey, data;
  const char *header1 = "!\r\n! GDBM FLAT FILE DUMP -- THIS IS NOT A TEXT FILE\r\n! ";
  const char *header2 = "\r\n!\r\n";
  int count = 0;

  /* Only support GDBM_WCREAT or GDBM_NEWDB */
  switch (flags)
    {
    case GDBM_WRCREAT:
      nfd = open (exportfile, O_WRONLY | O_CREAT | O_EXCL, mode);
      if (nfd == -1)
	{
	  gdbm_errno = GDBM_FILE_OPEN_ERROR;
	  return -1;
	}
      break;
    case GDBM_NEWDB:
      nfd = open (exportfile, O_WRONLY | O_CREAT | O_TRUNC, mode);
      if (nfd == -1)
	{
	  gdbm_errno = GDBM_FILE_OPEN_ERROR;
	  return -1;
	}
      break;
    default:
#ifdef GDBM_BAD_OPEN_FLAGS
      gdbm_errno = GDBM_BAD_OPEN_FLAGS;
#else
      gdbm_errno = GDBM_FILE_OPEN_ERROR;
#endif
      return -1;
  }
  
  /* Write out the text header. */
  if (write (nfd, header1, strlen (header1)) != strlen (header1))
    goto write_fail;
  if (write (nfd, gdbm_version, strlen (gdbm_version)) != strlen (gdbm_version))
    goto write_fail;
  if (write (nfd, header2, strlen (header2)) != strlen (header2))
    goto write_fail;

  /* For each item in the database, write out a record to the file. */
  key = gdbm_firstkey (dbf);

  while (key.dptr != NULL)
    {
      data = gdbm_fetch (dbf, key);
      if (data.dptr != NULL)
 	{
	  /* Add the data to the new file. */
	  size = htonl (key.dsize);
	  if (write (nfd, &size, sizeof(int)) != sizeof (int))
	    goto write_fail;
	  if (write (nfd, key.dptr, key.dsize) != key.dsize)
	    goto write_fail;

	  size = htonl (data.dsize);
	  if (write (nfd, &size, sizeof(int)) != sizeof (int))
	    goto write_fail;
	  if (write (nfd, data.dptr, data.dsize) != data.dsize)
	    goto write_fail;
 	}
      nextkey = gdbm_nextkey (dbf, key);
      free (key.dptr);
      free (data.dptr);
      key = nextkey;
      
      count++;
    }
  close (nfd);
  
  return count;
  
 write_fail:
  
  gdbm_errno = GDBM_FILE_WRITE_ERROR;
  return -1;
}

#ifndef _GDBMEXPORT_

int
gdbm_import (GDBM_FILE dbf, const char *importfile, int flag)
{
  int ifd, seenbang, seennewline, rsize, size, kbufsize, dbufsize, rret;
  char c, *kbuffer, *dbuffer;
  datum key, data;
  int count = 0;

  ifd = open (importfile, O_RDONLY, 0);
  if (ifd == -1)
    {
      gdbm_errno = GDBM_FILE_OPEN_ERROR;
      return -1;
    }

  seenbang = 0;
  seennewline = 0;
  kbuffer = NULL;
  dbuffer = NULL;

  /* Read (and discard) four lines begining with ! and ending with \n. */
  while (1)
    {
      if (read (ifd, &c, 1) != 1)
	goto read_fail;

      if (c == '!')
	seenbang++;
      if (c == '\n')
	{
	  if (seenbang > 3 && seennewline > 2)
	    {
	      /* End of last line. */
	      break;
	    }
	  seennewline++;
	}
    }

  /* Allocate buffers. */
  kbufsize = 512;
  kbuffer = malloc (kbufsize);
  if (kbuffer == NULL)
    {
      gdbm_errno = GDBM_MALLOC_ERROR;
      close (ifd);
      return -1;
    }
  dbufsize = 512;
  dbuffer = malloc (dbufsize);
  if (dbuffer == NULL)
    {
      gdbm_errno = GDBM_MALLOC_ERROR;
      close (ifd);
      return -1;
    }

  /* Insert/replace records in the database until we run out of file. */
  while ((rret = read (ifd, &rsize, sizeof(rsize))) != 0)
    {
      if (rret != sizeof(rsize))
	goto read_fail;

      /* Read the key. */
      size = ntohl (rsize);
      if (size > kbufsize)
	{
	  kbufsize = (size + 512);
	  kbuffer = realloc (kbuffer, kbufsize);
	  if (kbuffer == NULL)
	    {
	      gdbm_errno = GDBM_MALLOC_ERROR;
	      close (ifd);
	      return -1;
	    }
	}
      if (read (ifd, kbuffer, size) != size)
	goto read_fail;

      key.dptr = kbuffer;
      key.dsize = size;

      /* Read the data. */
      if (read (ifd, &rsize, sizeof(rsize)) != sizeof(rsize))
	goto read_fail;

      size = ntohl (rsize);
      if (size > dbufsize)
	{
	  dbufsize = (size + 512);
	  dbuffer = realloc (dbuffer, dbufsize);
	  if (dbuffer == NULL)
	    {
	      gdbm_errno = GDBM_MALLOC_ERROR;
	      close (ifd);
	      return -1;
	    }
	}
      if (read (ifd, dbuffer, size) != size)
	goto read_fail;

      data.dptr = dbuffer;
      data.dsize = size;

      if (gdbm_store (dbf, key, data, flag) != 0)
	{
	  /* Keep the existing errno. */
	  free (kbuffer);
	  free (dbuffer);
	  close (ifd);
	  return -1;
	}

      count++;
    }

  close (ifd);
  return count;

read_fail:

  if (kbuffer != NULL)
    free (kbuffer);
  if (dbuffer != NULL)
    free (dbuffer);

  close (ifd);

  gdbm_errno = GDBM_FILE_READ_ERROR;
  return -1;
}
#endif
