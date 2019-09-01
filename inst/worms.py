#!/usr/bin/env python3

# -*- coding: utf-8 -*- #
import re
import urllib.error
import urllib.request
import time
import unicodedata

class Worms:
    def __init__(self, taxon):

        self.taxon = taxon.replace(" ", "%20")

        aphiaID_url = "http://www.marinespecies.org/rest/AphiaIDByName/" + \
                      self.taxon + \
                      "?marine_only=false"

        self.aphiaID = None
        # make sure aphiaID will be available for downstream analyses
        while self.aphiaID is None:
            try:
                self.aphiaID = urllib.request.urlopen(aphiaID_url).read().decode('utf-8')
            except urllib.error.HTTPError:
                time.sleep(0.5)
                pass

        ##...variables to fill in...##
        self.taxonomic_ranges = []
        self.classification_page = ""
        self.synonym_list = []
        ##...variables to fill in...##

        ##...urls...##
        self.records_url = "http://www.marinespecies.org/rest/AphiaChildrenByAphiaID/" + \
                           self.aphiaID + \
                           "?marine_only=false&offset=1"
        self.accepted_name = ""
        self.classfication_url = "http://www.marinespecies.org/rest/AphiaClassificationByAphiaID/"
        self.synonym_url = "http://www.marinespecies.org/rest/AphiaSynonymsByAphiaID/"
        ##...urls...##

    def taxamatch(self):
        
        spps = re.sub("\\(.+\\)", "", self.taxon).lower()
        spps = re.sub("[ ]{2,}", " ", spps)
        # spps = self.taxon

        complete_url = "http://www.marinespecies.org/rest/AphiaRecordsByMatchNames?scientificnames%5B%5D=" + \
                       spps + \
                       "&marine_only=false"

        page = urllib.request.urlopen(complete_url).read().decode('utf-8')

        valid_info = re.sub('.*,"valid_AphiaID":(.*),"valid_name":"(.*)","valid_authority":.*', "\\1,\\2", page)
        # valid_name = "Mobula birostris"

        try:
            aphiaid, valid_name = valid_info.split(',')
            self.accepted_name = valid_name
            self.aphiaID = aphiaid

        except ValueError:
            self.accepted_name = ""

        return self.accepted_name

    def get_taxonomic_ranges(self):
        """Name of all valuable ranks are retrieved and stored at self.taxonomic_ranges and
        also complete string of information used to get it at self.classification_page
        """
        if self.aphiaID == '-999' or self.aphiaID == '':
            self.taxamatch()

        if self.aphiaID == '-999' or self.aphiaID == '':
            self.taxonomic_ranges = None

        else:

            complete_url = self.classfication_url + self.aphiaID
            # This while loop is because of classfication page, or classification string, is needed
            # since self.classification_page is not starting with a value,
            # this while loop may not slow down its request
            while self.classification_page == "":
                try:
                    self.classification_page = urllib.request.urlopen(complete_url).read().decode('utf-8')
                except urllib.error.HTTPError:
                    time.sleep(0.5)
                    pass

            # grant with a white space into the pattern can end up as non-smart search, but it is kept anyways
            self.taxonomic_ranges = [re.sub('"rank":"([A-Za-z ]+)"', "\\1", i) for i in
                                     re.findall('"rank":"[A-Za-z ]+"', self.classification_page)]

    def get_rank(self, rank):

        if self.taxonomic_ranges is None:
            return "check_spell"

        if not self.taxonomic_ranges:
            # if there is not a list of ranks for comparing with the rank variable
            # then, get it with the following and store them
            self.get_taxonomic_ranges()

        # since the prior ensures a list of rank's names, rank variable is looked between them
        spell = [i for i in self.taxonomic_ranges if i == rank]

        # if there was not any match, then a "check_spell" is returned
        if len(spell) == 0:
            return "check_spell"

        rankMatch = re.sub('.*"rank":"' +
                           spell[0] +
                           '","scientificname":"([A-Za-z\[\] ]+)".*',
                           "\\1", self.classification_page)

        if re.findall("\[unassigned\]", rankMatch):
            return 'unassigned'
        else:
            return rankMatch

    def get_synonyms(self):
        """
        wrapper for synonyms method of WoRMS API
        """
        if self.aphiaID == '-999' or self.aphiaID == '':
            self.taxamatch()

        if self.aphiaID == '' or self.aphiaID == '-999':
            return "Check your taxon!"

        else:

            complete_url = self.synonym_url + self.aphiaID
            synonym_page = None

            while synonym_page is None:
                try:
                    synonym_page = urllib.request.urlopen(complete_url).read().decode('utf-8')

                except urllib.error.HTTPError:
                    time.sleep(0.5)
                    pass

            pre_syn = re.findall('"scientificname":"[A-Z][a-z]+ [a-z]+"', synonym_page)

            self.synonym_list = [re.sub('"scientificname":"([A-Za-z ]+)"', "\\1", i) for i in pre_syn]

            return self.synonym_list
