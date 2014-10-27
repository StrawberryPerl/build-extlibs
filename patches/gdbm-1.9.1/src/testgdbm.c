/* testgdbm.c - Driver program to test the database routines and to
   help debug gdbm.  Uses inside information to show "system" information */

/* This file is part of GDBM, the GNU data base manager.
   Copyright (C) 1990, 1991, 1993, 2007, 2011 Free Software Foundation,
   Inc.

   GDBM is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3, or (at your option)
   any later version.

   GDBM is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with GDBM. If not, see <http://www.gnu.org/licenses/>.    */

/* Include system configuration before all else. */
#include "autoconf.h"

#include "gdbmdefs.h"
#include "gdbm.h"

#include <errno.h>
#include <ctype.h>
#ifndef _WIN32
#include <signal.h>
#include <sys/ioctl.h>
#endif
#ifdef HAVE_SYS_TERMIOS_H
#include <sys/termios.h>
#endif
#include <stdarg.h>

const char *progname;                     /* Program name */

char *prompt = "testgdbm> ";

char *file_name = NULL;             /* Database file name */   
GDBM_FILE gdbm_file = NULL;   /* Database to operate upon */
int interactive;                    /* Are we running in interactive mode? */
datum key_data;                     /* Current key */
datum return_data;                  /* Current data */
int key_z = 1;                      /* Keys are nul-terminated strings */
int data_z = 1;                     /* Data are nul-terminated strings */

#define SIZE_T_MAX ((size_t)-1)


void
error (int code, char *fmt, ...)
{
  va_list ap;
  if (!interactive)
    fprintf (stderr, "%s: ", progname);
  va_start (ap, fmt);
  vfprintf (stderr, fmt, ap);
  va_end (ap);
  fputc ('\n', stderr);
  if (code)
    exit (code);
}
  

size_t
bucket_print_lines (hash_bucket *bucket)
{
  return 6 + gdbm_file->header->bucket_elems + 3 + bucket->av_count;
}

/* Debug procedure to print the contents of the current hash bucket. */
void
print_bucket (FILE *fp, hash_bucket *bucket, char *mesg)
{
  int             index;

  fprintf (fp, "******* %s **********\n\nbits = %d\ncount= %d\nHash Table:\n",
	   mesg, bucket->bucket_bits, bucket->count);
  fprintf (fp,
     "     #    hash value     key size    data size     data adr  home\n");
  for (index = 0; index < gdbm_file->header->bucket_elems; index++)
    fprintf (fp, "  %4d  %12x  %11d  %11d  %11lu %5d\n", index,
	     bucket->h_table[index].hash_value,
	     bucket->h_table[index].key_size,
	     bucket->h_table[index].data_size,
	     (unsigned long) bucket->h_table[index].data_pointer,
	     bucket->h_table[index].hash_value %
	     gdbm_file->header->bucket_elems);

  fprintf (fp, "\nAvail count = %1d\n", bucket->av_count);
  fprintf (fp, "Avail  adr     size\n");
  for (index = 0; index < bucket->av_count; index++)
    fprintf (fp, "%9lu%9d\n",
	     (unsigned long) bucket->bucket_avail[index].av_adr,
	     bucket->bucket_avail[index].av_size);
}

size_t
_gdbm_avail_list_size (GDBM_FILE dbf, size_t min_size)
{
  int             temp;
  int             size;
  avail_block    *av_stk;
  size_t          lines;
  
  lines = 4 + dbf->header->avail.count;
  if (lines > min_size)
    return lines;
  /* Initialize the variables for a pass throught the avail stack. */
  temp = dbf->header->avail.next_block;
  size = (((dbf->header->avail.size * sizeof (avail_elem)) >> 1)
	  + sizeof (avail_block));
  av_stk = (avail_block *) malloc (size);
  if (av_stk == NULL)
    error (2, "Out of memory");

  /* Traverse the stack. */
  while (temp)
    {
      if (__lseek (dbf, temp, L_SET) != temp)
	{
	  error (0, "lseek: %s", strerror (errno));
	  break;
	}
      
      if (__read (dbf, av_stk, size) != size)
	{
	  error (0, "read: %s", strerror (errno));
	  break;
	}

      lines += av_stk->count;
      if (lines > min_size)
	break;
      temp = av_stk->next_block;
    }
  free (av_stk);

  return lines;
}

