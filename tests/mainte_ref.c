/*
 * Write Epson's own maintenance command bytes (epsMakeMainteCmd) to stdout, so CI can
 * check that filter/commandtoescpr emits exactly the same sequence.
 * Usage: mainte_ref clean|nozzle   (clock fixed at 2026-10-23 12:34:56)
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "epson-escpr-pvt.h"
#include "epson-escpr-services.h"
#include "epson-escpr-api.h"

extern EPS_PRINT_JOB printJob;
extern EPS_CMN_FUNC epsCmnFnc;

/* Fixed clock so the TI command is reproducible. */
static EPS_UINT32
fixed_time (EPS_LOCAL_TIME *t)
{
	t->year = 2026; t->mon = 10; t->day = 23;
	t->hour = 12; t->min = 34; t->sec = 56;
	return 0;
}

int
main (int argc, char *argv[])
{
	static EPS_PRINTER_INN printer;
	EPS_UINT8 buf[512];
	EPS_UINT32 size = sizeof (buf);
	EPS_INT32 cmd;

	if (argc != 2)
		return 2;
	cmd = strcmp (argv[1], "clean") == 0 ? EPS_MNT_CLEANING : EPS_MNT_NOZZLE;

	printer.language = EPS_LANG_ESCPR;
	strcpy ((char *) printer.modelName, "ET-2710 Series");
	printJob.printer = &printer;
	obsSetPrinter (&printer);
	epsCmnFnc.memAlloc = malloc;
	epsCmnFnc.memFree = free;
	epsCmnFnc.getLocalTime = fixed_time;

	if (epsMakeMainteCmd (cmd, buf, &size) != EPS_ERR_NONE || size > sizeof (buf))
		return 1;
	fwrite (buf, 1, size, stdout);
	return 0;
}
