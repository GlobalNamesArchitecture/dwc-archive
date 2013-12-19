require_relative '../spec_helper'

describe DarwinCore do
  subject { DarwinCore }
  let(:file_dir) { File.expand_path('../../files', __FILE__) }

  it 'breaks for ruby 1.8 and older' do
    stub_const('RUBY_VERSION', '1.8.7') 
    expect{load File.expand_path('../../../lib/dwc-archive.rb', __FILE__)}.
      to raise_exception
  end

  it 'continues for ruby 1.9.1 and higher' do
    stub_const('RUBY_VERSION', '1.9.2') 
    expect{load File.expand_path('../../../lib/dwc-archive.rb', __FILE__)}.
      to_not raise_exception
  end

  describe 'redis connection' do
    it 'redis is running' do
      expect do
        socket = TCPSocket.open('localhost', 6379)
        socket.close
      end.to_not raise_error
    end
  end

  it 'has version' do
    expect(DarwinCore::VERSION =~ /\d+\.\d+\.\d/).to be_true
  end

  describe '.nil_field?' do
    it 'is true for nil fields' do
      [nil, '/N', ''].each do |i|
        expect(DarwinCore.nil_field?(i)).to be_true
      end
    end

    it 'is false for non-nil  fields' do
      [0, '0', '123', 123, 'dsdfs434343/N'].each do |i|
        expect(subject.nil_field?(i)).to be_false
      end
    end
  end

  describe '.clean_all' do
    let(:tmp_dir) { DarwinCore::DEFAULT_TMP_DIR }

    it 'cleans dwca directories' do
      Dir.chdir(tmp_dir)
      FileUtils.mkdir('dwc_123') unless File.exists?('dwc_123')
      dwca_dirs =  Dir.entries(tmp_dir).select { |d| d.match(/^dwc_[\d]+$/) }
      expect(dwca_dirs.size > 0).to be_true
      subject.clean_all
      dwca_dirs =  Dir.entries(tmp_dir).select { |d| d.match(/^dwc_[\d]+$/) }
      expect(dwca_dirs.size == 0).to be_true
    end

    context 'no dwc files exist' do
      it 'does nothing' do
        subject.clean_all
        subject.clean_all
        dwca_dirs =  Dir.entries(tmp_dir).select { |d| d.match(/^dwc_[\d]+$/) }
        expect(dwca_dirs.size == 0).to be_true
      end
    end
  end

  describe '.logger' do
    it { expect(subject.logger.class).to eq Logger }
  end

  describe '.logger=' do
    it 'sets logger' do
      expect(subject.logger = 'fake logger').to eq 'fake logger'
      expect(subject.logger).to eq 'fake logger'
    end
  end

  describe '.logger_reset' do
    it 'resets logger' do
      subject.logger = 'fake logger'
      expect(subject.logger).to eq 'fake logger'
      subject.logger_reset
      expect(subject.logger.class).to eq Logger
    end
  end

  describe '.new' do
    subject(:dwca) { DarwinCore.new(file_path) }
   
    context 'tar.gz and zip files supplied' do 
      files = %w(data.zip data.tar.gz minimal.tar.gz junk_dir_inside.zip)
      files.each do |file|
        let(:file_path) { File.join(file_dir, file) }

        it "creates archive from  %s" % file do
          expect(dwca.archive.valid?).to be_true
        end

      end
    end

    context 'when file does not exist' do
      let(:file_path) { File.join(file_dir, 'no_file.gz') }

      it 'raises not found' do
         expect { dwca }.to raise_error DarwinCore::FileNotFoundError
      end
    end

    context 'archive cannot unpack' do

      let(:file_path) { File.join(file_dir, 'broken.tar.gz') }

      it 'raises unpacking error' do
        expect { dwca }.to raise_error DarwinCore::UnpackingError
      end
    end

    context 'archive is broken' do

      let(:file_path) { File.join(file_dir, 'invalid.tar.gz') }

      it 'raises error of invalid archive' do
        expect { dwca }.to raise_error DarwinCore::InvalidArchiveError
      end

    end
    
    context 'archive is not in utf-8 encoding' do

      let(:file_path) { File.join(file_dir, 'latin1.tar.gz') }
      
      it 'raises wrong encoding error' do
        expect { dwca }.to raise_error DarwinCore::EncodingError
      end

    end
    
    context 'filename with spaces and non-alphanumeric chars' do

      let(:file_path) { File.join(file_dir, 'file with characters(3).gz') }
      
      it 'creates archive' do
        expect(dwca.archive.valid?).to be_true
      end

    end
  end

  describe '#archive' do
    subject(:dwca) { DarwinCore.new(file_path) }
    let(:file_path) { File.join(file_dir, 'data.tar.gz') }

    it 'returns archive' do
      expect(dwca.archive.class).to be DarwinCore::Archive
    end
  end

  describe '#core' do
    subject(:dwca) { DarwinCore.new(file_path) }
    let(:file_path) { File.join(file_dir, 'data.tar.gz') }

    it 'returns core' do
      expect(dwca.core.class).to be DarwinCore::Core
    end
  end

  describe '#metadata' do
    subject(:dwca) { DarwinCore.new(file_path) }
    let(:file_path) { File.join(file_dir, 'data.tar.gz') }

    it 'returns eml' do
      expect(dwca.eml.class).to be DarwinCore::Metadata
      expect(dwca.metadata.class).to be DarwinCore::Metadata
    end
  end
  
  describe '#extensions' do
    subject(:dwca) { DarwinCore.new(file_path) }
    let(:file_path) { File.join(file_dir, 'data.tar.gz') }

    it 'returns extensions' do
      extensions = dwca.extensions
      expect(extensions.class).to be Array
      expect(extensions[0].class).to be DarwinCore::Extension 
    end
  end

  describe '#checksum' do
    subject(:dwca) { DarwinCore.new(file_path) }
    let(:file_path) { File.join(file_dir, 'data.tar.gz') }

    it 'creates checksum hash' do
      expect(dwca.checksum).to eq '7d94fc28ffaf434b66fbc790aa5ef00d834057bf'
    end
  end

  describe '#has_parent_id' do
    subject(:dwca) { DarwinCore.new(file_path) }

    context 'has classification' do
      let(:file_path) { File.join(file_dir, 'data.tar.gz') }
      it 'returns true' do
        expect(dwca.has_parent_id?).to be_true
      end
    end

    context 'does not have classification' do
      let(:file_path) { File.join(file_dir, 'gnub.tar.gz') }
      it 'returns false' do
        expect(dwca.has_parent_id?).to be_false
      end
    end
  end

  describe '#classification_normalizer' do
    subject(:dwca) { DarwinCore.new(file_path) }
    let(:file_path) { File.join(file_dir, 'data.tar.gz') }
   
    context 'not initialized' do
      it 'is nil' do
        expect(dwca.classification_normalizer).to be_nil
      end
    end

    context 'initialized' do
      it 'is DarwinCore::ClassificationNormalizer' do
        dwca.normalize_classification
        expect(dwca.classification_normalizer.class).
          to be DarwinCore::ClassificationNormalizer 
      end
    end
  end

end

