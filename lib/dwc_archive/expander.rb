# frozen_string_literal: true

class DarwinCore
  # Unpacks compressed archives into a temp directory
  class Expander
    def initialize(archive_path, tmp_dir)
      @archive_path = archive_path
      @tmp_dir = tmp_dir
      @dir_path = DarwinCore.random_path(tmp_dir)
      @unpacker = init_unpacker
    end

    def unpack
      clean
      raise DarwinCore::FileNotFoundError unless File.exist?(@archive_path)
      success = @unpacker.call(@dir_path, @archive_path) if @unpacker
      if @unpacker && success && $CHILD_STATUS.exitstatus.zero?
        success
      else
        clean
        raise DarwinCore::UnpackingError
      end
    end

    def path
      @path ||= files_path
    end

    def clean
      DarwinCore.clean(@dir_path)
    end

    def files
      DarwinCore.files(path)
    end

    private

    def init_unpacker
      file_command = IO.popen("file -z " + esc(@archive_path))
      file_type    = file_command.read
      file_command.close
      return tar_unpacker if file_type =~ /tar.*gzip/i
      return zip_unpacker if file_type =~ /Zip/
      nil
    end

    def tar_unpacker
      proc do |tmp_path, archive_path|
        FileUtils.mkdir tmp_path
        path = esc(archive_path)
        system("tar -zxf #{path} -C #{tmp_path} > /dev/null 2>&1")
      end
    end

    def zip_unpacker
      proc do |tmp_path, archive_path|
        path = esc(archive_path)
        system("unzip -qq -d #{tmp_path} #{path} > /dev/null 2>&1")
      end
    end

    def esc(a_str)
      "'" + a_str.gsub(92.chr, '\\\\\\').gsub("'", "\\\\'") + "'"
    end

    def path_entries(dir)
      Dir.entries(dir).reject { |e| e.match(/[\.]{1,2}$/) }.sort
    end

    def files_path
      entries = path_entries(@dir_path)
      entries.include?("meta.xml") ? @dir_path : search_for_file_path(entries)
    end

    def search_for_file_path(entries)
      res = nil
      entries.each do |e|
        check_path = File.join(@dir_path, e)
        next unless FileTest.directory?(check_path) &&
                    path_entries(check_path).include?("meta.xml")
        res = check_path
        break
      end
      res
    end
  end
end