void
_gdbm_print_avail_list (FILE *fp, GDBM_FILE dbf)
{
  int             temp;
  int             size;
  avail_block    *av_stk;
  
  /* Print the the header avail block.  */
  fprintf (fp, "\nheader block\nsize  = %d\ncount = %d\n",
	   dbf->header->avail.size, dbf->header->avail.count);
  for (temp = 0; temp < dbf->header->avail.count; temp++)
    {
      fprintf (fp, "  %15d   %10lu \n",
	       dbf->header->avail.av_table[temp].av_size,
	       (unsigned long) dbf->header->avail.av_table[temp].av_adr);
    }

  /* Initialize the variables for a pass throught the avail stack. */
  temp = dbf->header->avail.next_block;
  size = (((dbf->header->avail.size * sizeof (avail_elem)) >> 1)
	  + sizeof (avail_block));
  av_stk = (avail_block *) malloc (size);
  if (av_stk == NULL)
    error (2, "Out of memory");

  /* Print the stack. */
  while (temp)
    {
      if (__lseek (dbf, temp, L_SET) != temp)
	{
	  error (0, "lseek: %s", strerror (errno));
	  break;
	}
      
      if (__read (dbf, av_stk, size) != size)
	{
	  error (0, "read: %s", strerror (errno));
	  break;
	}

      /* Print the block! */
      fprintf (fp, "\nblock = %d\nsize  = %d\ncount = %d\n", temp,
	      av_stk->size, av_stk->count);
      for (temp = 0; temp < av_stk->count; temp++)
	{
	  fprintf (fp, "  %15d   %10lu \n", av_stk->av_table[temp].av_size,
		   (unsigned long) av_stk->av_table[temp].av_adr);
	}
      temp = av_stk->next_block;
    }
  free (av_stk);
}

void
_gdbm_print_bucket_cache (FILE *fp, GDBM_FILE dbf)
{
  int             index;
  char            changed;

  if (dbf->bucket_cache != NULL)
    {
      fprintf
	(fp,
	 "Bucket Cache (size %d):\n  Index:  Address  Changed  Data_Hash \n",
	 dbf->cache_size);
      for (index = 0; index < dbf->cache_size; index++)
	{
	  changed = dbf->bucket_cache[index].ca_changed;
	  fprintf (fp, "  %5d:  %7lu %7s  %x\n",
		   index,
		   (unsigned long) dbf->bucket_cache[index].ca_adr,
		   (changed ? "True" : "False"),
		   dbf->bucket_cache[index].ca_data.hash_val);
	}
    }
  else
    fprintf (fp, "Bucket cache has not been initialized.\n");
}

void
usage ()
{
  printf ("Usage: %s OPTIONS\n", progname);
  printf ("Test and modify a GDBM database.\n");
  printf ("\n");
  printf ("OPTIONS are:\n\n");
  printf ("  -b SIZE            set block size\n");
  printf ("  -c SIZE            set cache size\n");
  printf ("  -g FILE            operate on FILE instead of `junk.gdbm'\n");
  printf ("  -h                 print this help summary\n");
  printf ("  -l                 disable file locking\n");
  printf ("  -m                 disable file mmap\n");
  printf ("  -n                 create database\n");
  printf ("  -r                 open database in read-only mode\n");
  printf ("  -s                 synchronize to the disk after each write\n");
  printf ("  -v                 print program version\n");
  printf ("\n");
  printf ("Report bugs to <%s>.\n", PACKAGE_BUGREPORT);
}

void
version ()
{
  printf ("testgdbm (%s) %s\n", PACKAGE_NAME, PACKAGE_VERSION);
  printf ("Copyright (C) 2007-2011 Free Software Foundation, Inc.\n");
  printf ("License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>\n");
  printf ("This is free software: you are free to change and redistribute it.\n");
  printf ("There is NO WARRANTY, to the extent permitted by law.\n");
}

int
trimnl (char *str)
{
  int len = strlen (str);

  if (str[len - 1] == '\n')
    {
      str[--len] = 0;
      return 1;
    }
  return 0;
}

