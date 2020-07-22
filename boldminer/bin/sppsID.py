#!/usr/bin/env python3

# -*- coding: utf-8 -*- #
# import re
import argparse
from boldminer.id_engine import id_engine

# from OBISdat.utils import *
# from OBISdat.core_obis import Obis

THRESHOLD   = 0.98
BOLD_DB     = 'COX1_SPECIES_PUBLIC'
OUTPUTFILE  = "sppsID.txt"

def getOpt():
    parser = argparse.ArgumentParser(formatter_class = argparse.RawDescriptionHelpFormatter,
                                     description="""

                Wrapper of both BOLD and NCBI APIs for species identifications
                                    from DNA sequences

- Hosts:
    BOLD: http://www.boldsystems.org/index.php/Ids_xml
    NCBI: https://blast.ncbi.nlm.nih.gov/blast/Blast.cgi
                                     """)

    parser.add_argument('spps',
                        default=None,
                        help='Multifasta file ')

    parser.add_argument('-t','--threshold',
                        type = float,
                        metavar="",
                        action='store',
                        default=THRESHOLD,
                        help='Minimum similarity allowed for best matched species [Default = %s]' % THRESHOLD)
    parser.add_argument('-b','--bold_db', 
                        metavar="",
                        type = str,
                        default=BOLD_DB,
                        action='store',
                        help='''BOLD database. There are four available: 
                                COX1,
                                COX1_SPECIES,
                                COX1_SPECIES_PUBLIC,
                                COX1_L640bp
                                [Default = %s]''' % BOLD_DB )
    parser.add_argument('-n','--ncbi',
                        action='store_true',
                        help=' If selected, BLASTn is used to identify species')
    parser.add_argument('-q', '--quiet',
                        action='store_true',
                        help=' If selected, suppress running messages')
    parser.add_argument('-o','--out', 
                        metavar="",
                        type = str,
                        default=OUTPUTFILE,
                        action='store',
                        help='Output name [Default = %s]' % OUTPUTFILE )
    args = parser.parse_args()
    return args

def main():
    args = getOpt()

    id_engine( 
        query       = args.spps,
        db          = args.bold_db,
        make_blast  = args.ncbi,
        quiet       = args.quiet,
        threshold   = args.threshold,
        fileoutname = args.out
        )

if __name__ == "__main__":
    main()