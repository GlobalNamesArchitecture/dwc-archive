require_relative '../spec_helper'

describe DarwinCore do
  subject { DarwinCore }
  let(:file_dir) { File.expand_path('../../files', __FILE__) }

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
end