void
read_from_file (const char *name, int replace)
{
  int line = 0;
  char buf[1024];
  datum key;
  datum data;
  FILE *fp;
  int flag = replace ? GDBM_REPLACE : 0;
  
  fp = fopen (name, "r");
  if (!fp)
    {
      error (0, "cannot open file `%s' for reading: %s",
	     name, strerror (errno));
      return;
    }

  while (fgets (buf, sizeof buf, fp))
    {
      char *p;

      if (!trimnl (buf))
	{
	  error (0, "%s:%d: line too long", name, line);
	  continue;
	}

      line++;
      p = strchr (buf, ' ');
      if (!p)
	{
	  error (0, "%s:%d: malformed line", name, line);
	  continue;
	}

      for (*p++ = 0; *p && isspace (*p); p++)
	;
      key.dptr = buf;
      key.dsize = strlen (buf) + key_z;
      data.dptr = p;
      data.dsize = strlen (p) + data_z;
      if (gdbm_store (gdbm_file, key, data, flag) != 0)
	error (0, "%d: item not inserted: %s",
	       line, gdbm_strerror (gdbm_errno));
    }
  fclose (fp);
}

int
get_screen_lines ()
{
#ifdef TIOCGWINSZ
  if (isatty (1))
    {
      struct winsize ws;

      ws.ws_col = ws.ws_row = 0;
      if ((ioctl(1, TIOCGWINSZ, (char *) &ws) < 0) || ws.ws_row == 0)
	{
	  const char *lines = getenv ("LINES");
	  if (lines)
	    ws.ws_row = strtol (lines, NULL, 10);
	}
      return ws.ws_row;
    }
#else
  const char *lines = getenv ("LINES");
  if (lines)
    return strtol (lines, NULL, 10);
#endif
  return -1;
}

int
get_record_count ()
{
  datum key, data;
  int count = 0;
  data = gdbm_firstkey (gdbm_file);
  while (data.dptr != NULL)
    {
      count++;
      key = data;
      data = gdbm_nextkey (gdbm_file, key);
      free (key.dptr);
    }
  return count;
}


#define ARG_UNUSED __attribute__ ((__unused__))

#define NARGS 2


/* c - count */
void
count_handler (char *arg[NARGS] ARG_UNUSED, FILE *fp,
	       void *call_data ARG_UNUSED)
{
  fprintf (fp, "There are %d items in the database.\n", get_record_count ());
}

/* d key - delete */
void
delete_handler (char *arg[NARGS], FILE *fp, void *call_data ARG_UNUSED)
{
  if (key_data.dptr != NULL)
    free (key_data.dptr);
  key_data.dptr = strdup (arg[0]);
  key_data.dsize = strlen (arg[0]) + key_z;
  if (gdbm_delete (gdbm_file, key_data) != 0)
    {
      if (gdbm_errno == GDBM_ITEM_NOT_FOUND)
	error (0, "Item not found");
      else
	error (0, "Can't delete: %s",  gdbm_strerror (gdbm_errno));
    }
}

/* f key - fetch */
void
fetch_handler (char *arg[NARGS], FILE *fp, void *call_data ARG_UNUSED)
{
  if (key_data.dptr != NULL)
    free (key_data.dptr);
  key_data.dptr = strdup (arg[0]);
  key_data.dsize = strlen (arg[0]) + key_z;
  return_data = gdbm_fetch (gdbm_file, key_data);
  if (return_data.dptr != NULL)
    {
      fprintf (fp, "%.*s\n", return_data.dsize, return_data.dptr);
      free (return_data.dptr);
    }
  else
    fprintf (stderr, "No such item found.\n");
}

/* n [key] - next key */
void
nextkey_handler (char *arg[NARGS], FILE *fp, void *call_data ARG_UNUSED)
{
  if (arg[0])
    {
      if (key_data.dptr != NULL)
	free (key_data.dptr);
      key_data.dptr = strdup (arg[0]);
      key_data.dsize = strlen (arg[0]) + key_z;
    }
  return_data = gdbm_nextkey (gdbm_file, key_data);
  if (return_data.dptr != NULL)
    {
      key_data = return_data;
      fprintf (fp, "%.*s\n", key_data.dsize, key_data.dptr);
      return_data = gdbm_fetch (gdbm_file, key_data);
      fprintf (fp, "%.*s\n", return_data.dsize, return_data.dptr);
      free (return_data.dptr);
    }
  else
    {
      fprintf (stderr, "No such item found.\n");
      free (key_data.dptr);
      key_data.dptr = NULL;
    }
}

