class DarwinCore
  class Error < RuntimeError; end
  class FileNotFoundError < Error; end
  class UnpackingError < Error; end
  class InvalidArchiveError < Error; end
end
