import re
import sys
import time
from urllib.request import urlopen
import xml.etree.ElementTree as ET

from boldminer import utils

HOST    = "http://www.boldsystems.org/index.php/Ids_xml?db="
HOSTN   = "https://blast.ncbi.nlm.nih.gov/blast/Blast.cgi?CMD=Put&PROGRAM=blastn&MEGABLAST=on&DATABASE=nt&QUERY="
HOSTNG  = "https://blast.ncbi.nlm.nih.gov/blast/Blast.cgi?CMD=Get&FORMAT_TYPE=XML&RID="
ROWSTR  = "{spps}\t{match}\t{identity}\t{ID}\n"
ADDRESS = "BlastOutput_iterations/Iteration/Iteration_hits"

def getrows(child, cols):
    out = {}
    for i in cols:
        val = child.find(i)
        if val is None:
            valstr = ''
        else:
            valstr = val.text
        
        out[i] = valstr
    return out

def getIDfromNCBI(spps, seq):

    upstream     = ".+\"RID\" value=\""
    complete_url = HOSTN + seq + "&WORD_SIZE=28&HITLIST_SIZE=3"

    prerid = urlopen(complete_url).read().decode('utf-8')
    prerid = prerid.replace("\n", "")
    rid    = re.sub("\".*", "", re.sub( upstream, "", prerid ) )

    out = []

    if not rid:
        out.append(
            ROWSTR.format(
                spps = spps,
                match = "",
                identity = "0",
                ID = "GenBank: RID not available"
                )
            )
    else:

        while True:
            ncbiout = urlopen(HOSTNG + rid).read().decode('utf-8')

            if not ncbiout:
                time.sleep(0.3)
            else:
                break

        tree  = ET.fromstring(ncbiout).find(ADDRESS)

        if not tree:
            out.append(
                ROWSTR.format(
                    spps = spps,
                    match = "",
                    identity = "0",
                    ID = "Unavailable with NCBI"
                    )
                )
        else:

            tmp = []
            for child in tree:

                identity = child.find('Hit_hsps/Hsp/Hsp_identity').text
                length   = child.find('Hit_hsps/Hsp/Hsp_align-len').text
                #percentage
                try:
                    identity = round(int(identity)/int(length), 4)

                except ValueError:
                    identity = 0
                # print(identity)

                tmp.append(
                    ROWSTR.format(
                        spps     = spps,
                        match    = child.find('Hit_def').text[0:10],
                        identity = identity,
                        ID       = "GenBank: %s" % child.find('Hit_accession').text
                        )
                    )
            out.extend(tmp)

    return out

def getIDfromBOLD(seq, db = 'COX1_SPECIES_PUBLIC'):

    myfmt        = "{host}{db}&sequence={seq}"
    complete_url = myfmt.format(host = HOST, db = db, seq = seq)
    response     = urlopen(complete_url).read()
    tree         = ET.fromstring(response)

    mytarget = [
        'ID',
        'taxonomicidentification',
        'similarity',
        ]

    out = []
    for child in tree:
        out.append(getrows(child, mytarget))
    return out

def rowgenerator(obj, file, spps):

    # mystr = "{spps}\t{match}\t{identity}\t{ID}\n"
    # with open(file, 'a') as f:
    out = []
    for idict in obj:
        out.append(

            ROWSTR.format(
                spps     = spps,
                match    = idict['taxonomicidentification'],
                identity = idict['similarity'],
                ID       = idict['ID']
            )
        )

    return out


def filterbythreshold(rows, threshold):
    out = []

    for i in rows:
        identity = float(i.split("\t")[2])
        if identity >= threshold:
            out.append(i)

    return out


def writeout(file, out, threshold):

    # whole table
    with open(file, 'a') as f:
        f.writelines(out)

    # filtered table
    myfilterdfile = file + "_filtered"
    myfilterdvals = filterbythreshold(out, threshold)

    if myfilterdvals:
        with open(myfilterdfile, 'a') as f:
            f.writelines(myfilterdvals)

    
def id_engine(query, 
              db          = 'COX1_SPECIES_PUBLIC',
              make_blast  = True,
              quiet       = False,
              threshold   = 0.98,
              fileoutname = 'id_engine.txt'):

    query = utils.fas_to_dic(file = query)

    for head, seq in query.items():

        out    = []
        myhead = re.sub("^>", "",head)

        if not quiet:
            sys.stdout.write("\nIdentifying: %s" % myhead )
            sys.stdout.flush()

        myid = getIDfromBOLD(seq=seq, db=db)

        if not myid and make_blast:
            out.extend(
                getIDfromNCBI(
                    spps = myhead,
                    seq  = seq
                )
            )

        elif not myid and not make_blast:

            out.append(
                ROWSTR.format(
                    spps     = myhead,
                    match    = "",
                    identity = "0",
                    ID       = 'Unavailable with BOLD'
                )
            )
        else:
            out.extend(
                rowgenerator(
                    obj  = myid, 
                    file = fileoutname,
                    spps = myhead
                )
            )

        writeout(fileoutname, out, threshold)
        time.sleep(0.3)

    if not quiet:
        sys.stdout.write("\n")