/* s key data - store */
void
store_handler (char *arg[NARGS], FILE *fp, void *call_data ARG_UNUSED)
{
  datum key;
  datum data;
  
  key.dptr = arg[0];
  key.dsize = strlen (arg[0]) + key_z;
  data.dptr = arg[1];
  data.dsize = strlen (arg[1]) + data_z;
  if (gdbm_store (gdbm_file, key, data, GDBM_REPLACE) != 0)
    fprintf (stderr, "Item not inserted.\n");
}

/* 1 - begin iteration */

void
firstkey_handler (char *arg[NARGS], FILE *fp, void *call_data ARG_UNUSED)
{
  if (key_data.dptr != NULL)
    free (key_data.dptr);
  key_data = gdbm_firstkey (gdbm_file);
  if (key_data.dptr != NULL)
    {
      fprintf (fp, "%.*s\n", key_data.dsize, key_data.dptr);
      return_data = gdbm_fetch (gdbm_file, key_data);
      fprintf (fp, "%.*s\n", return_data.dsize, return_data.dptr);
      free (return_data.dptr);
    }
  else
    fprintf (fp, "No such item found.\n");
}

/* 2 - continue iteration */
void
next_on_last_handler (char *arg[NARGS] ARG_UNUSED, FILE *fp,
		      void *call_data ARG_UNUSED)
{
  return_data = gdbm_nextkey (gdbm_file, key_data);
  if (return_data.dptr != NULL)
    {
      free (key_data.dptr);
      key_data = return_data;
      fprintf (fp, "%.*s\n", key_data.dsize, key_data.dptr);
      return_data = gdbm_fetch (gdbm_file, key_data);
      fprintf (fp, "%.*s\n", return_data.dsize, return_data.dptr);
      free (return_data.dptr);
    }
  else
    fprintf (stderr, "No such item found.\n");
}

/* r - reorganize */
void
reorganize_handler (char *arg[NARGS] ARG_UNUSED, FILE *fp ARG_UNUSED,
		    void *call_data ARG_UNUSED)
{
  if (gdbm_reorganize (gdbm_file))
    fprintf (stderr, "Reorganization failed.\n");
  else
    fprintf (stderr, "Reorganization succeeded.\n");
}

/* A - print available list */
int
avail_begin (char *arg[NARGS], size_t *exp_count, void **data)
{
  if (exp_count)
    *exp_count = _gdbm_avail_list_size (gdbm_file, SIZE_T_MAX);
  return 0;
}

void
avail_handler (char *arg[NARGS] ARG_UNUSED, FILE *fp,
	       void *call_data ARG_UNUSED)
{
  _gdbm_print_avail_list (fp, gdbm_file);
}

/* C - print current bucket */
int
print_current_bucket_begin (char *arg[NARGS], size_t *exp_count, void **data)
{
  if (exp_count)
    *exp_count = bucket_print_lines (gdbm_file->bucket) + 3;
  return 0;
}

void
print_current_bucket_handler (char *arg[NARGS] ARG_UNUSED, FILE *fp,
			      void *call_data ARG_UNUSED)
{
  print_bucket (fp, gdbm_file->bucket, "Current bucket");
  fprintf (fp, "\n current directory entry = %d.\n",
	   gdbm_file->bucket_dir);
  fprintf (fp, " current bucket address  = %lu.\n",
	   (unsigned long) gdbm_file->cache_entry->ca_adr);
}

int
getnum (int *pnum, char *arg, char **endp)
{
  char *p;
  unsigned long x = strtoul (arg, &p, 10);
  if (*p && !isspace (*p))
    {
      printf ("not a number (stopped near %s)\n", p);
      return 1;
    }
  while (*p && isspace (*p))
    p++;
  if (endp)
    *endp = p;
  else if (*p)
    {
      printf ("not a number (stopped near %s)\n", p);
      return 1;
    }
  *pnum = x;
  return 0;
}
  
/* B num - print a bucket and set is a current one.
   Uses print_current_bucket_handler */
int
print_bucket_begin (char *arg[NARGS], size_t *exp_count, void **data ARG_UNUSED)
{
  int temp;

  if (getnum (&temp, arg[0], NULL))
    return 1;

  if (temp >= gdbm_file->header->dir_size / 4)
    {
      fprintf (stderr, "Not a bucket.\n");
      return 1;
    }
  _gdbm_get_bucket (gdbm_file, temp);
  if (exp_count)
    *exp_count = bucket_print_lines (gdbm_file->bucket) + 3;
  return 0;
}


