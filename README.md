Darwin Core Archive
===================

[![Gem Version][1]][2]
[![Continuous Integration Status][3]][4]
[![Coverage Status][5]][6]
[![CodePolice][7]][8]
[![Dependency Status][9]][10]

Darwin Core Archive format is a current standard for information exchange
between Global Names Architecture modules. This gem allows to work with
Darwin Core Archive data compressed to either zip or tar.gz files.
More information about Darwing Core Archive can be found on a [GBIF page:][11]

Installation
------------

    sudo gem install dwc-archive

### System Requirements

You need [Redis Server][12] and unzip library installed 


Usage
-----

    require 'rubygems'
    require 'dwc-archive'

    dwc = DarwinCore.new('/path_to_file/archive_file.tar.gz')
    dwc.archive.files      # the archive file list
    dwc.metadata.data      # summary of metadata from eml.xml if it exists
    dwc.metadata.authors   # authors of the archive
    dwc.core.data          # summary of DarwinCore main file
    dwc.core.file_path     # path to the DarwinCore main file
    dwc.extensions         # array of DarwinCore Star extensions
    dwc.extensions[0].data # summary for an extension

    # read content of the core data file into memory or used with a block
    # it returns array of arrays of data
    # rows that had a wrong encoding will be collected into errors array
    data, errors = dwc.core.read

    # read content using a block, getting back results in sets of 100 rows each
    results = []
    tail_data, tail_errors = dwc.core.read(100) do |data, errors|
      results << [data, errors]
    end
    results << [tail_data, tail_errors]

    # read content of an extension data file into memory
    data, errors = dwc.core.extensions[0].read

    # read content of an extension data using block
    results = []
    tail_data, tail_errors = dwc.core.extensions[0](100) do |data, errors|
      results << [data, errors]
    end
    results << [tail_data, tail_errors]

    # normalize names in classification collecting together synonyms,
    # canonical names, vernacular names and associating paths to taxons
    # in a classification distributed as DwCA file

    result = dwc.normalize_classification

    # for a finer control over normalization:

    cn = DarwinCore::ClassificationNormalizer.new(dwc)
    cn.normalize
    # if you don't want to generate path consisting of canonical forms
    # of ancestors to a taxon
    cn.normalize(:with_canonical_names => false)

    # if you don't want to ingest information from extensions
    cn.normalize(:with_extensions => false)

    # to get a flat hash of nodes with attached vernacular names and synonyms
    normalized_data = cn.normalized_data

    # to get a representation of tree organization as a hash
    classification_tree = cn.tree

    # to get list of all name strings used as scientific or vernacular names
    all_name_strings = cn.name_strings

    # to get list of errors generated during the normalization
    errors = cn.error_names

    DarwinCore.clean_all   # remove all expanded archives

Creating a DarwinCore Archive file
----------------------------------

    gen = DarwinCore::Generator.new('/tmp/dwc_birches.tar.gz')

    core = [
      ["http://rs.tdwg.org/dwc/terms/taxonID",
       "http://rs.tdwg.org/dwc/terms/parentNameUsageID",
       "http://rs.tdwg.org/dwc/terms/scientificName",
       "http://rs.tdwg.org/dwc/terms/taxonRank"],
      [1, 0, "Plantae", "kingdom"],
      [2, 1, "Betula", "genus"],
      [3, 2, "Betula verucosa", "species"]
    ]

    vernacular_names = [
      ["http://rs.tdwg.org/dwc/terms/TaxonID",
      "http://rs.tdwg.org/dwc/terms/vernacularName"],
      [1, "Plants"],
      [1, "Растения"],
      [2, "Birch"],
      [2, "Береза"],
      [3, "Wheeping Birch"],
      [3, "Береза плакучая"]
    ]

    eml = {
      :id => '1234',
      :license => 'http://creativecommons.org/licenses/by-sa/3.0/',
      :title => 'Test Classification',
      :authors => [
        { :first_name => 'John',
          :last_name => 'Doe',
          :email => 'jdoe@example.com',
          :organization => 'Example',
          :position => 'Assistant Professor',
          :url => 'http://example.org' },
          { :first_name => 'Jane',
            :last_name => 'Doe',
            :email => 'jane@example.com' }
    ],
      :metadata_providers => [
        { :first_name => 'Jim',
          :last_name => 'Doe',
          :email => 'jimdoe@example.com',
          :url => 'http://aggregator.example.org' }],
      :abstract => 'test classification',
      :citation =>
        'Test classification: Doe John, Doe Jane, Taxnonmy, 10, 1, 2010',
      :url => 'http://example.com'
    }

    gen.add_core(core, 'core.txt')
    gen.add_extension(vernacular_names,
                      'vernacular_names.txt',
                      true, 'http://rs.gbif.org/terms/1.0/VernacularName')
    gen.add_meta_xml
    gen.add_eml_xml(eml)
    gen.pack

Logging
-------

Gem has ability to show logs of it's events:

    require 'dwc-archive'
    DarwinCore.logger = Logger.new($stdout)


Note on Patches/Pull Requests
-----------------------------

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump
  version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.


Copyright
---------

Copyright (c) 2010-2013 Marine Biological Laboratory. See LICENSE for details.

[1]: https://badge.fury.io/rb/dwc-archive.png
[2]: http://badge.fury.io/rb/dwc-archive
[3]: https://secure.travis-ci.org/GlobalNamesArchitecture/dwc-archive.png
[4]: http://travis-ci.org/GlobalNamesArchitecture/dwc-archive
[5]: https://coveralls.io/repos/GlobalNameArchitecture/dwc-archive/badge.png
[6]: https://coveralls.io/r/GlobalNameArchitecture/dwc-archive
[7]: https://codeclimate.com/github/GlobalNameArchitecture/dwc-archive.png
[8]: https://codeclimate.com/github/GlobalNameArchitecture/dwc-archive
[9]: https://gemnasium.com/GlobalNamesArchitecture/dwc-archive.png
[10]: https://gemnasium.com/GlobalNamesArchitecture/dwc-archive
[11]: http://bit.ly/2IxcBA
[12]: http://redis.io/topics/quickstart