/* D - print hash directory */
int
print_dir_begin (char *arg[NARGS], size_t *exp_count, void **data ARG_UNUSED)
{
  if (exp_count)
    *exp_count = gdbm_file->header->dir_size / 4 + 3;
  return 0;
}

void
print_dir_handler (char *arg[NARGS] ARG_UNUSED, FILE *out,
		   void *call_data ARG_UNUSED)
{
  int i;

  fprintf (out, "Hash table directory.\n");
  fprintf (out, "  Size =  %d.  Bits = %d. \n\n",
	   gdbm_file->header->dir_size, gdbm_file->header->dir_bits);
  
  for (i = 0; i < gdbm_file->header->dir_size / 4; i++)
    fprintf (out, "  %10d:  %12lu\n", i, (unsigned long) gdbm_file->dir[i]);
}

/* F - print file handler */
int
print_header_begin (char *arg[NARGS], size_t *exp_count, void **data ARG_UNUSED)
{
  if (exp_count)
    *exp_count = 14;
  return 0;
}

void
print_header_handler (char *arg[NARGS] ARG_UNUSED, FILE *fp, void *call_data)
{
  fprintf (fp, "\nFile Header: \n\n");
  fprintf (fp, "  table        = %lu\n",
	   (unsigned long) gdbm_file->header->dir);
  fprintf (fp, "  table size   = %d\n", gdbm_file->header->dir_size);
  fprintf (fp, "  table bits   = %d\n", gdbm_file->header->dir_bits);
  fprintf (fp, "  block size   = %d\n", gdbm_file->header->block_size);
  fprintf (fp, "  bucket elems = %d\n", gdbm_file->header->bucket_elems);
  fprintf (fp, "  bucket size  = %d\n", gdbm_file->header->bucket_size);
  fprintf (fp, "  header magic = %x\n", gdbm_file->header->header_magic);
  fprintf (fp, "  next block   = %lu\n",
	   (unsigned long) gdbm_file->header->next_block);
  fprintf (fp, "  avail size   = %d\n", gdbm_file->header->avail.size);
  fprintf (fp, "  avail count  = %d\n", gdbm_file->header->avail.count);
  fprintf (fp, "  avail nx blk = %lu\n",
	   (unsigned long) gdbm_file->header->avail.next_block);
}  

/* H key - hash the key */
void
hash_handler (char *arg[NARGS], FILE *fp, void *call_data)
{
  datum key;
  
  key.dptr = arg[0];
  key.dsize = strlen (arg[0]) + key_z;
  fprintf (fp, "hash value = %x. \n", _gdbm_hash (key));
}

/* K - print the bucket cache */
int
print_cache_begin (char *arg[NARGS], size_t *exp_count, void **data ARG_UNUSED)
{
  if (exp_count)
    *exp_count = gdbm_file->bucket_cache ? gdbm_file->cache_size + 1 : 1;
  return 0;
}
    
void
print_cache_handler (char *arg[NARGS] ARG_UNUSED, FILE *fp,
		     void *call_data ARG_UNUSED)
{
  _gdbm_print_bucket_cache (fp, gdbm_file);
}

/* V - print GDBM version */
void
print_version_handler (char *arg[NARGS] ARG_UNUSED, FILE *fp,
		       void *call_data ARG_UNUSED)
{
  fprintf (fp, "%s\n", gdbm_version);
}

/* < file [replace] - read entries from file and store */
void
read_handler (char *arg[NARGS], FILE *fp, void *call_data ARG_UNUSED)
{
  read_from_file (arg[0], arg[1] && strcmp (arg[1], "replace") == 0);
}

/* l - List all entries */
int
list_begin (char *arg[NARGS], size_t *exp_count, void **data ARG_UNUSED)
{
  if (exp_count)
    *exp_count = get_record_count ();
  return 0;
}

void
list_handler (char *arg[NARGS] ARG_UNUSED, FILE *fp, void *call_data)
{
  datum key;
  datum data;

  key = gdbm_firstkey (gdbm_file);
  while (key.dptr)
    {
      datum nextkey = gdbm_nextkey (gdbm_file, key);

      data = gdbm_fetch (gdbm_file, key);
      if (!data.dptr)
	error (0, "cannot fetch data (key %.*s)", key.dsize, key.dptr);
      else
	{
	  fprintf (fp, "%.*s %.*s\n", key.dsize, key.dptr, data.dsize,
		   data.dptr);
	  free (data.dptr);
	}
      free (key.dptr);
      key = nextkey;
    }
}

/* q - quit the program */
void
quit_handler (char *arg[NARGS] ARG_UNUSED, FILE *fp ARG_UNUSED,
	      void *call_data ARG_UNUSED)
{
  if (gdbm_file != NULL)
    gdbm_close (gdbm_file);

  exit (0);
}

/* e file [truncate] - export to a flat file format */
void
export_handler (char *arg[NARGS], FILE *fp, void *call_data ARG_UNUSED)
{
  int flags = GDBM_WRCREAT;

  if (arg[1] != NULL && strcmp (arg[1], "truncate") == 0)
    flags = GDBM_NEWDB;

  if (gdbm_export (gdbm_file, arg[0], flags, 0600) == -1)
    error (0, "gdbm_export failed, %s", gdbm_strerror (gdbm_errno));
}

/* i file [replace] - import from a flat file */
void
import_handler (char *arg[NARGS], FILE *fp, void *call_data ARG_UNUSED)
{
  int flag = GDBM_INSERT;

  if (arg[1] != NULL && strcmp(arg[1], "replace") == 0)
    flag = GDBM_REPLACE;

  if (gdbm_import (gdbm_file, arg[0], flag) == -1)
    error (0, "gdbm_import failed, %s", gdbm_strerror (gdbm_errno));
}

/* S - print current program status */
void
status_handler (char *arg[NARGS] ARG_UNUSED, FILE *fp,
		void *call_data ARG_UNUSED)
{
  fprintf (fp, "Database file: %s\n", file_name);
  fprintf (fp, "Zero terminated keys: %s\n", key_z ? "yes" : "no");
  fprintf (fp, "Zero terminated data: %s\n", data_z ? "yes" : "no");
}

/* z - toggle key nul-termination */
void
key_z_handler (char *arg[NARGS] ARG_UNUSED, FILE *fp,
	       void *call_data ARG_UNUSED)
{
  key_z = !key_z;
  fprintf (fp, "Zero terminated keys: %s\n", key_z ? "yes" : "no");
}

/* Z - toggle data nul-termination */
void
data_z_handler (char *arg[NARGS] ARG_UNUSED, FILE *fp,
		void *call_data ARG_UNUSED)
{
  data_z = !data_z;
  fprintf (fp, "Zero terminated data: %s\n", data_z ? "yes" : "no");
}


void help_handler (char *arg[NARGS], FILE *fp, void *call_data);
int help_begin (char *arg[NARGS], size_t *exp_count, void **data);

struct command
{
  int abbrev;
  int  (*begin) (char *[NARGS], size_t *, void **);
  void (*handler) (char *[NARGS], FILE *fp, void *call_data);
  void (*end) (void *data);
  char *args[NARGS];
  char *doc;
};


struct command command_tab[] = {
  { 'c', NULL, count_handler, NULL,
    { NULL, NULL, }, "count (number of entries)" },
  { 'd', NULL, delete_handler, NULL,
    { "key", NULL, }, "delete" },
  { 'e', NULL, export_handler, NULL,
    { "file", "[truncate]", }, "export" },
  { 'f', NULL, fetch_handler, NULL,
    { "key", NULL }, "fetch" },
  { 'i', NULL, import_handler, NULL,
    { "file", "[replace]", }, "import" },
  { 'l', list_begin, list_handler, NULL,
    { NULL, NULL }, "list" },
  { 'n', NULL, nextkey_handler, NULL,
    { "[key]", NULL }, "nextkey" },
  { 'q', NULL, quit_handler, NULL,
    { NULL, NULL }, "quit" },
  { 's', NULL, store_handler, NULL,
    { "key", "data" }, "store" },
  { '1', NULL, firstkey_handler, NULL,
    { NULL, NULL }, "firstkey" },
  { '2', NULL, next_on_last_handler, NULL,
    { NULL, NULL, },
    "nextkey on last key (from n, 1 or 2)" },
  { '<', NULL, read_handler, NULL,
    { "file", "[replace]" },
    "read entries from file and store" },
  { 'r', NULL, reorganize_handler, NULL,
    { NULL, NULL, }, "reorganize" },
  { 'z', NULL, key_z_handler, NULL,
    { NULL, NULL }, "toggle key nul-termination" },
  { 'A', avail_begin, avail_handler, NULL,
    { NULL, NULL, }, "print avail list" }, 
  { 'B', print_bucket_begin, print_current_bucket_handler, NULL,
    { "bucket-number", NULL, }, "print a bucket" },
  { 'C', print_current_bucket_begin, print_current_bucket_handler, NULL,
    { NULL, NULL, },
    "print current bucket" },
  { 'D', print_dir_begin, print_dir_handler, NULL,
    { NULL, NULL, }, "print hash directory" },
  { 'F', print_header_begin , print_header_handler, NULL,
    { NULL, NULL, }, "print file header" },
  { 'H', NULL, hash_handler, NULL,
    { "key", NULL, }, "hash value of key" },
  { 'K', print_cache_begin, print_cache_handler, NULL,
    { NULL, NULL, }, "print the bucket cache" },
  { 'S', NULL, status_handler, NULL,
    { NULL, NULL }, "print current program status" },
  { 'V', NULL, print_version_handler, NULL,
    { NULL, NULL, }, "print version of gdbm" },
  { 'Z', NULL, data_z_handler, NULL,
    { NULL, NULL }, "toggle data nul-termination" },
  { '?', help_begin, help_handler, NULL,
    { NULL, NULL, }, "print this help list" },
  { 'q', NULL, quit_handler, NULL,
    { NULL, NULL, }, "quit the program" },
  { 0 }
};


/* ? - help handler */
#define CMDCOLS 30

int
help_begin (char *arg[NARGS], size_t *exp_count, void **data)
{
  if (exp_count)
    *exp_count = sizeof (command_tab) / sizeof (command_tab[0]) + 1;
  return 0;
}

void
help_handler (char *arg[NARGS], FILE *fp, void *call_data)
{
  struct command *cmd;
  
  for (cmd = command_tab; cmd->abbrev; cmd++)
    {
      int i;
      int n = fprintf (fp, " %c", cmd->abbrev);

      for (i = 0; i < NARGS && cmd->args[i]; i++)
	n += fprintf (fp, " %s", cmd->args[i]);

      if (n < CMDCOLS)
	fprintf (fp, "%*.s", CMDCOLS-n, "");
      fprintf (fp, " %s", cmd->doc);
      fputc ('\n', fp);
    }
}

struct command *
find_command (char *p)
{
  struct command *cmd;
  if (p[1])
    {
      printf ("Multicharacter commands are not yet implemented.\n");
      return NULL;
    }
  for (cmd = command_tab; cmd->abbrev; cmd++)
    if (cmd->abbrev == *p)
      return cmd;
  return NULL;
}

#define SKIPWS(p) while (*(p) && isspace (*(p))) (p)++
#define SKIPWORD(p) while (*(p) && !isspace (*(p))) (p)++

char *
getword (char *s, char **endp)
{
  char *p;
  SKIPWS (s);
  p = s;
  SKIPWORD (s);
  if (*s)
    {
      *s++ = 0;
      SKIPWS (s);
    }
  *endp = s;
  return p;
}

/* The test program allows one to call all the routines plus the hash function.
   The commands are single letter commands.  The user is prompted for all other
   information.  See the help command (?) for a list of all commands. */

int
main (int argc, char *argv[])
{
  char cmdbuf[1000];

  int cache_size = DEFAULT_CACHESIZE;
  int block_size = 0;
  
  int opt;
  char reader = FALSE;
  char newdb = FALSE;
  int flags = 0;
  char *pager = getenv ("PAGER");

  progname = strrchr (argv[0], '/');
  if (progname)
    progname++;
  else
    progname = argv[0];
  
  /* Argument checking. */
  if (argc == 2)
    {
      if (strcmp (argv[1], "--help") == 0)
	{
	  usage ();
	  exit (0);
	}
      else if (strcmp (argv[1], "--version") == 0)
	{
	  version ();
	  exit (0);
	}
    }
  
  opterr = 0;
  while ((opt = getopt (argc, argv, "lmsrnc:b:g:hv")) != -1)
    switch (opt)
      {
      case 'h':
	usage ();
	exit (0);

      case 'l':
	flags = flags | GDBM_NOLOCK;
	break;

      case 'm':
	flags = flags | GDBM_NOMMAP;
	break;

      case 's':
	if (reader)
	  error (2, "-s is incompatible with -r");

	flags = flags | GDBM_SYNC;
	break;
	
      case 'r':
	if (newdb)
	  error (2, "-r is incompatible with -n");

	reader = TRUE;
	break;
	
      case 'n':
	if (reader)
	  error (2, "-n is incompatible with -r");

	newdb = TRUE;
	break;
	
      case 'c':
	cache_size = atoi (optarg);
	break;
	
      case 'b':
	block_size = atoi (optarg);
	break;
	
      case 'g':
	file_name = optarg;
	break;

      case 'v':
	version ();
	exit (0);
	  
      default:
	error (2, "unknown option; try `%s -h' for more info\n", progname);
      }

  if (file_name == NULL)
    file_name = "junk.gdbm";

  /* Initialize variables. */
  interactive = isatty (0);

  if (reader)
    {
      gdbm_file = gdbm_open (file_name, block_size, GDBM_READER, 00664, NULL);
    }
  else if (newdb)
    {
      gdbm_file =
	gdbm_open (file_name, block_size, GDBM_NEWDB | flags, 00664, NULL);
    }
  else
    {
      gdbm_file =
	gdbm_open (file_name, block_size, GDBM_WRCREAT | flags, 00664, NULL);
    }
  if (gdbm_file == NULL)
    error (2, "gdbm_open failed: %s", gdbm_strerror (gdbm_errno));

  if (gdbm_setopt (gdbm_file, GDBM_CACHESIZE, &cache_size, sizeof (int)) ==
      -1)
    error (2, "gdbm_setopt failed: %s", gdbm_strerror (gdbm_errno));

#ifndef _WIN32
  signal (SIGPIPE, SIG_IGN);
#endif

  /* Welcome message. */
  if (interactive)
    printf ("\nWelcome to the gdbm test program.  Type ? for help.\n\n");

  while (1)
    {
      int i;
      char *p, *sp;
      char argbuf[NARGS][128];
      char *args[NARGS];
      struct command *cmd;
      void *call_data;
      size_t expected_lines, *expected_lines_ptr;
      FILE *out;

      if (interactive)
	{
	  printf ("%s", prompt);
	  fflush (stdout);
	}
      
      if (fgets (cmdbuf, sizeof cmdbuf, stdin) == NULL)
	{
	  putchar ('\n');
	  break;
	}

      trimnl (cmdbuf);
      p = getword (cmdbuf, &sp);
      if (!*p)
	continue;
      cmd = find_command (p);
      if (!cmd)
	{
	  error (0,
		 interactive ? "Invalid command. Try ? for help." :
		               "Unknown command");
	  continue;
	}

      memset (args, 0, sizeof (args));
      for (i = 0; i < NARGS && cmd->args[i]; i++)
	{
	  p = i < NARGS-1 ? getword (sp, &sp) : sp;
	  if (!*p)
	    {
	      char *arg = cmd->args[i];
	      if (*arg == '[')
		/* Optional argument */
		break;
	      if (!interactive)
		error (1, "%c: not enough arguments", cmd->abbrev);

	      
	      printf ("%s? ", arg);
	      if (fgets (argbuf[i], sizeof argbuf[i], stdin) == NULL)
		error (1, "unexpected eof");

	      trimnl (argbuf[i]);
	      args[i] = argbuf[i];
	    }
	  else
	    args[i] = p;
	}	  

      /* Prepare for calling the handler */
      call_data = NULL;
      expected_lines = 0;
      expected_lines_ptr = (interactive && pager) ? &expected_lines : NULL;
      out = NULL;
      if (cmd->begin && cmd->begin (args, expected_lines_ptr, &call_data))
	continue;
      if (pager && expected_lines > get_screen_lines ())
	{
	  out = popen (pager, "w");
	  if (!out)
	    {
	      error (0, "cannot run pager `%s': %s", pager,
		     strerror (errno));
	      pager = NULL;
	    }
	}

      cmd->handler (args, out ? out : stdout, call_data);
      if (cmd->end)
	cmd->end (call_data);
      else if (call_data)
	free (call_data);

      if (out)
	pclose (out);
    }
  
  /* Quit normally. */
  quit_handler (NULL, stdout, NULL);
  return 0;
}
